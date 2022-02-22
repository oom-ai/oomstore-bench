#!/usr/bin/env bash
SDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) && cd "$SDIR" || exit 1

usage() { echo "Usage: $(basename "$0") <feature_count>" >&2; }

[ $# -ne 1 ] && usage && exit 1

feature_count=$1
group=group_$feature_count

mkdir -p meta

./gen_ffgen_recipe.py "$feature_count" | ffgen schema -r /dev/stdin > "meta/$group.yaml"
