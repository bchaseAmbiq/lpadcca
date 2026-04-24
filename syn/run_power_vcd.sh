#!/bin/bash
# Two-step flow: (1) sim to generate VCD, (2) syn with VCD-annotated power
echo "=== run_power_vcd.sh started $(TZ='America/Los_Angeles' date '+%Y-%m-%d %H:%M:%S PDT') ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VCD_PATH="$SCRIPT_DIR/power.vcd"

# Step 1: Generate probe TCL with absolute VCD path
echo ""
echo "--- Step 1: Generating VCD from power_vcd_tb ---"
cat > "$SCRIPT_DIR/probe_tmp.tcl" <<EOF
database -open power_db -vcd -into $VCD_PATH -default
probe -create power_vcd_tb.u_dut -all -depth all -database power_db
run
exit
EOF

cd "$PROJECT_ROOT"
rm -f "$VCD_PATH"
bsub -q carrera_xcelium -K -o "$SCRIPT_DIR/vcd_sim.log" -R "rusage[XceliumFree=1]" \
    xrun -sv -64bit -access +rwc \
    rtl/adc_capture.v \
    rtl/cic_filter.v \
    rtl/hb1_fir.v \
    rtl/hb19_mux.v \
    rtl/lpf_fir.v \
    rtl/dga.v \
    rtl/hpf.v \
    rtl/osr_top.v \
    tb/power_vcd_tb.sv \
    -top power_vcd_tb \
    -input "$SCRIPT_DIR/probe_tmp.tcl"

rm -f "$SCRIPT_DIR/probe_tmp.tcl"

if [ ! -f "$VCD_PATH" ]; then
    echo "ERROR: power.vcd not generated at $VCD_PATH"
    echo "Searching..."
    find "$PROJECT_ROOT" -name 'power.vcd' -maxdepth 2 2>/dev/null
    exit 1
fi
VCD_SIZE=$(ls -lh "$VCD_PATH" | awk '{print $5}')
echo "  VCD generated: $VCD_PATH ($VCD_SIZE)"

# Step 2: Synthesize with VCD power
echo ""
echo "--- Step 2: Genus synthesis with VCD power ---"
cd "$SCRIPT_DIR"
rm -rf reports outputs genus.log fv genus.cmd* genus.log* genus.invs*
mkdir -p reports outputs
bsub -q carrera_other -K -o genus.log genus -batch -files genus_syn_vcd.tcl

echo ""
echo "--- Results ---"
if [ -f reports/power_vcd.rpt ]; then
    echo "VCD-annotated power (realistic):"
    grep 'Subtotal' reports/power_vcd.rpt
fi
if [ -f reports/power_default.rpt ]; then
    echo "Default-toggle power (pessimistic):"
    grep 'Subtotal' reports/power_default.rpt
fi

TAG=$(TZ='America/Los_Angeles' date '+%m%d_%H%M')
RESZIP="../syn_vcd_results_${TAG}.zip"
echo ""
echo "Packaging into ${RESZIP}..."
zip -o "${RESZIP}" genus.log vcd_sim.log reports/*.rpt outputs/*.v outputs/*.sdc 2>/dev/null

rm -f "$VCD_PATH"
rm -rf reports outputs genus.log fv genus.cmd* genus.log* genus.invs* vcd_sim.log xcelium.d

echo "=== run_power_vcd.sh finished $(TZ='America/Los_Angeles' date '+%Y-%m-%d %H:%M:%S PDT') ==="
echo "Done. Results in ${RESZIP}"
