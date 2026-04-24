# Issue #12: APB Bus Interface for osr_top

## Summary
Wrap `osr_top` with an AMBA APB slave interface so it can be memory-mapped in an M55 subsystem. Currently `osr_top` has bare wires for configuration (mode, dga_shift, dga_frac_q16) and streaming output (data_out, data_valid). These need to be mapped to APB-accessible registers.

## Requirements
- APB3 slave (PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA, PREADY, PSLVERR)
- Register map for: mode, dga_shift, dga_frac_q16, control/status, data readback
- Interrupt output for data_valid (or FIFO threshold)
- Must be compatible with Arm M55 subsystem APB interconnect

## Dependencies
- #3 (register HTML docs) defines the register map
- #9 (FIFO) — optional but desirable for data buffering

## Deliverables
- `rtl/osr_apb.v` — APB wrapper
- Register map definition (feeds into #3 and #14)
