# Issue #10: Full-scale (0 dBFS) filter chain test

## Description
Prove the filter chain handles true 0 dBFS input (±2047 peak sine) before any data-width reduction, for all 3 modes. No saturation allowed. Output must be bit-exact vs. C golden model.

## Test Plan
- Input: 1 kHz sine at 0 dBFS (amplitude = 2047)
- Run for all 3 modes (NB, WB, SWB)
- Set DGA to compensate for Q17→Q15 and g_fir (per mode)
- Capture RTL output samples
- Run same stimulus through C model (`LP_OSR_step`)
- Compare RTL vs C model output: must be bit-exact (or document any acceptable LSB differences)
- Monitor all internal nodes for saturation/overflow

## Dependencies
- Need to build a C model driver that outputs golden reference samples
- Or implement the C model comparison in the SV testbench

## Status
Open — ready to implement.
