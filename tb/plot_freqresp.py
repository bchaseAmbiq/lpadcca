#!/usr/bin/env python3
import csv
import math
import sys
import os
from datetime import datetime, timezone, timedelta

try:
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
except ImportError:
    print("ERROR: matplotlib not found. Install with: pip3 install matplotlib")
    sys.exit(1)

MODES = [
    ('nb',  {'label': 'NB (fs=8 kHz)',  'passband': (300, 3400),  'hpf_knee': 200, 'fs': 8000}),
    ('wb',  {'label': 'WB (fs=16 kHz)', 'passband': (150, 6700),  'hpf_knee': 150, 'fs': 16000}),
    ('swb', {'label': 'SWB (fs=32 kHz)','passband': (150, 12000), 'hpf_knee': 150, 'fs': 32000}),
]

MASKS = {
    'nb': {
        'hi_f': [200, 3400],
        'hi_db': [6, 6],
        'lo_f': [200, 3400],
        'lo_db': [-6, -6],
    },
    'wb': {
        'hi_f': [100, 200, 5000, 6400],
        'hi_db': [5, 5, 5, 5],
        'lo_f': [200, 5000, 6400],
        'lo_db': [-5, -5, -10],
    },
    'swb': {
        'hi_f': [200, 13000],
        'hi_db': [4, 4],
        'lo_f': [200, 5000, 13000],
        'lo_db': [-4, -4, -7],
    },
}

def plot_mode(ax, mname, info):
    fname = f'freqresp_{mname}.txt'
    try:
        with open(fname) as f:
            reader = csv.DictReader(f)
            rows = list(reader)
    except FileNotFoundError:
        ax.text(0.5, 0.5, f'{fname} not found', transform=ax.transAxes, ha='center')
        return

    freqs = [int(r['freq_hz']) for r in rows]
    amps  = [int(r['amplitude']) for r in rows]
    ovfs  = [int(r['overflows']) for r in rows]

    ref_amp = None
    for fr, am in zip(freqs, amps):
        if fr == 1000:
            ref_amp = am
            break
    if ref_amp is None or ref_amp == 0:
        ref_amp = max(amps) if max(amps) > 0 else 1

    gain_db = []
    for a in amps:
        if a > 0:
            gain_db.append(20.0 * math.log10(a / ref_amp))
        else:
            gain_db.append(-80.0)

    ax.plot(freqs, gain_db, 'b-o', linewidth=2, markersize=6, markerfacecolor='dodgerblue',
            markeredgecolor='navy', markeredgewidth=0.8, zorder=5)

    mask = MASKS[mname]
    ax.plot(mask['hi_f'], mask['hi_db'], 'r-', linewidth=2, label='Mask High', zorder=4)
    ax.plot(mask['lo_f'], mask['lo_db'], 'r--', linewidth=2, label='Mask Low', zorder=4)

    ax.fill_between(mask['hi_f'], mask['hi_db'], [20]*len(mask['hi_f']),
                     alpha=0.06, color='red')
    ax.fill_between(mask['lo_f'], mask['lo_db'], [-20]*len(mask['lo_f']),
                     alpha=0.06, color='red')

    ax.axvline(info['hpf_knee'], color='green', linestyle='--', linewidth=0.8, alpha=0.6,
               label=f'HPF {info["hpf_knee"]} Hz')
    ax.axvline(info['fs'] / 2, color='purple', linestyle=':', linewidth=0.8, alpha=0.6,
               label=f'Nyquist {info["fs"]//2} Hz')

    ax.axhline(0, color='black', linestyle='-', linewidth=0.6)

    for i in range(len(freqs)):
        yoff = 10 if gain_db[i] < -1 else -12
        lbl = f'{gain_db[i]:+.1f}'
        if ovfs[i] > 0:
            lbl += f'\nOVF={ovfs[i]}'
            ax.plot(freqs[i], gain_db[i], 'rx', markersize=10, markeredgewidth=2, zorder=6)
        ax.annotate(lbl, (freqs[i], gain_db[i]),
                    textcoords='offset points', xytext=(0, yoff),
                    fontsize=6, ha='center', color='black',
                    bbox=dict(boxstyle='round,pad=0.15', fc='white', ec='gray', alpha=0.7, lw=0.5))

    ax.set_xlabel('Frequency (Hz)', fontsize=9)
    ax.set_ylabel('Gain (dB re: 1 kHz)', fontsize=9)
    ax.set_title(f'{info["label"]}  (1 kHz ref = {ref_amp})', fontsize=10, fontweight='bold')
    ax.set_xscale('log')
    ax.set_xlim(freqs[0] * 0.7, max(freqs[-1], info['fs']//2) * 1.3)
    ax.set_ylim(-15, 10)
    ax.grid(True, which='major', alpha=0.3, linewidth=0.6)
    ax.grid(True, which='minor', alpha=0.1, linewidth=0.4)
    pdt = timezone(timedelta(hours=-7))
    ts = datetime.now(pdt).strftime('%Y-%m-%d %H:%M PDT')
    ax.text(0.99, 0.01, ts, transform=ax.transAxes, fontsize=6,
            ha='right', va='bottom', color='gray')

    mask = MASKS[mname]
    n_fail = 0
    for i in range(len(freqs)):
        f = freqs[i]
        g = gain_db[i]
        for j in range(len(mask['hi_f']) - 1):
            if mask['hi_f'][j] <= f <= mask['hi_f'][j+1]:
                t = (f - mask['hi_f'][j]) / (mask['hi_f'][j+1] - mask['hi_f'][j])
                lim = mask['hi_db'][j] + t * (mask['hi_db'][j+1] - mask['hi_db'][j])
                if g > lim:
                    n_fail += 1
                break
        for j in range(len(mask['lo_f']) - 1):
            if mask['lo_f'][j] <= f <= mask['lo_f'][j+1]:
                t = (f - mask['lo_f'][j]) / (mask['lo_f'][j+1] - mask['lo_f'][j])
                lim = mask['lo_db'][j] + t * (mask['lo_db'][j+1] - mask['lo_db'][j])
                if g < lim:
                    n_fail += 1
                break
    result = 'PASS' if n_fail == 0 else f'FAIL ({n_fail} pts)'
    ax.text(0.99, 0.97, result, transform=ax.transAxes, fontsize=10,
            ha='right', va='top', fontweight='bold',
            color='green' if n_fail == 0 else 'red',
            bbox=dict(boxstyle='round,pad=0.3', fc='white', ec='gray', alpha=0.9))

    ax.legend(fontsize=7, loc='lower left', ncol=2)

fig, axes = plt.subplots(1, 3, figsize=(20, 6))

for idx, (mname, info) in enumerate(MODES):
    plot_mode(axes[idx], mname, info)

fig.suptitle('OSR Signal Chain \u2014 Frequency Response (all modes)', fontsize=14, fontweight='bold', y=1.02)
fig.tight_layout()
fig.savefig('freqresp_all.png', dpi=150, bbox_inches='tight')
plt.close(fig)
print("Saved freqresp_all.png")

for mname, info in MODES:
    fig_s, ax_s = plt.subplots(figsize=(10, 6))
    plot_mode(ax_s, mname, info)
    fig_s.tight_layout()
    outfile = f'freqresp_{mname}.png'
    fig_s.savefig(outfile, dpi=150, bbox_inches='tight')
    plt.close(fig_s)
    print(f"Saved {outfile}")

print("Plots complete.")
