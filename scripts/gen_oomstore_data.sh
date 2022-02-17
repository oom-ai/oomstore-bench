#!/usr/bin/env bash
SDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) && cd "$SDIR" || exit 1

info() { printf "$(date -Is) %b[info]%b %s\n" '\e[0;32m\033[1m' '\e[0m' "$*" >&2; }

usage() { echo "Usage: $(basename "$0") <rows>" >&2; }

[ $# -ne 1 ] && usage && exit 1

rows=$1

mkdir -p data

for n in 25 50 100 200 300; do
    group=group_$n
    info "generate data for $group..."
    ./gen_ffgen_recipe.py $n | ffgen group --seed 0 -I "1..$rows" -r /dev/stdin > data/$group.csv
done
