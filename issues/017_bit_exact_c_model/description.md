# Issue #17: Bit-Exact RTL vs C Model Verification

## Summary
Confirm that the RTL produces bit-for-bit identical output to the C reference model (`ref/lpadc_osr.c`) for all modes. Issue #10 covers 0 dBFS full-scale; this issue covers a comprehensive bit-exact comparison across multiple stimulus types and levels.

## Current Status
- The testbench checks THD+N, frequency response, P.50 SDR, square-wave, and full-scale — all 16 tests PASS.
- However, there is NO explicit bit-exact comparison against the C model output. The TB generates stimulus internally and checks behavioral metrics (SDR, overflow counts, rate), not sample-by-sample matching.

## Requirements
- Run the C model with identical stimulus vectors, dump sample-by-sample output
- Run RTL sim with same stimulus, dump sample-by-sample output
- Diff the two outputs — must be identical (zero LSB difference)
- Cover: NB/WB/SWB × sine 1kHz -3dBFS, multi-tone, DC, ramp

## Deliverables
- Script to run C model and capture output vectors
- TB mode or script to dump RTL output vectors
- Comparison script with pass/fail report
