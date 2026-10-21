#!/bin/bash
# Submit one array task per .set file under SW_INPUT_DIR (paths read from sw_pipeline_array.slurm).
# Like gen_set_file_names.m, files in folders whose name contains RW or DS are skipped.
#   ./submit_sw_array.sh          -> (re)build dataset_list.txt and submit all (max 20 running)
#   ./submit_sw_array.sh 1        -> only task 1 (test run)
#   ./submit_sw_array.sh 3,7,12   -> rerun selected tasks (uses the existing dataset_list.txt)
set -euo pipefail

cd "$(dirname "$0")"
SLURM_SCRIPT=sw_pipeline_array.slurm

read_var() { grep -m1 "^export $1=" "$SLURM_SCRIPT" | cut -d= -f2 | awk '{print $1}'; }
SW_INPUT_DIR=$(read_var SW_INPUT_DIR)
SW_OUTPUT_DIR=$(read_var SW_OUTPUT_DIR)
LIST="$SW_OUTPUT_DIR/dataset_list.txt"

mkdir -p "$SW_OUTPUT_DIR" logs
if [ $# -eq 0 ] || [ ! -f "$LIST" ]; then
    (cd "$SW_INPUT_DIR" && find . -type f -name '*.set' -printf '%P\n') \
        | awk -F/ '{folder = $0; sub("/[^/]*$", "", folder); if (NF == 1 || folder !~ /RW|DS/) print}' \
        | LC_ALL=C sort > "$LIST"
fi

N=$(wc -l < "$LIST")
if [ "$N" -eq 0 ]; then
    echo "No .set files found under $SW_INPUT_DIR (edit SW_INPUT_DIR in $SLURM_SCRIPT)" >&2
    exit 1
fi

ARRAY=${1:-1-$N%20}
echo "$N datasets listed in $LIST; submitting --array=$ARRAY"
nl -w4 "$LIST" | head -20
[ "$N" -gt 20 ] && echo "   ... (see $LIST)"

sbatch --array="$ARRAY" "$SLURM_SCRIPT"
