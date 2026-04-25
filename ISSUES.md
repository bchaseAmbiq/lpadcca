# Issues

## Open
- [~] #1: NB gain ~2 dB low — filter design limitation, see #18 (see `issues/001_nb_gain_compensation/`)
- [ ] #16: FPGA test image, Stratix 10 — not started (see `issues/016_fpga_test_image/`)
- [ ] #18: Passband flatness — NB/WB fail freq response, needs LPF coefficient redesign (see `issues/018_passband_flatness/`)

## Closed
- [x] #2: THD+N analysis — NB -78 dB, WB -77 dB, SWB -74 dB
- [x] #3: HTML register docs (original) — superseded by #14
- [x] #4: Genus synthesis — scripts (`syn/genus_syn.tcl`, `genus_syn_apb.tcl`, `genus_syn_vcd.tcl`) and results in `syn_results_*/`
- [x] #5: <10 µW power target — **achieved 6.2 µW** with clock gating + VCD annotation (see `syn_vcd_results_0424_1637/`)
- [x] #6: ITU-T P.50 distortion — all modes PASS, plot script + data in sim results
- [x] #7: Square-wave stress — all modes PASS, waveform capture + plots
- [x] #8: Mode switch — all 3 transitions PASS
- [x] #9: FIFO backpressure — 16-deep FIFO + empty/half/full/ovf flags + independent interrupts
- [x] #10: Full-scale 0 dBFS — all modes PASS, no overflow
- [x] #11: HPF alpha hardcoded as mode LUT in osr_top
- [x] #12: APB bus interface — `rtl/osr_apb.v` with FIFO, 10-register map
- [x] #13: HAL + SW driver — `sw/hal/osr_hal.h`, `sw/driver/osr_drv.{h,c}`
- [x] #14: HTML register docs — `docs/osr_regs.html` v2.0 (10 registers, PDM style)
- [x] #15: M55 bare-metal app — `sw/app/main.c`, Makefile, linker.ld
- [x] #17: Bit-exact verification — `tb/bitexact/` infrastructure (C driver, RTL dump, compare)
