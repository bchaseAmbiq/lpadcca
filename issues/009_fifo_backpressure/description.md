# Issue #9: Output FIFO with flags and independent interrupts

## Description
Add a 16-deep, 16-bit-wide synchronous FIFO between the OSR core output
(CDC'd into PCLK domain) and the APB DATA read port. Three flag-based
interrupts (empty, half-full, full/overflow) must be independently
readable, clearable, and enable/disable-able via APB registers, and
drive the `irq` output to the M55 NVIC.

## FIFO Specification
- Depth: 16 entries
- Width: 16 bits (signed PCM samples)
- Clock domain: PCLK (write side receives CDC'd new_sample_pclk pulse)
- Write: auto-push on each new_sample_pclk; if full, set overflow flag, drop sample
- Read: APB read of FIFO_DATA register pops one entry
- Flush: write 1 to FIFO_FLUSH register clears FIFO and all flags

## Flags (active high, directly readable in FIFO_STATUS)
- EMPTY: FIFO count == 0 (asserted after reset/flush)
- HALF:  FIFO count >= FIFO_THRESH (programmable, default 8)
- FULL:  FIFO count == 16
- OVF:   sticky — set when a write is attempted while full; W1C

## Interrupt Architecture
Each flag has three independent register bits:

| Register     | Bits        | Access | Description |
|-------------|-------------|--------|-------------|
| INTEN       | [3:0]       | RW     | Per-flag interrupt enable |
| INTSTAT     | [3:0]       | RO     | Raw interrupt status (live flags) |
| INTCLR      | [3:0]       | W1C    | Write 1 to clear sticky OVF; others auto-clear |

Bit mapping: [0]=EMPTY, [1]=HALF, [2]=FULL, [3]=OVF

irq = |(INTSTAT & INTEN)

## Updated Register Map (osr_apb.v)
| Offset | Name         | Access | Description |
|--------|-------------|--------|-------------|
| 0x00   | CTRL        | RW     | mode, enable, dga_shift |
| 0x04   | DGA_FRAC    | RW     | dga_frac_q16 |
| 0x08   | FIFO_STATUS | RO/W1C | [0]empty [1]half [2]full [3]ovf [7:4]count |
| 0x0C   | FIFO_DATA   | RO     | pop & return top entry (sign-extended 32b) |
| 0x10   | INTEN       | RW     | [3:0] per-flag interrupt enable |
| 0x14   | INTSTAT     | RO     | [3:0] raw flag status |
| 0x18   | INTCLR      | W1C    | [3:0] clear sticky flags (OVF) |
| 0x1C   | FIFO_THRESH | RW     | [3:0] half-full threshold (default 8) |
| 0x20   | FIFO_FLUSH  | WO     | [0] write 1 to flush FIFO |
| 0x24   | ID          | RO     | 0xA05B_0002 |

## Deliverables
- `rtl/osr_fifo.v` — 16×16 sync FIFO with flags
- Updated `rtl/osr_apb.v` — FIFO integration + new register map
- Updated `sw/hal/osr_hal.h` — new register defines
- Updated `sw/driver/osr_drv.{h,c}` — FIFO read API
- Updated `docs/osr_regs.html` — new register docs

## Status
In progress
