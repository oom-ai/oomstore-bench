#!/usr/bin/env bash
SDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) && cd "$SDIR" || exit 1

mkdir -p data

for n in 25 50 100 200 300; do
    ./gen_ffgen_recipe.py $n | ffgen group -r /dev/stdin > data/group_$n.csv
done
