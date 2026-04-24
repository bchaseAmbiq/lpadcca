#!/usr/bin/env python3
import csv
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
    ('nb',  'NB (8 kHz)'),
    ('wb',  'WB (16 kHz)'),
    ('swb', 'SWB (32 kHz)'),
]

SDR_THRESH = 25.0

def load_p50(fname):
    rows = []
    with open(fname) as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append({
                'test': r['test'],
                'freq': int(r['freq_hz']),
                'level': float(r['level_dbm0']),
                'sdr': float(r['sdr_db']),
                'overflow': int(r['overflow']),
                'pass': int(r['pass']),
            })
    return rows

def plot_freq_sweep(ax, rows, mode_label):
    freq_rows = [r for r in rows if r['test'] == 'freq']
    if not freq_rows:
        ax.text(0.5, 0.5, 'No freq sweep data', transform=ax.transAxes, ha='center')
        return
    freqs = [r['freq'] for r in freq_rows]
    sdrs = [r['sdr'] for r in freq_rows]
    colors = ['green' if r['pass'] else 'red' for r in freq_rows]
    ax.bar(range(len(freqs)), sdrs, color=colors, alpha=0.8, edgecolor='black', linewidth=0.5)
    ax.set_xticks(range(len(freqs)))
    ax.set_xticklabels([str(f) for f in freqs], rotation=45, fontsize=7)
    ax.axhline(SDR_THRESH, color='red', linestyle='--', linewidth=1, label=f'Threshold {SDR_THRESH} dB')
    ax.set_xlabel('Frequency (Hz)', fontsize=9)
    ax.set_ylabel('SDR (dB)', fontsize=9)
    ax.set_title(f'{mode_label} — Freq Sweep @ −16 dBm0', fontsize=10, fontweight='bold')
    ax.set_ylim(0, max(sdrs) * 1.15)
    ax.legend(fontsize=7)
    ax.grid(True, axis='y', alpha=0.3)

def plot_level_sweep(ax, rows, mode_label):
    level_rows = [r for r in rows if r['test'] == 'level']
    if not level_rows:
        ax.text(0.5, 0.5, 'No level sweep data', transform=ax.transAxes, ha='center')
        return
    levels = [r['level'] for r in level_rows]
    sdrs = [r['sdr'] for r in level_rows]
    colors = ['green' if r['pass'] else 'red' for r in level_rows]
    ax.bar(range(len(levels)), sdrs, color=colors, alpha=0.8, edgecolor='black', linewidth=0.5)
    ax.set_xticks(range(len(levels)))
    ax.set_xticklabels([f'{l:.0f}' for l in levels], fontsize=8)
    ax.axhline(SDR_THRESH, color='red', linestyle='--', linewidth=1, label=f'Threshold {SDR_THRESH} dB')
    ax.set_xlabel('Level (dBm0)', fontsize=9)
    ax.set_ylabel('SDR (dB)', fontsize=9)
    ax.set_title(f'{mode_label} — Level Sweep @ 1020 Hz', fontsize=10, fontweight='bold')
    ax.set_ylim(0, max(sdrs) * 1.15)
    ax.legend(fontsize=7)
    ax.grid(True, axis='y', alpha=0.3)

pdt = timezone(timedelta(hours=-7))
ts = datetime.now(pdt).strftime('%Y-%m-%d %H:%M PDT')

fig, axes = plt.subplots(2, 3, figsize=(20, 10))
for idx, (mname, mlabel) in enumerate(MODES):
    fname = f'p50_{mname}.txt'
    try:
        rows = load_p50(fname)
    except FileNotFoundError:
        axes[0, idx].text(0.5, 0.5, f'{fname} not found', transform=axes[0, idx].transAxes, ha='center')
        axes[1, idx].text(0.5, 0.5, f'{fname} not found', transform=axes[1, idx].transAxes, ha='center')
        continue
    plot_freq_sweep(axes[0, idx], rows, mlabel)
    plot_level_sweep(axes[1, idx], rows, mlabel)
    axes[1, idx].text(0.99, 0.01, ts, transform=axes[1, idx].transAxes, fontsize=6,
                      ha='right', va='bottom', color='gray')

fig.suptitle('OSR Signal Chain — ITU-T P.50 Sending Distortion (SDR)', fontsize=14, fontweight='bold', y=1.01)
fig.tight_layout()
fig.savefig('p50_all.png', dpi=150, bbox_inches='tight')
plt.close(fig)
print("Saved p50_all.png")

for mname, mlabel in MODES:
    fname = f'p50_{mname}.txt'
    try:
        rows = load_p50(fname)
    except FileNotFoundError:
        continue
    fig_s, (ax_f, ax_l) = plt.subplots(1, 2, figsize=(14, 5))
    plot_freq_sweep(ax_f, rows, mlabel)
    plot_level_sweep(ax_l, rows, mlabel)
    ax_l.text(0.99, 0.01, ts, transform=ax_l.transAxes, fontsize=6,
              ha='right', va='bottom', color='gray')
    fig_s.tight_layout()
    outfile = f'p50_{mname}.png'
    fig_s.savefig(outfile, dpi=150, bbox_inches='tight')
    plt.close(fig_s)
    print(f"Saved {outfile}")

print("P.50 plots complete.")
