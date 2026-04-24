#!/usr/bin/env python3
import math

hb1 = [3164, 0, -2941, 0, 9040, 14246, 9040, 0, -2941, 0, 3164]
hb2 = [1476, 0, -1134, 0, 1759, 0, -3139, 0, 9740, 15367, 9740, 0, -3139, 0, 1759, 0, -1134, 0, 1476]
lp8 = [83, -106, 129, -63, -213, 797, -1692, 2782, -3843, 4630, 27853, 4630, -3843, 2782, -1692, 797, -213, -63, 129, -106, 83]
lp16 = [59, -45, 0, 154, -489, 1040, -1780, 2600, -3366, 3899, 28672, 3899, -3366, 2600, -1780, 1040, -489, 154, 0, -45, 59]
lp32 = [-79, 118, -218, 389, -626, 911, -1218, 1508, -1751, 1910, 30802, 1910, -1751, 1508, -1218, 911, -626, 389, -218, 118, -79]

g_hb1 = sum(hb1) / 32768.0
g_hb2 = sum(hb2) / 32768.0
g_lp8 = sum(lp8) / 32768.0
g_lp16 = sum(lp16) / 32768.0
g_lp32 = sum(lp32) / 32768.0

print(f"HB1  DC gain: {g_hb1:.6f}")
print(f"HB2  DC gain: {g_hb2:.6f}")
print(f"LP8  DC gain: {g_lp8:.6f}")
print(f"LP16 DC gain: {g_lp16:.6f}")
print(f"LP32 DC gain: {g_lp32:.6f}")

g_nb  = g_hb1 * (g_hb2**4) * g_lp8
g_wb  = g_hb1 * (g_hb2**3) * g_lp16
g_swb = g_hb1 * (g_hb2**2) * g_lp32

print(f"\nNB  g_fir = {g_nb:.6f}  ({20*math.log10(g_nb):+.2f} dB)")
print(f"WB  g_fir = {g_wb:.6f}  ({20*math.log10(g_wb):+.2f} dB)")
print(f"SWB g_fir = {g_swb:.6f}  ({20*math.log10(g_swb):+.2f} dB)")

print("\nDGA settings (compensate g_fir * 4 for Q17->Q15):")
for name, gf in [("NB", g_nb), ("WB", g_wb), ("SWB", g_swb)]:
    linear = 1.0 / (gf * 4.0)
    shift = 0
    frac = linear
    while frac >= 2.0:
        frac /= 2.0
        shift += 1
    while frac < 1.0:
        frac *= 2.0
        shift -= 1
    q16 = int(round(frac * 65536))
    if q16 < 65536:
        q16 = 65536
    if q16 > 131071:
        q16 = 131071
    print(f"  {name}: shift={shift:+d}  frac_q16={q16}  (linear={linear:.6f}  frac={frac:.6f})")
