# 00_setup.R  最初に 1 回だけ実行する準備のスクリプト
# RStudio で meta-analysis-nyumon.Rproj を開き、このファイルを開いて
# 右上の Source を押す（または全体を選んで Ctrl+Enter / Cmd+Enter）。
#
# このスクリプトがすること
#   1. R の版を確かめる
#   2. インターネットへの経路を確かめる。大学のプロキシの自動設定ファイルを
#      読めれば福井大学の学内 LAN と判定し、大学のプロキシを設定する
#   3. 本で使うパッケージのうち、入っていないものを入れる
#   4. data、fig、out のフォルダを作る
#   5. 010_make_data.R を実行して、架空データの CSV を作る
# 何度実行してもかまわない。入っているパッケージは入れ直さない。

# ---- 1. R の版 ----
if (getRversion() < "4.2.0") {
  stop("R の版が古いため、日本語のファイルを正しく読めないことがあります。",
       "R 4.2 以降を https://cran.r-project.org/ から入れ直してください。",
       call. = FALSE)
}
cat("R の版:", as.character(getRversion()), "\n")

# ---- 2. 経路とプロキシ ----
# 福井大学の学内 LAN では外部へ直接つながらず、大学のプロキシを通す必要がある。
# 学外や自宅では、何も設定しなくてもつながる。
# 大学はプロキシの自動設定ファイル（wpad.dat）を学内だけに置いている。
# これが取れれば学内と判定し、中に書かれたプロキシを使う。
wpad_url <- "http://wpad.u-fukui.ac.jp/wpad.dat"

can_reach <- function(u, sec = 5) {
  old <- options(timeout = sec)
  on.exit(options(old))
  ok <- tryCatch({
    con <- url(u, open = "rb", method = "libcurl")
    close(con)
    TRUE
  }, error = function(e) FALSE, warning = function(w) FALSE)
  ok
}

set_proxy <- function(p) {
  Sys.setenv(http_proxy = p, https_proxy = p,
             HTTP_PROXY = p, HTTPS_PROXY = p)
}

repos <- "https://cloud.r-project.org"
test_url <- paste0(repos, "/src/contrib/PACKAGES")

# wpad.dat を読み、「PROXY ホスト:ポート」を書かれた順に返す。取れなければ NULL
read_wpad <- function(sec = 3) {
  old <- options(timeout = sec)
  on.exit(options(old))
  txt <- tryCatch({
    con <- url(wpad_url, open = "r", method = "libcurl")
    on.exit(close(con), add = TRUE)
    readLines(con, warn = FALSE)
  }, error = function(e) NULL, warning = function(w) NULL)
  if (is.null(txt) || !any(grepl("FindProxyForURL", txt))) return(NULL)
  # 最後の代入が、どの条件にも当たらない一般のサイト（CRAN を含む）向けの設定
  hits <- grep("use_this_proxy *= *\"PROXY", txt, value = TRUE)
  line <- if (length(hits) > 0) hits[length(hits)] else paste(txt, collapse = " ")
  hp <- regmatches(line, gregexpr("PROXY +[A-Za-z0-9.-]+:[0-9]+", line))[[1]]
  hp <- unique(sub("^PROXY +", "", hp))
  if (length(hp) == 0) return(NULL)
  paste0("http://", hp)
}

# 大学のプロキシを順に試す。通ったら TRUE
try_fukui_proxy <- function(cand) {
  for (p in cand) {
    set_proxy(p)
    if (can_reach(test_url, sec = 8)) {
      cat("福井大学のプロキシを設定しました:", p, "\n")
      return(TRUE)
    }
    # 大学の経路では https が通らず http なら通る場合に備える
    if (can_reach("http://cloud.r-project.org/src/contrib/PACKAGES", sec = 8)) {
      repos <<- "http://cloud.r-project.org"
      cat("福井大学のプロキシを設定し、CRAN には http で接続します:", p, "\n")
      return(TRUE)
    }
  }
  Sys.unsetenv(c("http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY"))
  FALSE
}

wpad <- NULL
if (nzchar(Sys.getenv("https_proxy")) || nzchar(Sys.getenv("HTTPS_PROXY"))) {
  cat("プロキシは設定済みです。そのまま使います\n")
  ok <- TRUE
} else if (!is.null(wpad <- read_wpad())) {
  cat("福井大学の学内 LAN と判定しました（プロキシの自動設定ファイルを読めました）\n")
  ok <- try_fukui_proxy(wpad) || can_reach(test_url)
} else if (can_reach(test_url)) {
  cat("学外と判定しました。インターネットに直接つながります（プロキシは使いません）\n")
  ok <- TRUE
} else {
  ok <- FALSE
}
if (!ok) {
  stop("インターネットにつながりません。ネットワークの接続を確かめてください。\n",
       "学内で失敗するときは、総合情報基盤センターの案内でプロキシの設定を確かめ、\n",
       "Sys.setenv(http_proxy = \"http://ホスト:ポート\", https_proxy = \"http://ホスト:ポート\")\n",
       "を実行してから、このスクリプトをもう一度実行してください。",
       call. = FALSE)
}
options(repos = c(CRAN = repos))
# R を再起動するとプロキシの設定は消える。学内で続けて作業するときは、
# 新しい R のセッションでも最初にこのスクリプトを実行する。

# ---- 3. パッケージ ----
pkgs <- c("meta", "metafor", "mada", "lme4", "MASS")
need <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(need) > 0) {
  cat("パッケージを入れます:", paste(need, collapse = ", "), "\n")
  install.packages(need)
}
still <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(still) > 0) {
  stop("入らなかったパッケージがあります: ", paste(still, collapse = ", "),
       "\n上に出ているメッセージを確かめてください。", call. = FALSE)
}
cat("パッケージはそろいました:", paste(pkgs, collapse = ", "), "\n")

# ---- 4. フォルダ ----
for (d in c("data", "fig", "out")) {
  if (!dir.exists(d)) dir.create(d)
}

# ---- 5. 架空データ ----
source("010_make_data.R", encoding = "UTF-8")
cat("\n準備ができました。次は 100_part1.R（第 1 部）、",
    "200_part2.R（第 2 部）を開いて実行してください\n", sep = "")
