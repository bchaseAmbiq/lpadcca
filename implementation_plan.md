# OSR Signal Chain RTL — Implementation Plan

## Status
- **Plan presented**: awaiting user sign-off before coding begins
- **Session time**: ~30 min elapsed as of save

## Ground Rules
1. Don't guess — ask to clarify when uncertain
2. Deliverables zipped as `name_MMDD_HHMM.zip` (e.g. `osr_0408_1400.zip`)
3. Track all prompts in `session_log.md` with approximate timestamps
4. ADC macro (green box) already exists — we are building the blue boxes only
5. User has working integer C model (`lpadc_osr.c`, `sysparm.c`) and `osr_decimators.h` with coefficients
6. Test vectors: none yet — generate basic sine-tone stimulus for NB/WB/SWB to start
7. Future DV additions planned: THD+N, noise, two-tone IMD, squarewave stress, FIFO tests, coef read/write

## Reference Files in Workspace
| File | Purpose |
|------|---------|
| `OSR_Orig.jpg` | Block diagram (primary reference) |
| `OSRSignalChain.jpg` | Earlier/alternate block diagram |
| `lpadc_p1_eoc_adcout.png` | ADC timing: clk, eoc, adc_out[11:0] |
| `lpadc_osr.c` / `lpadc_osr.h` | C model: CIC, HB chain, LPF, DGA, HPF |
| `sysparm.c` / `sysparm.h` | Config init: mode selection, coef quantization, DGA calc |
| `osr_decimators.h` | Float coefficients: HB1(11), HB2(19), LP8/LP16/LP32(21 each) |

## Top-Level Interface
```
osr_top
  Inputs:  clk (3.072 MHz), rst_n, eoc, adc_data[11:0], mode[1:0]
           dga_shift[3:0], dga_frac_q16[16:0]
  Outputs: data_out[15:0], data_valid
```

## Block Hierarchy
```
osr_top
 ├── adc_capture      — negedge sample of adc_data when eoc high
 ├── cic_filter       — R=12, N=3 (3 integrators + 3 combs + normalize)
 ├── hb1_fir          — 11-tap halfband (dedicated, parallel MAC, 4 mults)
 ├── hb19_mux         — 19-tap halfband (time-mux HB2-5, parallel MAC, 6 mults)
 ├── lpf_fir          — 21-tap symmetric (serial MAC, 1 mult, 3 coef sets by mode)
 ├── dga              — shift + Q16 fractional multiply
 └── hpf              — 1st-order IIR DC blocker
```

## Microarchitecture

### adc_capture
- Negedge FF captures `adc_data[11:0]` when `eoc==1`
- Re-registers into posedge domain (metastability-safe crossing)
- Output: 12-bit signed, valid pulse

### CIC Filter (R=12, N=3)
- 3 integrator accumulators at 3.072 MHz (26-bit internal width)
- Phase counter 0–11, triggers comb section at count==11
- 3 comb differentiators (delay-and-subtract) at 256 kHz decimated rate
- Normalize: `(d3 × 607 + (1<<19)) >> 20` (≈ ÷1728, <0.03% error)
- Output: `norm_q11 << 6` → Q17 (18 bits)
- CIC gain: R^N = 12^3 = 1728, needs ceil(log2(1728))=11 extra bits → 23-bit minimum, using 26

### HB1 FIR (11-tap, dedicated)
- Symmetric halfband: non-zero at even indices + center
- Unique non-zero Q15 coefficients: {3164, −2941, 9040, 14246(center)}
- Parallel MAC: 3 pre-adds (symmetric pairs) + 4 multiplies + accumulate, 1 cycle
- Phase toggle: compute only on kept phase, decimates 256→128 kHz
- Accumulate 64-bit, final round: `(acc + 16384) >> 15`
- Input/output: 18-bit (Q17)

### HB19 Mux (19-tap, time-multiplexed for HB2–HB5)
- Single FIR datapath shared across up to 4 stages
- 4 separate sets of 19-entry delay-line registers (one per stage)
- Same HB2 coefficients for all stages
- Unique non-zero Q15: {1476, −1134, 1759, −3139, 9740, 15367(center)}
- Parallel MAC: 5 pre-adds + 6 multiplies per stage
- FSM sequences through active stages: ~4 cycles/stage, worst-case 16 cycles
- Timing budget: 24 clocks between HB2 inputs (256kHz CIC rate ÷ HB1 decimate = 128kHz → 3.072M/128k = 24)
- Number of active stages depends on mode: NB=4, WB=3, SWB=2

### LPF FIR (21-tap symmetric)
- Serial MAC architecture: 1 multiplier, 11 cycles per output (10 pre-adds + center)
- 3 coefficient ROMs (LP8/LP16/LP32), selected by mode[1:0]
- Runs at output rate: NB=8kHz, WB=16kHz, SWB=32kHz
- Ample time budget (96–384 clocks between outputs)
- Accumulate 64-bit, round: `(acc + 16384) >> 15`

### DGA (Digital Gain Adjust)
- `dga_out = (lpf_out × dga_frac_q16) >> 16`
- Then arithmetic shift by `dga_shift` (left if positive, right if negative)
- Registered output

### HPF (DC Blocker)
- 1st-order IIR: `y[n] = (x[n] − x[n−1]) + α × y[n−1]`
- α in Q15, mode-dependent: NB=0.8546→27999, WB=0.9428→30893, SWB=0.9710→31817
- Output clamp to signed 16-bit [-32768, 32767]

## Q15 Coefficients (quantized from osr_decimators.h)

### HB1 (11-tap) — non-zero only
```
h[0]=h[10]= 3164    (0.0965385 × 32768)
h[2]=h[8] = −2941   (−0.0897180 × 32768)
h[4]=h[6] =  9040   (0.2757999 × 32768)
h[5]      = 14246   (0.4347592 × 32768, center)
```

### HB2 (19-tap) — non-zero only
```
h[0]=h[18]=  1476   (0.0450513 × 32768)
h[2]=h[16]= −1134   (−0.0346113 × 32768)
h[4]=h[14]=  1759   (0.0536854 × 32768)
h[6]=h[12]= −3139   (−0.0957992 × 32768)
h[8]=h[10]=  9740   (0.2972444 × 32768)
h[9]      = 15367   (0.4688587 × 32768, center)
```

### LP8 (21-tap, NB 8kHz)
```
{83, −106, 129, −63, −213, 797, −1692, 2782, −3843, 4630,
 27853,
 4630, −3843, 2782, −1692, 797, −213, −63, 129, −106, 83}
```

### LP16 (21-tap, WB 16kHz)
```
{59, −45, 0, 154, −489, 1040, −1780, 2600, −3366, 3899,
 28672,
 3899, −3366, 2600, −1780, 1040, −489, 154, 0, −45, 59}
```

### LP32 (21-tap, SWB 32kHz)
```
{−79, 118, −218, 389, −626, 911, −1218, 1508, −1751, 1910,
 30802,
 1910, −1751, 1508, −1218, 911, −626, 389, −218, 118, −79}
```

## Assumptions
1. Single clock domain (3.072 MHz posedge), clock enables for multi-rate — no divided clocks
2. ADC data sampled on negedge clk when eoc==1, re-registered to posedge domain
3. Mode is static during operation (no glitch-free dynamic mode switching required)
4. HB2–HB5 all use identical HB2 coefficients (confirmed from C code: `sysparm.c` lines 123–127)
5. EOC arrives once per clock cycle (one ADC sample per 3.072 MHz tick)
6. Low-power priority: time-multiplexed HB, serial MAC for LPF, clock-gated blocks

## DV Testbench Plan (Phase 1 — basic)
- SV testbench (`osr_tb.sv`)
- ADC model generates 1 kHz sine tone, 12-bit quantized, with eoc protocol
- Three test modes: NB (8kHz out), WB (16kHz out), SWB (32kHz out)
- Captures DUT output to text file for offline analysis
- Basic self-check: verify output valid strobes at expected rate

## File Organization
```
rtl/
  osr_top.v
  adc_capture.v
  cic_filter.v
  hb1_fir.v
  hb19_mux.v
  lpf_fir.v
  dga.v
  hpf.v
tb/
  osr_tb.sv
```

## Next Steps (when session resumes)
1. Get user sign-off on this plan
2. Start coding RTL block by block (CIC first)
3. Lint each block as written
4. Build testbench
5. Package into zip
