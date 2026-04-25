# LPADCCA OSR Signal Chain — Executive Summary

**Date:** 2026-04-24  
**Technology:** TSMC 12nm FF+ (tcbn12ffcplusbwp6tsa24p96cpd)  
**Supply Voltage:** 0.668 V (TT corner, 25°C)  
**ADC Input Clock:** 3.072 MHz  
**Synthesis Tool:** Cadence Genus 23.12

---

## Overview

LPADCCA is a low-power audio decimation chain that converts 12-bit LPADC output
samples (clocked at 3.072 MHz) to PCM audio at 8/16/32 kHz, selectable by mode.
The primary design goal is **sub-10 µW total power** at the 12nm 0.668 V supply.

The signal chain: ADC capture → CIC decimator → halfband FIR chain (HB19 × 4
stages) → LPF FIR → DGA (programmable gain) → HPF (DC block) → 16-deep output
FIFO → APB slave interface.

---

## Operating Modes

| Mode | Name | Output Rate | Decimation Ratio |
|------|------|------------|-----------------|
| 0    | NB   | 8 kHz      | 384×            |
| 1    | WB   | 16 kHz     | 192×            |
| 2    | SWB  | 32 kHz     | 96×             |

---

## Power Consumption

Power estimated using Cadence Genus with VCD annotation from RTL simulation
(NB mode, 1 kHz sine at −3 dBFS, 60,000 ADC cycles). Reflects actual switching
activity, not worst-case toggle rates.

**VCD-Annotated Power — NB Mode (TT 0.668 V, 25°C)**

| Category            | Power    | % of Total |
|---------------------|----------|-----------|
| Leakage             | 3.61 µW  | 58.2%     |
| Dynamic — Internal  | 1.70 µW  | 27.4%     |
| Dynamic — Switching | 0.90 µW  | 14.4%     |
| **Total**           | **6.21 µW** | 100%  |

**→ Power target of < 10 µW achieved. Margin: 38%.**

Leakage dominates (58%) because the design operates at 0.668 V with many
always-on filter delay-line registers. Dynamic power scales upward in WB and SWB
modes as more clock domains stay active at higher rates; NB is the lowest-power
operating point. Worst-case (100% toggle activity) estimate is 14.6 µW.

17 integrated clock-gating cells suppress switching in inactive filter stages.

---

## Area

| Metric                | Value        |
|-----------------------|-------------|
| Total cells           | 7,356        |
| **Total cell area**   | **3,347 µm²** |
| Sequential (FFs)      | 2,284 cells — 1,775 µm² (53%) |
| Combinational logic   | 4,276 cells — 1,505 µm² (45%) |
| Clock gates           | 17 cells — 10 µm² (<1%)       |

**Block-level area breakdown:**

| Block       | Cells | Area (µm²) | Area % |
|------------|-------|-----------|--------|
| HB19 mux   | 3,072 | 1,623     | 48.5%  |
| LPF FIR    | 1,800 | 670       | 20.0%  |
| HB1 FIR    | 661   | 325       | 9.7%   |
| CIC filter | 568   | 301       | 9.0%   |
| DGA        | 727   | 206       | 6.2%   |
| HPF        | 486   | 191       | 5.7%   |
| ADC capture | 39   | 31        | 0.9%   |

HB19 (4× halfband stages) is the largest block at 48% of area. LPF and HB1 FIR
account for another 30%. Full adder cells (FA1D1, 1,366 instances) total 957 µm²,
reflecting the multi-stage MAC datapaths.

---

## Audio Performance

Results from RTL simulation (`sim_results_0424_1645`), 12-bit signed PCM output.
No overflow observed at 0 dBFS input.

### THD+N — 1 kHz tone, −3 dBFS

| Mode | THD+N   | Dominant distortion    |
|------|---------|------------------------|
| NB   | −78 dB  | H3 ≈ −78 dB (3rd harmonic) |
| WB   | −77 dB  | H3                     |
| SWB  | −74 dB  | H3                     |

Distortion is dominated by 3rd harmonic from CIC normalization quantization.

### ITU-T P.50 SDR — All modes PASS

**NB (8 kHz) — frequency sweep at −16 dBm0:**

| Freq (Hz) | SDR (dB) |
|-----------|---------|
| 315       | 59.2    |
| 408       | >99     |
| 510       | 60.1    |
| 816       | 30.0    |
| 1020      | 61.7    |

**NB — level sweep at 1020 Hz:**

| Level (dBm0) | SDR (dB) |
|-------------|---------|
| −6          | 72.2    |
| −16         | 61.7    |
| −31         | 48.2    |

WB frequency sweep: 55–99+ dB SDR — all PASS  
SWB frequency sweep: 48–66 dB SDR — all PASS

### Other Tests

| Test                     | NB     | WB     | SWB    |
|--------------------------|--------|--------|--------|
| Square-wave stress       | PASS   | PASS   | PASS   |
| Mode switch (3 combos)   | PASS   | PASS   | PASS   |
| Full-scale 0 dBFS        | PASS   | PASS   | PASS   |
| Passband flatness ±1 dB  | **FAIL** | **FAIL** | marginal |

Passband flatness failure in NB/WB is due to HB/LPF passband droop and HPF
interaction. Fix identified: Parks-McClellan equiripple LPF redesign (Issue #18,
zero area/power impact).

---

## Interface

- **APB3 slave** — 10-register map: CTRL, DGA_FRAC, FIFO_STATUS, FIFO_DATA,
  INTEN, INTSTAT, INTCLR, FIFO_THRESH, FIFO_FLUSH, ID (0xA05B_0002)
- **Output FIFO** — 16-deep × 16-bit; empty / half / full / overflow flags;
  per-flag interrupt enables; IRQ output to M55 NVIC
- **SW driver** — `sw/hal/osr_hal.h`, `sw/driver/osr_drv.{h,c}`
- **Register docs** — `docs/osr_regs.html`

---

## Open Items

| # | Issue | Impact |
|---|-------|--------|
| #18 | Passband flatness — NB/WB exceed ±1 dB spec; fix: equiripple LPF (no area/power cost) | Audio quality |
| #1  | NB gain ~2 dB low at 1 kHz — root cause is HB droop, closed by #18 fix | Audio quality |
| #16 | FPGA test image (Stratix 10) — not started | Validation |
