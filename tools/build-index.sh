#!/bin/sh
# quizzes/ の中の *.json(index.json 以外)を並べて、quizzes/index.json を作り直す
cd "$(dirname "$0")/../quizzes" || exit 1
{
  printf '[\n'
  first=1
  for f in $(ls *.json | grep -v '^index.json$' | sort); do
    [ "$first" = 1 ] || printf ',\n'
    printf ' "%s"' "$f"
    first=0
  done
  printf '\n]\n'
} > index.json
echo "wrote quizzes/index.json:"
cat index.json
