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
    ('nb',  'NB (8 kHz)',  8000),
    ('wb',  'WB (16 kHz)', 16000),
    ('swb', 'SWB (32 kHz)', 32000),
]

MAX_DISPLAY_CYCLES = 6

def load_sqwave(fname):
    data = {}
    with open(fname) as f:
        reader = csv.DictReader(f)
        for r in reader:
            freq = int(r['freq_hz'])
            if freq not in data:
                data[freq] = []
            data[freq].append(int(r['value']))
    return data

def plot_sqwave_ax(ax, samples_all, freq, fs, mlabel, ts):
    period_samps = max(int(round(fs / freq)), 1)
    n_show = min(len(samples_all), period_samps * MAX_DISPLAY_CYCLES)
    samples = np.array(samples_all[:n_show])
    t_ms = np.arange(len(samples)) / fs * 1000.0

    ax.plot(t_ms, samples, 'b-o', linewidth=1.2, markersize=2.5,
            markerfacecolor='dodgerblue', markeredgewidth=0)
    ax.set_xlabel('Time (ms)', fontsize=8)
    ax.set_ylabel('Amplitude', fontsize=8)
    ax.set_title(f'{mlabel} — {freq} Hz square-wave response',
                 fontsize=9, fontweight='bold')
    ymax = max(abs(samples.min()), abs(samples.max()))
    ax.set_ylim(-ymax * 1.25, ymax * 1.25)
    ax.grid(True, alpha=0.3)
    ax.axhline(0, color='gray', linewidth=0.5)

    for c in range(MAX_DISPLAY_CYCLES + 1):
        edge_t = c / freq * 1000.0
        if edge_t <= t_ms[-1]:
            ax.axvline(edge_t, color='red', linewidth=0.4, alpha=0.4,
                       linestyle=':')

    pk_all = max(abs(np.min(samples_all)), abs(np.max(samples_all)))
    ax.text(0.02, 0.95,
            f'pk={pk_all}  period={period_samps} samp\n'
            f'showing {len(samples)}/{len(samples_all)} samples\n'
            f'Gibbs ringing expected on edges',
            transform=ax.transAxes, fontsize=6.5, va='top',
            family='monospace',
            bbox=dict(boxstyle='round,pad=0.3', facecolor='wheat',
                      alpha=0.6))
    ax.text(0.99, 0.01, ts, transform=ax.transAxes, fontsize=6,
            ha='right', va='bottom', color='gray')

pdt = timezone(timedelta(hours=-7))
ts = datetime.now(pdt).strftime('%Y-%m-%d %H:%M PDT')

fig, axes = plt.subplots(3, 3, figsize=(20, 14))

for col, (mname, mlabel, fs) in enumerate(MODES):
    fname = f'sqwave_{mname}.txt'
    try:
        data = load_sqwave(fname)
    except FileNotFoundError:
        for row in range(3):
            axes[row, col].text(0.5, 0.5, f'{fname} not found',
                                transform=axes[row, col].transAxes,
                                ha='center')
        continue

    freqs = sorted(data.keys())
    for row, freq in enumerate(freqs[:3]):
        plot_sqwave_ax(axes[row, col], data[freq], freq, fs, mlabel, ts)

fig.suptitle('OSR Signal Chain — Square-Wave Stress Test '
             '(full-scale w/ headroom, Gibbs ringing expected)',
             fontsize=14, fontweight='bold', y=1.01)
fig.tight_layout()
fig.savefig('sqwave_all.png', dpi=150, bbox_inches='tight')
plt.close(fig)
print("Saved sqwave_all.png")

for mname, mlabel, fs in MODES:
    fname = f'sqwave_{mname}.txt'
    try:
        data = load_sqwave(fname)
    except FileNotFoundError:
        continue
    freqs = sorted(data.keys())
    nf = min(len(freqs), 3)
    fig_s, axs = plt.subplots(1, nf, figsize=(6 * nf, 4.5))
    if nf == 1:
        axs = [axs]
    for i, freq in enumerate(freqs[:nf]):
        plot_sqwave_ax(axs[i], data[freq], freq, fs, mlabel, ts)
    fig_s.suptitle(f'{mlabel} Square-Wave Response (Gibbs ringing expected)',
                   fontsize=11, fontweight='bold')
    fig_s.tight_layout()
    outfile = f'sqwave_{mname}.png'
    fig_s.savefig(outfile, dpi=150, bbox_inches='tight')
    plt.close(fig_s)
    print(f"Saved {outfile}")

print("Square-wave plots complete.")
