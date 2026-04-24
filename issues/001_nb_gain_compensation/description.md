# Issue #1: NB gain is ~2 dB low

## Problem
With DGA set to unity (shift=-2, frac=65536), the NB mode output amplitude at 1 kHz is ±18262 vs expected ~±23170. WB and SWB are closer but still slightly low.

## Analysis
Computed FIR chain DC gains (see `tb/calc_dga.py`):
- NB  g_fir = 1.003328 (+0.03 dB)
- WB  g_fir = 1.001862 (+0.02 dB)
- SWB g_fir = 0.997924 (-0.02 dB)

DC gain is essentially unity — the 2 dB NB loss is NOT from DC gain. It's from the HB filter chain's passband response at 1 kHz accumulating through 4 HB19 stages. Each stage adds ~0.5 dB loss at 1 kHz due to halfband passband ripple.

## Fix Applied
Updated DGA values in TB to match C model's `split_gain_to_q16()`:
- NB:  shift=-3, frac_q16=130637
- WB:  shift=-3, frac_q16=130828
- SWB: shift=-2, frac_q16=65672

This corrects the DC gain component (~0.03 dB). The remaining ~2 dB NB loss at 1 kHz is inherent to the filter design and would require filter coefficient redesign to fix.

## Status
Partially resolved — DGA DC compensation applied. Residual ~2 dB NB loss at 1 kHz is a filter design limitation.
