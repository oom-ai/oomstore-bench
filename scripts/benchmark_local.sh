#!/usr/bin/env bash
set -euo pipefail
SDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) && cd "$SDIR" || exit 1

info() { printf "$(date -Is) %b[info]%b %s\n" '\e[0;32m\033[1m' '\e[0m' "$*" >&2; }

usage() { echo "Usage: $(basename "$0") <feature_count>" >&2; }

[ $# -ne 1 ] && usage && exit 1

feature_count=$1
group_name="group_$feature_count"
oomstore_cfg=$SDIR/oomstore_local.yaml
REQUESTS=${REQUESTS:-20000}
ROWS=${ROWS:-50000}

results_dir="$SDIR/results"

prepare() {
    info "prepare data..."

    ./gen_oomstore_meta.sh "$feature_count"
    ./gen_oomstore_data.sh "$feature_count"

    oomplay init postgres redis
    oomcli init
    oomcli apply -f "meta/$group_name.yaml"
    oomcli import -g "$group_name" --input-file "data/$group_name.csv"
    oomcli sync -g "$group_name"
}

bench_golang() {
    info "benchmark golang..."
    concurrency=$1
    mkdir -p "$results_dir/golang"
    (
        cd ../golang
        info "warm up..."
        go run ./online_get/main.go "$oomstore_cfg" "$REQUESTS" "$concurrency" "$ROWS" "$feature_count"
        info "benchmarking..."
        go run ./online_get/main.go "$oomstore_cfg" "$REQUESTS" "$concurrency" "$ROWS" "$feature_count" \
            >"$results_dir/golang/n${REQUESTS}_r${ROWS}_f${feature_count}_c${concurrency}"
    )
}

bench_rust() {
    info "benchmark rust..."
    concurrency=$1
    mkdir -p "$results_dir/rust"
    (
        cd ../rust
        info "warm up..."
        cargo run --release -- "$oomstore_cfg" "$REQUESTS" "$concurrency" "$ROWS" "$feature_count"
        info "benchmarking..."
        cargo run --release -- "$oomstore_cfg" "$REQUESTS" "$concurrency" "$ROWS" "$feature_count" \
            >"$results_dir/rust/n${REQUESTS}_r${ROWS}_f${feature_count}_c${concurrency}"
    )
}

bench_python() {
    info "benchmark python..."
    concurrency=$1
    mkdir -p "$results_dir/python"
    (
        cd ../python
        info "warm up..."
        python online_get.py "$oomstore_cfg" "$REQUESTS" "$concurrency" "$ROWS" "$feature_count"
        info "benchmarking..."
        python online_get.py "$oomstore_cfg" "$REQUESTS" "$concurrency" "$ROWS" "$feature_count" \
            >"$results_dir/python/n${REQUESTS}_r${ROWS}_f${feature_count}_c${concurrency}"
    )
}

bench_all() {
    for concurrency in 1 2 4 8 16 32 64 128; do
        info "benchmark (concurrency=${concurrency})..."
        bench_golang "$concurrency"
        bench_rust   "$concurrency"
        bench_python "$concurrency"
    done
}

main() {
    prepare
    bench_all
}

main
