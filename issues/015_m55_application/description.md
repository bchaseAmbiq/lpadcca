# Issue #15: M55 Bare-Metal Application

## Summary
Create a small bare-metal Cortex-M55 application that exercises the OSR IP via the APB driver. This serves as a bring-up / smoke test application.

## Requirements
- Startup code + linker script (or use existing BSP)
- Initialize OSR in each mode (NB/WB/SWB)
- Configure DGA gain
- Capture N samples via polling and/or interrupt
- Print results via UART/semihosting
- Build with Arm Compiler 6 or arm-none-eabi-gcc

## Dependencies
- #12 (APB interface)
- #13 (HAL / driver)

## Deliverables
- `sw/app/main.c`
- `sw/app/Makefile` or build script
