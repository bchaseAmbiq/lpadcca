#!/usr/bin/env python3
"""
gen_stim.py — Generate stimulus file for bit-exact RTL vs C-model comparison.

Output: one signed 12-bit integer per line (range −2048..2047).

Stimulus types match the RTL testbench (osr_tb.sv) and C driver exactly:
  sine:  q = int(sin(2*pi*freq*idx / 3072000) * amplitude), clamped
  dc:    constant value (clamped)
  ramp:  (idx % 4096) − 2048

Usage:
  python3 gen_stim.py --type sine --freq 1000 --amp 1449 --nsamples 500000 -o stim.txt
"""

import argparse
import math
import sys

FS_ADC = 3072000.0


def main():
    parser = argparse.ArgumentParser(description="Generate OSR stimulus file")
    parser.add_argument("--type", required=True, choices=["sine", "dc", "ramp"],
                        help="Stimulus type")
    parser.add_argument("--freq", type=float, default=1000.0,
                        help="Frequency in Hz (for sine)")
    parser.add_argument("--amp", type=int, default=1449,
                        help="Amplitude in ADC codes (peak)")
    parser.add_argument("--nsamples", type=int, default=500000,
                        help="Number of ADC-rate samples to generate")
    parser.add_argument("-o", "--output", default="stim.txt",
                        help="Output file (default: stim.txt)")
    args = parser.parse_args()

    with open(args.output, "w") as f:
        for idx in range(args.nsamples):
            if args.type == "sine":
                sv = math.sin(2.0 * math.pi * args.freq * idx / FS_ADC)
                q = int(sv * args.amp)
                if q > 2047:
                    q = 2047
                if q < -2048:
                    q = -2048
            elif args.type == "dc":
                q = args.amp
                if q > 2047:
                    q = 2047
                if q < -2048:
                    q = -2048
            elif args.type == "ramp":
                q = (idx & 0xFFF) - 2048
            else:
                print(f"Unknown type: {args.type}", file=sys.stderr)
                sys.exit(1)

            f.write(f"{q}\n")

    print(f"gen_stim: wrote {args.nsamples} samples to {args.output}",
          file=sys.stderr)


if __name__ == "__main__":
    main()
