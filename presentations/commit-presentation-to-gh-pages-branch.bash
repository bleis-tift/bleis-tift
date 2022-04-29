#!/bin/bash

if [ $# -ne 1 ]; then
  echo "usage: ./commit-presentation-to-gh-pages-branch.bash <path-to-markdown>"
  echo "example: ./commit-presentation-to-gh-pages-branch.bash 2022/0430-fffsharp5.md"
  exit 1
fi

cd "$(dirname "$0")" || exit

markdown=$1
dir=$(dirname "$markdown")
presentation="${dir//\//-}-$(basename "${markdown%.*}")"

if [ ! -d "${dir}/export" ]; then
  echo "${dir}/export directory is not found."
  echo "You need to export html files using VSCode."
  exit 1
fi

mv "${dir}/export" "${presentation}"
git switch gh-pages
git add "${presentation}"
git commit -m "Add presentation(${presentation})"