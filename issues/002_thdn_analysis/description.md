# Issue #2: Compute THD+N from captured data

## Problem
We have 4096-point captures of 1 kHz @ -3 dBFS for all 3 modes (`thdn_swb.txt`, `thdn_wb.txt`, `thdn_nb.txt`) but haven't computed the actual THD+N numbers.

## Approach
- Run FFT on the 4096-point captures (coherent sampling: 1 kHz lands exactly on a bin in all modes)
- Measure fundamental power at bin 128 (SWB), 256 (WB), 512 (NB)
- Sum all other bins (noise + harmonics)
- Report THD+N in dB

## Data
Located in `sim_results_0409_1838/`

## Results (sim_results_0409_1838, DGA shift=-2 unity)
| Mode | Fundamental | THD+N | H2 | H3 | H4 | H5 |
|------|-----------|-------|-----|-----|-----|-----|
| NB   | -4.6 dBFS | -78.0 dB | -97.8 | -78.0 | — | — |
| WB   | -3.9 dBFS | -76.8 dB | — | -78.4 | -98.5 | -82.3 |
| SWB  | -3.2 dBFS | -73.7 dB | -110.9 | -77.8 | -108.1 | -80.5 |

H3 dominates (~-78 dB). THD+N limited by 3rd harmonic, likely from CIC normalization quantization.

## Status
Resolved — analysis script at `tb/calc_thdn.py`.
