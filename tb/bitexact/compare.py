#!/usr/bin/env python3
"""
compare.py — Compare C-model and RTL output vectors sample-by-sample.

Reads two files (one integer per line), skips initial transient samples,
and reports mismatches.

Usage:
  python3 compare.py cmodel_out.txt rtl_out.txt [--skip 512]

Exit code:
  0 = bit-exact match (after skip)
  1 = mismatch or error
"""

import argparse
import sys


def main():
    parser = argparse.ArgumentParser(description="Compare C-model vs RTL output")
    parser.add_argument("cmodel_file", help="C model output file")
    parser.add_argument("rtl_file", help="RTL output file")
    parser.add_argument("--skip", type=int, default=512,
                        help="Number of initial output samples to skip (default: 512)")
    args = parser.parse_args()

    try:
        with open(args.cmodel_file) as f:
            cmodel = [int(line.strip()) for line in f if line.strip()]
    except Exception as e:
        print(f"ERROR: reading {args.cmodel_file}: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        with open(args.rtl_file) as f:
            rtl = [int(line.strip()) for line in f if line.strip()]
    except Exception as e:
        print(f"ERROR: reading {args.rtl_file}: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"C-model samples: {len(cmodel)}")
    print(f"RTL samples:     {len(rtl)}")
    print(f"Skip first:      {args.skip}")

    # Use shorter length for comparison
    n_cmodel = len(cmodel) - args.skip
    n_rtl = len(rtl) - args.skip

    if n_cmodel <= 0:
        print(f"ERROR: C-model has {len(cmodel)} samples, need > {args.skip}")
        sys.exit(1)
    if n_rtl <= 0:
        print(f"ERROR: RTL has {len(rtl)} samples, need > {args.skip}")
        sys.exit(1)

    n_compare = min(n_cmodel, n_rtl)
    print(f"Comparing:       {n_compare} samples (after skip)")

    if n_cmodel != n_rtl:
        print(f"WARNING: sample count differs after skip: "
              f"cmodel={n_cmodel}, rtl={n_rtl}")

    mismatches = 0
    max_abs_err = 0
    first_mismatches = []

    for i in range(n_compare):
        c_val = cmodel[args.skip + i]
        r_val = rtl[args.skip + i]
        err = abs(c_val - r_val)
        if err > max_abs_err:
            max_abs_err = err
        if c_val != r_val:
            mismatches += 1
            if len(first_mismatches) < 10:
                first_mismatches.append(
                    (args.skip + i, c_val, r_val, c_val - r_val))

    print(f"Mismatches:      {mismatches}")
    print(f"Max abs error:   {max_abs_err}")

    if first_mismatches:
        print("\nFirst mismatches (up to 10):")
        print(f"  {'Index':>8s}  {'C-model':>8s}  {'RTL':>8s}  {'Diff':>8s}")
        for idx, cv, rv, diff in first_mismatches:
            print(f"  {idx:8d}  {cv:8d}  {rv:8d}  {diff:8d}")

    if mismatches == 0 and n_cmodel == n_rtl:
        print("\nRESULT: PASS (bit-exact match)")
        sys.exit(0)
    elif mismatches == 0 and n_cmodel != n_rtl:
        print(f"\nRESULT: WARN (values match but sample counts differ)")
        sys.exit(1)
    else:
        print(f"\nRESULT: FAIL ({mismatches} mismatches)")
        sys.exit(1)


if __name__ == "__main__":
    main()
