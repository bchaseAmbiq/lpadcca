# Issue #16: FPGA Test Image (Stratix 10)

## Summary
Create an FPGA top-level design targeting Intel Stratix 10 that instantiates `osr_top` (or `osr_apb`) along with test structures for board-level validation.

## Requirements
- Target: Intel Stratix 10 development board
- Test structures:
  - **Canned data ROM**: preloaded sine/multi-tone stimulus played into `adc_data`/`eoc` inputs
  - **Capture RAM**: stores N output samples for readback via JTAG/Avalon
  - **Mode/gain control**: settable via JTAG or on-board switches/buttons
  - **Expected-output comparator**: optional gold reference for pass/fail LED
  - **Clock generation**: PLL for ADC clock domain
- JTAG System Console or Nios-based readback for captured data
- Quartus project files

## Deliverables
- `fpga/rtl/fpga_top.v` — top-level wrapper with test structures
- `fpga/rtl/canned_data_rom.v` — stimulus ROM
- `fpga/rtl/capture_ram.v` — output capture
- `fpga/quartus/` — Quartus project, SDC constraints, pin assignments
- `fpga/scripts/` — build scripts
- `fpga/README.md` — board setup and usage instructions
