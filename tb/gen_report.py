#!/usr/bin/env python3
"""Generate an HTML report embedding all PNG plots from the results directory.
Run from inside the results directory: python3 ../tb/gen_report.py
"""
import base64
import glob
import os
from datetime import datetime, timezone, timedelta

PLOT_ORDER = [
    ('thdn_all.png',      'THD+N Spectrum — All Modes'),
    ('thdn_nb.png',       'THD+N Spectrum — NB (8 kHz)'),
    ('thdn_wb.png',       'THD+N Spectrum — WB (16 kHz)'),
    ('thdn_swb.png',      'THD+N Spectrum — SWB (32 kHz)'),
    ('freqresp_all.png',  'Frequency Response — All Modes'),
    ('freqresp_nb.png',   'Frequency Response — NB (8 kHz)'),
    ('freqresp_wb.png',   'Frequency Response — WB (16 kHz)'),
    ('freqresp_swb.png',  'Frequency Response — SWB (32 kHz)'),
    ('p50_all.png',       'ITU-T P.50 SDR — All Modes'),
    ('p50_nb.png',        'ITU-T P.50 SDR — NB (8 kHz)'),
    ('p50_wb.png',        'ITU-T P.50 SDR — WB (16 kHz)'),
    ('p50_swb.png',       'ITU-T P.50 SDR — SWB (32 kHz)'),
    ('sqwave_all.png',    'Square-Wave Stress — All Modes'),
    ('sqwave_nb.png',     'Square-Wave Stress — NB (8 kHz)'),
    ('sqwave_wb.png',     'Square-Wave Stress — WB (16 kHz)'),
    ('sqwave_swb.png',    'Square-Wave Stress — SWB (32 kHz)'),
]

pdt = timezone(timedelta(hours=-7))
ts = datetime.now(pdt).strftime('%Y-%m-%d %H:%M:%S PDT')

images = []
for fname, title in PLOT_ORDER:
    if os.path.exists(fname):
        with open(fname, 'rb') as f:
            b64 = base64.b64encode(f.read()).decode('ascii')
        images.append((fname, title, b64))

extras = sorted(glob.glob('*.png'))
seen = {fname for fname, _, _ in images}
for fname in extras:
    if fname not in seen:
        with open(fname, 'rb') as f:
            b64 = base64.b64encode(f.read()).decode('ascii')
        images.append((fname, fname, b64))

nav = []
sections = []
for i, (fname, title, b64) in enumerate(images):
    aid = f'img{i}'
    nav.append(f'<a href="#{aid}">{title}</a>')
    sections.append(
        f'<div class="plot-section" id="{aid}">\n'
        f'  <h2>{title}</h2>\n'
        f'  <p class="meta">{fname}</p>\n'
        f'  <img src="data:image/png;base64,{b64}" alt="{title}">\n'
        f'</div>'
    )

html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>OSR Simulation Report — {ts}</title>
<style>
  body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI",
         Helvetica, Arial, sans-serif;
         margin: 0; padding: 0; background: #f5f5f5; color: #333; }}
  header {{ background: #1a1a2e; color: #eee; padding: 20px 30px;
           position: sticky; top: 0; z-index: 10;
           box-shadow: 0 2px 8px rgba(0,0,0,0.3); }}
  header h1 {{ margin: 0; font-size: 1.4em; }}
  header .ts {{ font-size: 0.8em; color: #aaa; margin-top: 4px; }}
  nav {{ background: #16213e; padding: 8px 30px;
        position: sticky; top: 72px; z-index: 9;
        overflow-x: auto; white-space: nowrap;
        box-shadow: 0 1px 4px rgba(0,0,0,0.2); }}
  nav a {{ color: #8ec5fc; text-decoration: none; margin-right: 18px;
          font-size: 0.85em; }}
  nav a:hover {{ text-decoration: underline; }}
  .plot-section {{ background: #fff; margin: 20px 30px;
                  padding: 20px; border-radius: 6px;
                  box-shadow: 0 1px 3px rgba(0,0,0,0.1); }}
  .plot-section h2 {{ margin-top: 0; font-size: 1.15em; color: #1a1a2e; }}
  .plot-section .meta {{ font-size: 0.75em; color: #999; margin: -8px 0 12px; }}
  .plot-section img {{ max-width: 100%; height: auto;
                      border: 1px solid #ddd; border-radius: 4px; }}
  footer {{ text-align: center; padding: 20px; font-size: 0.75em;
           color: #999; }}
</style>
</head>
<body>
<header>
  <h1>OSR Audio Decimation — Simulation Report</h1>
  <div class="ts">Generated {ts} &nbsp;|&nbsp; {len(images)} plots</div>
</header>
<nav>
  {'&nbsp;|&nbsp;'.join(nav)}
</nav>
{''.join(sections)}
<footer>
  OSR Signal Chain &mdash; report generated {ts}
</footer>
</body>
</html>
"""

outfile = 'sim_report.html'
with open(outfile, 'w') as f:
    f.write(html)
print(f"Generated {outfile} with {len(images)} embedded plots ({ts})")
