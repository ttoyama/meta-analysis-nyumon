#!/bin/zsh
# 本の正本（Dropbox）から、公開する LaTeX のソースと PDF をこのリポジトリへ写す。
# 正本を直して組み直したあとに、リポジトリのルートで実行する。
set -eu
SRC="$HOME/Library/CloudStorage/Dropbox/Projects/learning/メタ解析入門/book"
DST="$(cd "$(dirname "$0")/.." && pwd)"

# 付録 A に載せるコードと、配布するスクリプトが同じかを先に確かめる
for f in 010_make_data.R 100_part1.R 200_part2.R; do
  if ! cmp -s "$SRC/body/code/$f" "$DST/$f"; then
    echo "body/code/$f とリポジトリの $f が違います。どちらかに揃えてから実行してください" >&2
    exit 1
  fi
done

mkdir -p "$DST/book"
rsync -a --delete \
  --include='/メタ解析入門*.tex' --include='/contents.tex' --include='/cover.tex' --include='/reading-preamble.tex' \
  --include='/sty/' --include='/sty/*.sty' \
  --include='/body/' --include='/body/*.tex' \
  --include='/body/code/' --include='/body/code/*.R' \
  --exclude='*' \
  "$SRC/" "$DST/book/"
# 図は正本では book の一つ上の fig/ にある。本文が読む図だけを book/fig/ に写す
mkdir -p "$DST/book/fig"
rm -f "$DST"/book/fig/*.pdf(N)
for f in $(grep -ohE 'kkfig(\[[^]]*\])?\{[A-Za-z0-9_.-]+\}' "$SRC"/body/*.tex | sed -E 's/.*\{([^}]+)\}/\1/' | sort -u); do
  cp "$SRC/../fig/${f%.pdf}.pdf" "$DST/book/fig/"
done
cp "$SRC/メタ解析入門.pdf" "$DST/meta_analysis_nyumon.pdf"
cp "$SRC/メタ解析入門_a4.pdf" "$DST/meta_analysis_nyumon_a4.pdf"
cp "$SRC/メタ解析入門_kindle.pdf" "$DST/meta_analysis_nyumon_kindle.pdf"
echo "写しました: book/ と PDF 3 つ（A5、A4、Kindle）"
