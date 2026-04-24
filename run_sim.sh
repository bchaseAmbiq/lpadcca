#!/bin/bash
echo "=== run_sim.sh started $(TZ='America/Los_Angeles' date '+%Y-%m-%d %H:%M:%S PDT') ==="
rm -rf results
mkdir -p results
bsub -q carrera_xcelium -K -o results/sim.log -R "rusage[XceliumFree=1]" xrun -sv -64bit -access +rwc rtl/adc_capture.v rtl/cic_filter.v rtl/hb1_fir.v rtl/hb19_mux.v rtl/lpf_fir.v rtl/dga.v rtl/hpf.v rtl/osr_top.v tb/osr_tb.sv -top osr_tb

echo "Computing THD+N..."
cd results && python3 ../tb/calc_thdn.py && cd ..

echo "Generating frequency response plots..."
cd results && python3 ../tb/plot_freqresp.py && cd ..

echo "Generating THD+N spectrum plots..."
cd results && python3 ../tb/plot_thdn.py && cd ..

echo "Generating P.50 SDR plots..."
cd results && python3 ../tb/plot_p50.py && cd ..

echo "Generating square-wave plots..."
cd results && python3 ../tb/plot_sqwave.py && cd ..

echo "Generating HTML report..."
cd results && python3 ../tb/gen_report.py && cd ..

TAG=$(TZ='America/Los_Angeles' date '+%m%d_%H%M')
RESZIP="sim_results_${TAG}.zip"
echo "Packaging results into ${RESZIP}..."
cd results && zip -o "../${RESZIP}" sim.log sim_report.html thdn_*.txt thdn_*.png thdn_all.png freqresp_*.txt freqresp_*.png freqresp_all.png p50_*.txt p50_*.png p50_all.png sqwave_*.txt sqwave_*.png sqwave_all.png 2>/dev/null && cd ..
echo "=== run_sim.sh finished $(TZ='America/Los_Angeles' date '+%Y-%m-%d %H:%M:%S PDT') ==="
echo "Done. Results in ${RESZIP}"
