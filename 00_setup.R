# 00_setup.R  最初に 1 回だけ実行する準備のスクリプト
# RStudio で meta-analysis-nyumon.Rproj を開き、このファイルを開いて
# 右上の Source を押す（または全体を選んで Ctrl+Enter / Cmd+Enter）。
#
# このスクリプトがすること
#   1. R の版を確かめる
#   2. インターネットへの経路を確かめる。直接つながらなければ
#      福井大学の学内 LAN とみなし、大学のプロキシを設定する
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
fukui_proxy <- c("http://proxy.example.ac.jp:8080",
                 "http://192.0.2.10:8080")   # 名前を引けないときの予備

can_reach <- function(u, sec = 8) {
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

if (nzchar(Sys.getenv("https_proxy")) || nzchar(Sys.getenv("HTTPS_PROXY"))) {
  cat("プロキシは設定済みです。そのまま使います\n")
} else if (can_reach(test_url)) {
  cat("インターネットに直接つながりました（プロキシは使いません）\n")
} else {
  cat("直接つながりません。福井大学のプロキシを試します\n")
  found <- FALSE
  for (p in fukui_proxy) {
    set_proxy(p)
    if (can_reach(test_url)) {
      cat("福井大学の学内 LAN と判定し、プロキシを設定しました:", p, "\n")
      found <- TRUE
      break
    }
    # 大学の経路では https が通らず http なら通る場合に備える
    if (can_reach("http://cloud.r-project.org/src/contrib/PACKAGES")) {
      repos <- "http://cloud.r-project.org"
      cat("プロキシを設定し、CRAN には http で接続します:", p, "\n")
      found <- TRUE
      break
    }
  }
  if (!found) {
    Sys.unsetenv(c("http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY"))
    stop("インターネットにつながりません。ネットワークの接続を確かめてください。",
         "学内で失敗するときは、情報部門の案内にあるプロキシの設定を確かめてください。",
         call. = FALSE)
  }
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
