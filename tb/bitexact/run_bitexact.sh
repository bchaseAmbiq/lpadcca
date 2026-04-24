#!/bin/bash
# run_bitexact.sh — Master script for bit-exact RTL vs C-model verification.
#
# Runs all mode × stimulus combinations, compares outputs, and reports
# aggregate pass/fail.
#
# Prerequisites:
#   - Build cmodel_driver: cd tb/bitexact && make
#   - Xcellium (xrun) available via bsub
#
# Usage:
#   cd <project_root>/tb/bitexact
#   ./run_bitexact.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BITEXACT_DIR="$SCRIPT_DIR"

# RTL source files (relative to project root)
RTL_FILES=(
    rtl/adc_capture.v
    rtl/cic_filter.v
    rtl/hb1_fir.v
    rtl/hb19_mux.v
    rtl/lpf_fir.v
    rtl/dga.v
    rtl/hpf.v
    rtl/osr_top.v
)

# Number of ADC-rate input samples per test
NSAMPLES=500000

# Output skip for comparison (initial transient)
SKIP=512

# DGA configurations per mode (from sysparm_init with atten=0, headroom=0)
#   mode 0 (NB):  shift=-3, frac=130637
#   mode 1 (WB):  shift=-3, frac=130828
#   mode 2 (SWB): shift=-2, frac=65672
declare -A DGA_SHIFT=( [0]="-3" [1]="-3" [2]="-2" )
declare -A DGA_FRAC=(  [0]="130637" [1]="130828" [2]="65672" )
declare -A MODE_NAME=( [0]="NB" [1]="WB" [2]="SWB" )

# Stimulus definitions: "name type freq amp"
STIMULI=(
    "sine1k sine 1000 1449"
    "dc1024 dc 0 1024"
    "ramp   ramp 0 0"
)

# Build C model driver
echo "=== Building C-model driver ==="
cd "$BITEXACT_DIR"
make -s clean
make -s
echo "  cmodel_driver built OK"

# Create work directory
WORKDIR="$BITEXACT_DIR/work_$(date +%m%d_%H%M%S)"
mkdir -p "$WORKDIR"
echo "=== Work directory: $WORKDIR ==="

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_TESTS=0

for MODE in 0 1 2; do
    MNAME="${MODE_NAME[$MODE]}"
    SHIFT="${DGA_SHIFT[$MODE]}"
    FRAC="${DGA_FRAC[$MODE]}"

    for STIM_DEF in "${STIMULI[@]}"; do
        read -r SNAME STYPE SFREQ SAMP <<< "$STIM_DEF"

        TESTNAME="${MNAME}_${SNAME}"
        TESTDIR="$WORKDIR/$TESTNAME"
        mkdir -p "$TESTDIR"

        echo ""
        echo "--- Test: $TESTNAME (mode=$MODE, stim=$STYPE, freq=$SFREQ, amp=$SAMP) ---"

        # 1. Generate stimulus
        echo "  [1/4] Generating stimulus..."
        python3 "$BITEXACT_DIR/gen_stim.py" \
            --type "$STYPE" --freq "$SFREQ" --amp "$SAMP" \
            --nsamples "$NSAMPLES" \
            -o "$TESTDIR/stim.txt" 2>&1 | sed 's/^/    /'

        # 2. Run C model
        echo "  [2/4] Running C model..."
        "$BITEXACT_DIR/cmodel_driver" "$MODE" "$STYPE" "$SFREQ" "$SAMP" "$NSAMPLES" \
            > "$TESTDIR/cmodel_out.txt" \
            2>"$TESTDIR/cmodel_stderr.txt"
        CMODEL_LINES=$(wc -l < "$TESTDIR/cmodel_out.txt")
        echo "    C-model produced $CMODEL_LINES output samples"
        cat "$TESTDIR/cmodel_stderr.txt" | sed 's/^/    /'

        # 3. Run RTL simulation via bsub + xrun
        echo "  [3/4] Running RTL simulation (xrun via bsub)..."

        # Build xrun command
        RTL_PATHS=""
        for rf in "${RTL_FILES[@]}"; do
            RTL_PATHS="$RTL_PATHS $PROJECT_ROOT/$rf"
        done

        # Copy stim.txt to a location xrun can find (run from testdir)
        cd "$TESTDIR"
        bsub -q carrera_xcelium -K -o "$TESTDIR/xrun.log" \
            -R "rusage[XceliumFree=1]" \
            xrun -sv -64bit -access +rwc \
                $RTL_PATHS \
                "$BITEXACT_DIR/dump_rtl_vectors.sv" \
                -top dump_rtl_vectors \
                +MODE="$MODE" \
                +DGA_SHIFT="$SHIFT" \
                +DGA_FRAC="$FRAC" \
                +STIM_FILE="$TESTDIR/stim.txt" \
                +RTL_OUT="$TESTDIR/rtl_out.txt"

        if [ -f "$TESTDIR/rtl_out.txt" ]; then
            RTL_LINES=$(wc -l < "$TESTDIR/rtl_out.txt")
            echo "    RTL produced $RTL_LINES output samples"
        else
            echo "    ERROR: rtl_out.txt not found!"
            TOTAL_FAIL=$((TOTAL_FAIL + 1))
            TOTAL_TESTS=$((TOTAL_TESTS + 1))
            continue
        fi

        # 4. Compare
        echo "  [4/4] Comparing..."
        cd "$BITEXACT_DIR"
        if python3 "$BITEXACT_DIR/compare.py" \
            "$TESTDIR/cmodel_out.txt" \
            "$TESTDIR/rtl_out.txt" \
            --skip "$SKIP" 2>&1 | tee "$TESTDIR/compare.log" | sed 's/^/    /'; then
            echo "  >> $TESTNAME: PASS"
            TOTAL_PASS=$((TOTAL_PASS + 1))
        else
            echo "  >> $TESTNAME: FAIL"
            TOTAL_FAIL=$((TOTAL_FAIL + 1))
        fi
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    done
done

echo ""
echo "============================================"
echo "  BIT-EXACT VERIFICATION SUMMARY"
echo "  Tests:  $TOTAL_TESTS"
echo "  PASS:   $TOTAL_PASS"
echo "  FAIL:   $TOTAL_FAIL"
if [ "$TOTAL_FAIL" -eq 0 ]; then
    echo "  STATUS: ALL TESTS PASSED"
else
    echo "  STATUS: $TOTAL_FAIL TEST(S) FAILED"
fi
echo "  Work dir: $WORKDIR"
echo "============================================"

exit "$TOTAL_FAIL"
