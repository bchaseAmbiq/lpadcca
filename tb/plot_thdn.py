#!/usr/bin/env python3
import math
import sys
from datetime import datetime, timezone, timedelta

try:
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    import numpy as np
except ImportError:
    print("ERROR: matplotlib/numpy not found. Install with: pip3 install matplotlib numpy")
    sys.exit(1)

MODES = [
    ('nb',  {'label': 'NB (8 kHz)',  'fs': 8000,  'fund_bin': 512}),
    ('wb',  {'label': 'WB (16 kHz)', 'fs': 16000, 'fund_bin': 256}),
    ('swb', {'label': 'SWB (32 kHz)', 'fs': 32000, 'fund_bin': 128}),
]

N = 4096

def load_samples(fname):
    with open(fname) as f:
        return [int(line.strip()) for line in f if line.strip()]

def plot_thdn(ax, mname, info):
    fname = f'thdn_{mname}.txt'
    try:
        samples = load_samples(fname)
    except FileNotFoundError:
        ax.text(0.5, 0.5, f'{fname} not found', transform=ax.transAxes, ha='center')
        return

    x = np.array(samples[:N], dtype=float)
    X = np.fft.fft(x)
    mag = np.abs(X[:N//2])
    mag_db = np.full_like(mag, -200.0)
    nonzero = mag > 0
    mag_db[nonzero] = 20.0 * np.log10(mag[nonzero] / (N / 2))

    fs = info['fs']
    freqs = np.arange(N//2) * fs / N
    fund_bin = info['fund_bin']

    fund_db = mag_db[fund_bin]
    fund_amp = mag[fund_bin] * 2.0 / N
    fund_dbfs = 20.0 * math.log10(fund_amp / 32768.0) if fund_amp > 0 else -999

    mag_sq = np.abs(X[:N//2])**2
    fund_pwr = mag_sq[fund_bin]
    total_pwr = np.sum(mag_sq[1:])
    noise_pwr = total_pwr - fund_pwr
    thdn_db = 10.0 * math.log10(noise_pwr / fund_pwr) if fund_pwr > 0 else -999

    h2_bin = fund_bin * 2
    h3_bin = fund_bin * 3
    h4_bin = fund_bin * 4
    h5_bin = fund_bin * 5

    ax.plot(freqs[1:], mag_db[1:], 'b-', linewidth=0.6, alpha=0.8)

    ax.plot(freqs[fund_bin], mag_db[fund_bin], 'go', markersize=8, zorder=5,
            label=f'Fund {freqs[fund_bin]:.0f} Hz ({fund_dbfs:.1f} dBFS)')

    for hk, hlbl, clr in [(h2_bin, 'H2', 'red'), (h3_bin, 'H3', 'orange'),
                           (h4_bin, 'H4', 'purple'), (h5_bin, 'H5', 'brown')]:
        if 1 < hk < N//2:
            hdb = mag_db[hk] - mag_db[fund_bin]
            ax.plot(freqs[hk], mag_db[hk], 'v', color=clr, markersize=7, zorder=5,
                    label=f'{hlbl} {freqs[hk]:.0f} Hz ({hdb:.1f} dBc)')

    noise_floor = np.median(mag_db[1:])
    ax.axhline(noise_floor, color='gray', linestyle=':', linewidth=0.6, alpha=0.5)

    ax.set_xlabel('Frequency (Hz)', fontsize=9)
    ax.set_ylabel('Magnitude (dBFS)', fontsize=9)
    ax.set_title(f'{info["label"]}  THD+N = {thdn_db:.1f} dB', fontsize=10, fontweight='bold')
    ax.set_xlim(0, fs / 2)
    ax.set_ylim(noise_floor - 10, fund_db + 10)
    ax.grid(True, which='major', alpha=0.3)
    ax.legend(fontsize=7, loc='upper right')

    pdt = timezone(timedelta(hours=-7))
    ts = datetime.now(pdt).strftime('%Y-%m-%d %H:%M PDT')
    ax.text(0.99, 0.01, ts, transform=ax.transAxes, fontsize=6,
            ha='right', va='bottom', color='gray')

fig, axes = plt.subplots(1, 3, figsize=(20, 6))
for idx, (mname, info) in enumerate(MODES):
    plot_thdn(axes[idx], mname, info)
fig.suptitle('OSR Signal Chain — THD+N Spectrum (1 kHz @ -3 dBFS)', fontsize=14, fontweight='bold', y=1.02)
fig.tight_layout()
fig.savefig('thdn_all.png', dpi=150, bbox_inches='tight')
plt.close(fig)
print("Saved thdn_all.png")

for mname, info in MODES:
    fig_s, ax_s = plt.subplots(figsize=(10, 6))
    plot_thdn(ax_s, mname, info)
    fig_s.tight_layout()
    outfile = f'thdn_{mname}.png'
    fig_s.savefig(outfile, dpi=150, bbox_inches='tight')
    plt.close(fig_s)
    print(f"Saved {outfile}")

print("THD+N plots complete.")
