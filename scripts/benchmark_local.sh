#!/usr/bin/env bash
set -euo pipefail
SDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) && cd "$SDIR" || exit 1

usage() { echo "Usage: $(basename "$0") <feature_count>" >&2; }

[ $# -ne 1 ] && usage && exit 1

feature_count=$1
group_name="group_$feature_count"
oomstore_cfg=$SDIR/oomstore_local.yaml
REQUESTS=${REQUESTS:-20000}
ROWS=${ROWS:-50000}

results_dir="$SDIR/results"

prepare() {
    ./gen_oomstore_meta.sh "$feature_count"
    ./gen_oomstore_data.sh "$feature_count"

    oomplay init postgres redis
    oomcli init
    oomcli apply -f "meta/$group_name.yaml"
    oomcli import -g "$group_name" --input-file "data/$group_name.csv"
    oomcli sync -g "$group_name"
}

bench_golang() {
    id=$1
    mkdir -p "$results_dir/golang"
    (
        cd ../golang
        for concurrency in 1 2 4 8 16 32 64 128; do
            go run ./online_get/main.go "$oomstore_cfg" "$REQUESTS" $concurrency "$ROWS" "$feature_count" \
                > "$results_dir/golang/n${REQUESTS}_c${concurrency}_r${ROWS}_f${feature_count}.$id"
        done
    )
}

bench_all() {
    for id in {1..5}; do
        bench_golang "$id"
    done
}

main() {
    prepare
    bench_all
}

main
