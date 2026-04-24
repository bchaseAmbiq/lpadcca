#!/bin/bash
# Synthesize both osr_top (core) and osr_apb (full wrapper with FIFO),
# each into its own results directory.
echo "=== run_genus.sh started $(TZ='America/Los_Angeles' date '+%Y-%m-%d %H:%M:%S PDT') ==="

TAG=$(TZ='America/Los_Angeles' date '+%m%d_%H%M')

for RUN in core apb; do
    if [ "$RUN" = "core" ]; then
        TCL=genus_syn.tcl
        LABEL="osr_top"
    else
        TCL=genus_syn_apb.tcl
        LABEL="osr_apb"
    fi

    echo ""
    echo "--- Synthesizing $LABEL ($TCL) ---"
    OUTDIR="results_${RUN}"
    rm -rf "$OUTDIR"
    mkdir -p "$OUTDIR/reports" "$OUTDIR/outputs"

    rm -rf reports outputs genus.log fv genus.cmd* genus.log* genus.invs*
    mkdir -p reports outputs
    bsub -q carrera_other -K -o genus.log genus -batch -files "$TCL"

    cp -f genus.log "$OUTDIR/"
    cp -f reports/*.rpt "$OUTDIR/reports/" 2>/dev/null
    cp -f outputs/*.v outputs/*.sdc "$OUTDIR/outputs/" 2>/dev/null
    echo "  $LABEL results in syn/$OUTDIR/"
done

rm -rf reports outputs genus.log fv genus.cmd* genus.log* genus.invs*

RESZIP="../syn_results_${TAG}.zip"
echo ""
echo "Packaging all synthesis results into ${RESZIP}..."
zip -ro "${RESZIP}" results_core/ results_apb/ 2>/dev/null
echo "=== run_genus.sh finished $(TZ='America/Los_Angeles' date '+%Y-%m-%d %H:%M:%S PDT') ==="
echo "Done. Results in ${RESZIP}"
