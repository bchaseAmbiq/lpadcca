#!/usr/bin/env python3
import math

hb1 = [3164, 0, -2941, 0, 9040, 14246, 9040, 0, -2941, 0, 3164]
hb2 = [1476, 0, -1134, 0, 1759, 0, -3139, 0, 9740, 15367, 9740, 0, -3139, 0, 1759, 0, -1134, 0, 1476]
lp8 = [83, -106, 129, -63, -213, 797, -1692, 2782, -3843, 4630, 27853, 4630, -3843, 2782, -1692, 797, -213, -63, 129, -106, 83]
lp16 = [59, -45, 0, 154, -489, 1040, -1780, 2600, -3366, 3899, 28672, 3899, -3366, 2600, -1780, 1040, -489, 154, 0, -45, 59]
lp32 = [-79, 118, -218, 389, -626, 911, -1218, 1508, -1751, 1910, 30802, 1910, -1751, 1508, -1218, 911, -626, 389, -218, 118, -79]

def freq_resp(coeffs, f, fs):
    re = 0.0; im = 0.0
    for n in range(len(coeffs)):
        w = 2*math.pi*f*n/fs
        re += coeffs[n] * math.cos(w)
        im -= coeffs[n] * math.sin(w)
    return math.sqrt(re*re + im*im)

def dc(coeffs):
    return sum(coeffs)

print("=== DC gains (Q15 sum) ===")
for name, c in [("HB1",hb1),("HB2",hb2),("LP8",lp8),("LP16",lp16),("LP32",lp32)]:
    print(f"  {name}: {dc(c)}  ({dc(c)/32768.0:.4f})")

# Each decimation-by-2 filter is evaluated at its INPUT rate
# HB1: 256k->128k, HB2 stages cascade from 128k down
# NB: HB1(256k) -> HB2(128k) -> HB2(64k) -> HB2(32k) -> HB2(16k) -> LP8(8k)
# WB: HB1(256k) -> HB2(128k) -> HB2(64k) -> HB2(32k) -> LP16(16k)
# SWB: HB1(256k) -> HB2(128k) -> HB2(64k) -> LP32(32k)

print("\n=== NB composite (dB re 1kHz) ===")
nb_freqs = [100, 200, 300, 500, 1000, 1400, 2000, 2800, 3000, 3200, 3400]
nb_vals = {}
for f in nb_freqs:
    g = freq_resp(hb1, f, 256000.0)
    for fs_in in [128000, 64000, 32000, 16000]:
        g *= freq_resp(hb2, f, fs_in)
    g *= freq_resp(lp8, f, 8000.0)
    nb_vals[f] = g
ref = nb_vals[1000]
for f in nb_freqs:
    db = 20*math.log10(nb_vals[f]/ref) if nb_vals[f] > 0 else -999
    print(f"  {f:5d} Hz: {db:+.2f} dB  (measured: see freqresp_nb.txt)")

print("\n=== WB composite (dB re 1kHz) ===")
wb_freqs = [100, 150, 200, 300, 500, 1000, 2000, 3000, 4000, 5000, 6000, 6400, 6700]
wb_vals = {}
for f in wb_freqs:
    g = freq_resp(hb1, f, 256000.0)
    for fs_in in [128000, 64000, 32000]:
        g *= freq_resp(hb2, f, fs_in)
    g *= freq_resp(lp16, f, 16000.0)
    wb_vals[f] = g
ref = wb_vals[1000]
for f in wb_freqs:
    db = 20*math.log10(wb_vals[f]/ref) if wb_vals[f] > 0 else -999
    print(f"  {f:5d} Hz: {db:+.2f} dB")

print("\n=== SWB composite (dB re 1kHz) ===")
swb_freqs = [100, 150, 200, 300, 500, 1000, 2000, 4000, 6000, 8000, 10000, 12000, 14000]
swb_vals = {}
for f in swb_freqs:
    g = freq_resp(hb1, f, 256000.0)
    for fs_in in [128000, 64000]:
        g *= freq_resp(hb2, f, fs_in)
    g *= freq_resp(lp32, f, 32000.0)
    swb_vals[f] = g
ref = swb_vals[1000]
for f in swb_freqs:
    db = 20*math.log10(swb_vals[f]/ref) if swb_vals[f] > 0 else -999
    print(f"  {f:5d} Hz: {db:+.2f} dB")
