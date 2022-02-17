#!/usr/bin/env bash
set -euo pipefail
SDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) && cd "$SDIR" || exit 1

usage() { echo "Usage: $(basename "$0") <group_name>" >&2; }

[ $# -ne 1 ] && usage && exit 1

group_name=$1

oomplay init postgres redis
oomcli init
oomcli apply -f "meta/$group_name.yaml"
oomcli import -g "$group_name" --input-file "data/$group_name.csv"
oomcli sync -g "$group_name"
