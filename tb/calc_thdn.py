#!/usr/bin/env python3
import math
import sys

MODES = {
    'nb':  {'fs': 8000,  'fund_bin': 512,  'label': 'NB (8 kHz)'},
    'wb':  {'fs': 16000, 'fund_bin': 256,  'label': 'WB (16 kHz)'},
    'swb': {'fs': 32000, 'fund_bin': 128,  'label': 'SWB (32 kHz)'},
}

N = 4096

def load_samples(fname):
    with open(fname) as f:
        return [int(line.strip()) for line in f if line.strip()]

def fft_mag_sq(x):
    n = len(x)
    result = [0.0] * n
    for k in range(n):
        re = 0.0
        im = 0.0
        for t in range(n):
            angle = 2.0 * math.pi * k * t / n
            re += x[t] * math.cos(angle)
            im -= x[t] * math.sin(angle)
        result[k] = re * re + im * im
    return result

try:
    import numpy as np
    HAS_NUMPY = True
except ImportError:
    HAS_NUMPY = False

def compute_thdn(fname, info):
    samples = load_samples(fname)
    if len(samples) < N:
        print(f"  WARNING: only {len(samples)} samples (need {N})")
        return

    x = samples[:N]

    if HAS_NUMPY:
        X = np.fft.fft(x)
        mag_sq = (np.abs(X) ** 2).tolist()
    else:
        mag_sq = fft_mag_sq(x)

    fund_bin = info['fund_bin']
    fund_power = mag_sq[fund_bin]

    total_power = sum(mag_sq[1:N//2])
    noise_power = total_power - fund_power

    if fund_power > 0:
        thdn_db = 10.0 * math.log10(noise_power / fund_power)
    else:
        thdn_db = -999.0

    fund_amp = math.sqrt(fund_power) * 2.0 / N
    fund_dbfs = 20.0 * math.log10(fund_amp / 32768.0) if fund_amp > 0 else -999.0

    h2 = mag_sq[fund_bin * 2] if fund_bin * 2 < N // 2 else 0
    h3 = mag_sq[fund_bin * 3] if fund_bin * 3 < N // 2 else 0
    h4 = mag_sq[fund_bin * 4] if fund_bin * 4 < N // 2 else 0
    h5 = mag_sq[fund_bin * 5] if fund_bin * 5 < N // 2 else 0

    def harm_db(hp):
        if hp > 0 and fund_power > 0:
            return 10.0 * math.log10(hp / fund_power)
        return -999.0

    print(f"  {info['label']}:")
    print(f"    Fundamental: bin {fund_bin}, amplitude {fund_amp:.1f}, {fund_dbfs:.1f} dBFS")
    print(f"    THD+N:  {thdn_db:.1f} dB")
    print(f"    H2: {harm_db(h2):.1f} dB  H3: {harm_db(h3):.1f} dB  H4: {harm_db(h4):.1f} dB  H5: {harm_db(h5):.1f} dB")

print(f"THD+N Analysis (4096-pt FFT, 1 kHz @ -3 dBFS)")
print(f"Using {'numpy FFT' if HAS_NUMPY else 'pure Python DFT (slow)'}")
print()

for mname, info in MODES.items():
    fname = f'thdn_{mname}.txt'
    try:
        compute_thdn(fname, info)
    except FileNotFoundError:
        print(f"  {fname} not found, skipping")
