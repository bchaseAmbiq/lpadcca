# Issue #13: HAL and SW Driver for OSR IP

## Summary
Create a hardware abstraction layer (HAL) and software driver for the OSR IP block, targeting the Arm Cortex-M55 platform. The driver should allow configuration of operating mode, DGA gain, and reading of decimated audio samples.

## Requirements
- HAL layer: register-level accessors (CMSIS-style base address + offset)
- Driver API: init, set_mode, set_gain, read_sample (polling), read_sample (interrupt-driven)
- Header file with register map `#define`s matching #12 APB register map
- Must be compatible with CMSIS and Arm Compiler 6 / GCC

## Deliverables
- `sw/hal/osr_hal.h` — register defines + inline accessors
- `sw/driver/osr_drv.h` / `osr_drv.c` — driver API
