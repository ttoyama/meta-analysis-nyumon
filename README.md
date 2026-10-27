# メタ解析入門（臨床検査技師のための）

メタ解析をこれから始める臨床検査技師のための学習書と、本の中で使う R のスクリプトです。前半（第 1 部）で介入の効果を統合する方法を、後半（第 2 部）で検査の精度を統合する方法を、架空の例題と実データで説明しています。

- 本: [`meta_analysis_nyumon.pdf`](meta_analysis_nyumon.pdf)（A5、約 230 ページ）
  - 印刷用: [`meta_analysis_nyumon_a4.pdf`](meta_analysis_nyumon_a4.pdf)（A4、片面印刷向け、約 160 ページ）
  - Kindle 用: [`meta_analysis_nyumon_kindle.pdf`](meta_analysis_nyumon_kindle.pdf)（7 インチの Kindle Paperwhite に合わせた判型）
- R のスクリプト: このリポジトリの `.R` ファイル
- 本の LaTeX ソース: [`book/`](book/)

初めて読むときは、見出しに「発展」の印のある節を飛ばして読んでかまいません。

## ファイル

| ファイル | 中身 |
|----------|------|
| `meta_analysis_nyumon.pdf` | 本（A5） |
| `meta_analysis_nyumon_a4.pdf` | 本（A4 の印刷用） |
| `meta_analysis_nyumon_kindle.pdf` | 本（Kindle 用） |
| `meta-analysis-nyumon.Rproj` | RStudio のプロジェクト。ダブルクリックで開くと、作業フォルダが自動で決まる |
| `00_setup.R` | 最初に 1 回実行する準備。パッケージの導入、フォルダの作成、架空データの作成を行う |
| `010_make_data.R` | 架空データ（降圧薬 A の 10 試験、プロカルシトニンの 10 研究）を作る。`00_setup.R` が呼び出す |
| `100_part1.R` | 第 1 部の解析 |
| `200_part2.R` | 第 2 部の解析 |
| `book/` | 本の LaTeX ソースと図 |
| `tools/sync_book.sh` | 著者が手元の正本からソースと PDF を写すためのスクリプト |

## 使い方（Windows、Mac 共通）

1. R（4.2 以降）と RStudio を入れます。
   - R: https://cran.r-project.org/
   - RStudio: https://posit.co/download/rstudio-desktop/
2. このページの右上の緑の「Code」ボタンから「Download ZIP」を選び、ダウンロードした ZIP を展開します。
3. 展開したフォルダの中の `meta-analysis-nyumon.Rproj` をダブルクリックします。RStudio が開きます。
4. RStudio の右下の Files から `00_setup.R` を開き、エディタの右上の「Source」を押します。足りないパッケージ（meta、metafor、mada、lme4、MASS）が自動で入り、`data`、`fig`、`out` のフォルダと架空データが作られます。初回はパッケージのダウンロードに数分かかります。
5. 「準備ができました」と出たら、`100_part1.R`（第 1 部）や `200_part2.R`（第 2 部）を開いて、上から順に実行します。図は作業フォルダに PDF で保存されます。

数値は、本文と同じ値が出ることを確かめてあります。R やパッケージの版によって、小数の末尾がわずかに変わることがあります。

## 福井大学の学内 LAN で使うとき

福井大学の学内 LAN では、外部へ直接つながらず、大学のプロキシを通す必要があります。`00_setup.R` は、まず大学がプロキシの自動設定ファイルを置いている http://wpad.u-fukui.ac.jp/wpad.dat を 3 秒ほど待って読みに行きます。読めれば学内と判定し、ファイルに書かれたプロキシを設定してから続けます。読めなければ学外と判定し、プロキシを使わずに直接つなぎます。このファイルは学内からしか読めないため、学内のプロキシのアドレスはスクリプトには書いていません。

プロキシの設定は、R を再起動すると消えます。学内でパッケージを追加するときは、新しい R のセッションで `00_setup.R` をもう一度実行してください。

ほかの機関でプロキシが必要なときは、`00_setup.R` を実行する前に、R のコンソールで次のように設定してください（アドレスは各機関の案内に従う）。

```r
Sys.setenv(http_proxy = "http://proxy.example.ac.jp:8080",
           https_proxy = "http://proxy.example.ac.jp:8080")
```

## 動かないとき

- 「R の版が古い」と出たら、R を 4.2 以降に入れ直してください。古い R では、日本語を含むスクリプトの文字化けが起きることがあります。
- 「ファイルが見つからない」と出たら、`meta-analysis-nyumon.Rproj` から RStudio を開いたかを確かめてください。別の方法で RStudio を開いた場合は、Session メニューの Set Working Directory で、このフォルダを作業フォルダにします。
- パッケージが入らないときは、RStudio を管理者として実行する必要はありません。表示されたメッセージを確かめ、ネットワークの接続を確かめてから、もう一度 `00_setup.R` を実行してください。

## データについて

例題の降圧薬 A の 10 試験と、プロカルシトニン（PCT）の 10 研究は、説明のために作った架空のデータで、実在の試験や研究ではありません。実データの例には、metafor パッケージの BCG ワクチンの 13 試験（`dat.bcg`）と、mada パッケージの AUDIT-C の 14 研究（`AuditC`）を使っています。

## 本を自分で組むとき

`book/` で次を実行すると、`メタ解析入門.pdf`（A5）ができます。A4 版は `メタ解析入門_a4.tex`、Kindle 版は `メタ解析入門_kindle.tex` を同じように組みます。本文は 3 つの版で共通の `contents.tex` と `body/` にあります。TeX Live の LuaLaTeX で組みます。

```sh
cd book
TEXINPUTS="./sty:" latexmk -lualatex メタ解析入門.tex
```

和文の書体は、既定ではヒラギノ（macOS）を使います。ヒラギノのない環境では、原ノ味フォント（TeX Live に入っている）に切り替えて組みます。

```sh
TEXINPUTS="./sty:" latexmk -lualatex -usepretex='\PassOptionsToPackage{profile=haranoaji}{kk-fonts}' メタ解析入門.tex
```

## ライセンス

- 本（`meta_analysis_nyumon.pdf`）と LaTeX ソース（`book/`）: [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/deed.ja)（表示・非営利。`book/LICENSE` を参照）。出典を示せば、複製して配ることも手を加えることも自由ですが、販売などの営利の目的には使えません
- R のスクリプト: MIT License（`LICENSE` を参照）
