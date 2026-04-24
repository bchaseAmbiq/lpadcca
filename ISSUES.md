# Issues

## Open
- [~] #1: NB gain — DGA g_fir compensation applied; ~2 dB residual at 1 kHz is filter design limitation (see `issues/001_nb_gain_compensation/`)
- [x] #2: THD+N analysis complete: NB -78 dB, WB -77 dB, SWB -74 dB (see `issues/002_thdn_analysis/`)
- [ ] #3: Create HTML register interface documentation (see `issues/003_register_html_docs/`) — BLOCKED: awaiting interface description
- [ ] #4: Create Genus synthesis script for power estimation (see `issues/004_genus_synthesis/`)
- [ ] #5: Hit <10 µW power target (see `issues/005_power_target/`) — BLOCKED on #4
- [ ] #6: ITU-T P.50 sending distortion test (see `issues/006_itu_p50_distortion/`)

- [ ] #7: Square-wave stress test (see `issues/007_squarewave_stress/`)
- [ ] #8: Clean mode switch test (see `issues/008_mode_switch/`)
- [x] #9: FIFO features and backpressure (see `issues/009_fifo_backpressure/`) — 16-deep FIFO + flags + interrupts implemented
- [ ] #10: Full-scale 0 dBFS filter chain test, bit-exact vs C model (see `issues/010_fullscale_test/`)

- [ ] #11: Hardcode HPF alpha in HW, keep DGA programmable (see `issues/011_hardcode_hpf_programmable_dga/`)

- [x] #12: APB bus interface for osr_top (see `issues/012_apb_interface/`) — `rtl/osr_apb.v` created, lints clean
- [x] #13: HAL and SW driver for M55 (see `issues/013_hal_sw_driver/`) — `sw/hal/osr_hal.h`, `sw/driver/osr_drv.{h,c}`
- [x] #14: HTML register documentation (see `issues/014_html_register_docs/`) — `docs/osr_regs.html` created, PDM style
- [x] #15: M55 bare-metal application (see `issues/015_m55_application/`) — `sw/app/main.c`, Makefile, linker.ld
- [ ] #16: FPGA test image, Stratix 10 (see `issues/016_fpga_test_image/`)
- [x] #17: Bit-exact RTL vs C model verification (see `issues/017_bit_exact_c_model/`) — `tb/bitexact/` infrastructure

## Closed
- [x] #11: HPF alpha hardcoded as mode LUT in osr_top, hpf_alpha_q15 port removed
