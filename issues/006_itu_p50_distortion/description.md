# Issue #6: ITU-T P.50 sending distortion test

## Description
Implement ITU-T P.50 sending distortion test. Two series:

### NB (mode=0, 8 kHz output) — implement first
1. **Frequency sweep** at −16 dBm0 across 315/408/510/816/1020 Hz
2. **Level sweep** at 1020 Hz from −6 to −31 dBm0

SDR measured via Goertzel filter.

### WB (mode=1, 16 kHz output) — extend after NB passes
1. **Frequency sweep** at −16 dBm0 across ITU-T P.50 WB sending frequencies (e.g. 200/315/408/510/816/1020/1600/2000 Hz)
2. **Level sweep** at 1020 Hz, same levels as NB
3. SDR requirements per ITU-T P.50 Table 7

### SWB (mode=2, 32 kHz output) — extend after WB passes
1. **Frequency sweep** at −16 dBm0 across SWB sending frequencies (up to ~8 kHz)
2. **Level sweep** at 1020 Hz
3. SDR requirements per ITU-T P.50 Table 8

## Status
Open — ready to implement (NB first).
