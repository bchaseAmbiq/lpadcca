# Issue #18: Passband Flatness — NB and WB fail frequency response

## Problem
NB and WB modes have excessive passband amplitude variation. The DGA compensates DC gain but not frequency-dependent droop. CIC sinc³ droop is negligible (<0.13 dB) — the problem is in the halfband/LPF filter chain and the HPF DC blocker.

## Theoretical Filter Chain Response (dB re 1 kHz)

### NB (target: ±1 dB passband 300–3400 Hz)
| Freq | Filter theory | Measured | Status |
|------|--------------|----------|--------|
| 100 Hz | +2.0 | +4.0 | FAIL (HPF + meas error) |
| 300 Hz | +1.7 | +2.0 | FAIL |
| 500 Hz | +1.1 | −0.3 | marginal |
| 1000 Hz | 0.0 | 0.0 | ref |
| 2000 Hz | −0.3 | −0.9 | OK |
| 3200 Hz | −2.2 | −1.7 | FAIL |
| 3400 Hz | −6.0 | −4.9 | FAIL (rolloff) |

NB passband ripple: ~3 dB theoretical, ~9 dB measured (measurement artifacts add ~3-4 dB).

### WB (target: ±1.5 dB passband 150–6700 Hz)
| Freq | Filter theory | Measured | Status |
|------|--------------|----------|--------|
| 100 Hz | +1.0 | +4.0 | FAIL |
| 300 Hz | +0.9 | +2.1 | FAIL |
| 1000 Hz | 0.0 | 0.0 | ref |
| 5000 Hz | −1.9 | +0.1 | marginal |
| 6700 Hz | −3.8 | −1.7 | FAIL (rolloff) |

### SWB (target: ±2 dB passband 200–14000 Hz)
SWB is the best — ~2.5 dB theoretical variation. Marginal pass.

## Root Causes
1. **HB/LPF passband droop**: 21-tap Hamming-windowed LPF designs have ~2 dB low-frequency boost relative to mid-band. Short filter length means wider transition band and more passband ripple.
2. **HPF DC blocker adds ripple**: 1st-order IIR with alpha=0.854 (NB) has a gradual high-pass rolloff that interacts with the LPF droop, amplifying low-freq boost in measurements.
3. **Peak-detection measurement error**: Only 256 output samples for freq response — just 3 cycles at 100 Hz / 8 kHz. Needs more samples or FFT-based measurement.

## Proposed Fixes
### Option A: Redesign LPF coefficients (low risk, no area change)
- Use Parks-McClellan (equiripple) design instead of Hamming window
- Target ±0.5 dB passband ripple within the same 21-tap structure
- Only changes coefficient ROM values — no RTL structural change, no power impact

### Option B: Longer LPF filters (moderate risk, area + power increase)
- Increase LPF from 21 to 41 taps for tighter passband control
- Doubles lpf_fir MAC cycles (11→21 per sample) but LPF runs at output rate (8–32 kHz), so power increase is small
- Estimated power: +2–3 µW (registers + MAC switching)
- Area: +400–500 µm² (doubling lpf_fir shift register)

### Option C: Add dedicated droop compensation FIR (high risk)
- Insert a short (7–11 tap) inverse-sinc/droop-comp filter after the LPF
- New RTL module, new pipeline stage
- Estimated power: +3–5 µW
- Area: +300–400 µm²
- Not recommended: the droop is from the HB/LPF, not CIC

### Recommendation
**Option A first** — redesign LPF coefficients with equiripple optimization. If insufficient, move to Option B. This fixes the filter response at zero additional power or area cost.

## Also Fix
- TB freq response measurement: increase to 1024+ output samples
- TB THD+N: add output amplitude check (±1 dB of expected dBFS)
- TB freq response: add passband flatness mask check with proper pass/fail

## Status
Open
