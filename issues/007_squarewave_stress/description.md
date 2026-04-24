# Issue #7: Square-wave stress test

## Description
Apply a full-scale square wave at the ADC input and verify the filter chain handles it without overflow, saturation, or latch-up in all 3 modes. Monitor all internal node widths for saturation.

## Test Plan
- Input: ±2047 square wave at various frequencies (e.g. 100 Hz, 1 kHz, Nyquist/2)
- Run for all 3 modes (NB, WB, SWB)
- Check: no overflow flags, output settles to expected filtered waveform
- Monitor CIC integrators, HB/LPF accumulators, DGA output, HPF clamp

## Status
Open — ready to implement.
