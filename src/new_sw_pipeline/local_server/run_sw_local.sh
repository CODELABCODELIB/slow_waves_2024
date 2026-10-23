#!/bin/bash
# Run the refined-ICA SW pipeline on the local server (no Slurm), N_PARALLEL datasets at a time.
# Uses the same dataset_list.txt and MATLAB wrapper as the ALICE run, so IDs/outputs are identical.
#   ./run_sw_local.sh           -> (re)build dataset_list.txt and run all tasks
#   ./run_sw_local.sh 1         -> only task 1 (test run)
#   ./run_sw_local.sh 3 7 12    -> only these tasks (uses the existing dataset_list.txt)
#   FORCE=1 ./run_sw_local.sh   -> also rerun tasks that already have outputs
# To keep it running after logging out:
#   nohup ./run_sw_local.sh > run_sw_local.out 2>&1 &
set -euo pipefail

# ---- Settings: edit these ----------------------------------------------------
SW_INPUT_DIR=${SW_INPUT_DIR:-/mnt/ZETA18/User_Specific_Data_Storage/ruchella/Feb_2022_BS_to_tap_classification_EEG}
SW_OUTPUT_DIR=${SW_OUTPUT_DIR:-/mnt/ZETA18/User_Specific_Data_Storage/ruchella/slow_waves/sw_refined_ica_rerun}
EEGLAB_DIR=${EEGLAB_DIR:-}             # empty: search under /home/ruchella/imports
N_PARALLEL=${N_PARALLEL:-4}           # datasets at the same time (~40 GB RAM each)
THREADS_PER_RUN=${THREADS_PER_RUN:-4}
MATLAB=${MATLAB:-}                    # empty: matlab on PATH, else ~/matlab_2024b/bin/matlab
# ------------------------------------------------------------------------------

if [ -z "$MATLAB" ]; then
    if command -v matlab > /dev/null; then
        MATLAB=matlab
    else
        MATLAB=$HOME/matlab_2024b/bin/matlab
    fi
fi
if ! command -v "$MATLAB" > /dev/null; then
    echo "MATLAB not found at '$MATLAB'; set MATLAB at the top of $0" >&2
    exit 1
fi
echo "MATLAB: $MATLAB"

CODE_DIR=$(cd "$(dirname "$0")/.." && pwd)
PIPELINE_DIR=$CODE_DIR/new_sw_pipeline
ALICE_DIR=$CODE_DIR/alice
LIST="$SW_OUTPUT_DIR/dataset_list.txt"
LOG_DIR="$SW_OUTPUT_DIR/logs"

if [ -z "$EEGLAB_DIR" ]; then
    EEGLAB_DIR=$(find /home/ruchella/imports -maxdepth 4 -name eeglab.m -printf '%h\n' 2>/dev/null | head -1)
fi
if [ -z "$EEGLAB_DIR" ] || [ ! -f "$EEGLAB_DIR/eeglab.m" ]; then
    echo "EEGLAB not found; set EEGLAB_DIR at the top of $0" >&2
    exit 1
fi
echo "EEGLAB: $EEGLAB_DIR"

# EEGLAB <= 2020 detects MATLAB via version(1) > '5', which fails for MATLAB R2024a+
# ('24.x') and makes it run its Octave-only setup.
if grep -q "if v(1) > '5'" "$EEGLAB_DIR/eeglab.m"; then
    echo "This EEGLAB mistakes MATLAB R2024a+ for Octave. Patch it once (backup: eeglab.m.bak):" >&2
    echo "  sed -i.bak \"s/if v(1) > '5'/if exist('OCTAVE_VERSION','builtin') == 0/\" '$EEGLAB_DIR/eeglab.m'" >&2
    exit 1
fi

mkdir -p "$SW_OUTPUT_DIR" "$LOG_DIR"
if [ $# -eq 0 ] || [ ! -f "$LIST" ]; then
    # Keep in sync with alice/submit_sw_array.sh (skip folders containing RW or DS).
    (cd "$SW_INPUT_DIR" && find . -type f -name '*.set' -printf '%P\n') \
        | awk -F/ '{folder = $0; sub("/[^/]*$", "", folder); if (NF == 1 || folder !~ /RW|DS/) print}' \
        | LC_ALL=C sort > "$LIST"
fi
N=$(wc -l < "$LIST")
if [ "$N" -eq 0 ]; then
    echo "No .set files found under $SW_INPUT_DIR" >&2
    exit 1
fi

if [ $# -eq 0 ]; then
    TASKS=$(seq 1 "$N")
else
    TASKS="$*"
fi

# Same ID rule as run_sw_pipeline_alice.m.
dataset_id() { sed -n "${1}p" "$LIST" | sed -e 's/\.set$//' -e 's/[^A-Za-z0-9_.-]/_/g'; }

TODO=()
for i in $TASKS; do
    out="$SW_OUTPUT_DIR/Outputs/$(dataset_id "$i")/refined"
    if [ "${FORCE:-0}" != 1 ] && [ -f "$out/wave_results.mat" ] && [ -f "$out/cleaned_EEG.mat" ]; then
        echo "skip  $i (outputs exist)"
    else
        TODO+=("$i")
    fi
done
echo "$N datasets in $LIST; running ${#TODO[@]} task(s), $N_PARALLEL in parallel. Logs: $LOG_DIR"

run_one() {
    local i=$1
    if SW_TASK_ID=$i SW_INPUT_DIR=$SW_INPUT_DIR SW_OUTPUT_DIR=$SW_OUTPUT_DIR "$MATLAB" -batch \
        "maxNumCompThreads($THREADS_PER_RUN); addpath('$EEGLAB_DIR'); eeglab nogui; addpath('$PIPELINE_DIR'); addpath('$ALICE_DIR'); run_sw_pipeline_alice" \
        > "$LOG_DIR/task_$i.log" 2>&1; then
        echo "OK     $i"
    else
        echo "FAILED $i"
    fi
}
export -f run_one
export SW_INPUT_DIR SW_OUTPUT_DIR EEGLAB_DIR PIPELINE_DIR ALICE_DIR LOG_DIR THREADS_PER_RUN MATLAB

RESULTS="$LOG_DIR/run_status_$(date +%Y%m%d_%H%M%S).txt"
if [ ${#TODO[@]} -gt 0 ]; then
    printf '%s\n' "${TODO[@]}" | xargs -P "$N_PARALLEL" -I{} bash -c 'run_one {}' | tee "$RESULTS"
fi

FAILED=$(grep '^FAILED' "$RESULTS" 2>/dev/null | awk '{print $2}' | sort -n | tr '\n' ' ' || true)
OK_COUNT=$(awk '/^OK/ {n++} END {print n+0}' "$RESULTS" 2>/dev/null || echo 0)
echo "Done: $OK_COUNT ok, $(echo $FAILED | wc -w) failed."
if [ -n "$FAILED" ]; then
    echo "Rerun failed tasks with: $0 $FAILED"
fi

if ls "$SW_OUTPUT_DIR"/batch_summaries/*.csv > /dev/null 2>&1; then
    awk 'FNR==1 && NR!=1 {next} {print}' "$SW_OUTPUT_DIR"/batch_summaries/*.csv > "$SW_OUTPUT_DIR/batch_summary_all.csv"
    echo "Merged summary: $SW_OUTPUT_DIR/batch_summary_all.csv"
fi
