#!/usr/bin/env bash
SDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) && cd "$SDIR" || exit 1

info() { printf "$(date -Is) %b[info]%b %s\n" '\e[0;32m\033[1m' '\e[0m' "$*" >&2; }

usage() { echo "Usage: $(basename "$0") <feature_count>" >&2; }

[ $# -ne 1 ] && usage && exit 1

feature_count=$1
group=group_$feature_count

mkdir -p data

info "generate data for $group..."
./gen_ffgen_recipe.py "$feature_count" |
    ffgen group --seed 0 -I "1..${ROWS:-50000}" -r /dev/stdin > "data/$group.csv"
