#ifndef OSR_HAL_H
#define OSR_HAL_H

#include <stdint.h>

#ifndef OSR_BASE_ADDR
#define OSR_BASE_ADDR 0x40010000UL
#endif

#define OSR_CTRL_OFFSET        0x00U
#define OSR_DGA_FRAC_OFFSET    0x04U
#define OSR_FIFO_STATUS_OFFSET 0x08U
#define OSR_FIFO_DATA_OFFSET   0x0CU
#define OSR_INTEN_OFFSET       0x10U
#define OSR_INTSTAT_OFFSET     0x14U
#define OSR_INTCLR_OFFSET      0x18U
#define OSR_FIFO_THRESH_OFFSET 0x1CU
#define OSR_FIFO_FLUSH_OFFSET  0x20U
#define OSR_ID_OFFSET          0x24U

#define OSR_CTRL_MODE_MSK      0x3U
#define OSR_CTRL_MODE_POS      0U
#define OSR_CTRL_ENABLE_MSK    0x4U
#define OSR_CTRL_ENABLE_POS    2U
#define OSR_CTRL_DGA_SHIFT_MSK 0xF0U
#define OSR_CTRL_DGA_SHIFT_POS 4U

#define OSR_FIFO_STATUS_EMPTY_MSK 0x1U
#define OSR_FIFO_STATUS_HALF_MSK  0x2U
#define OSR_FIFO_STATUS_FULL_MSK  0x4U
#define OSR_FIFO_STATUS_OVF_MSK   0x8U
#define OSR_FIFO_STATUS_COUNT_MSK 0xF0U
#define OSR_FIFO_STATUS_COUNT_POS 4U

#define OSR_INT_EMPTY_MSK 0x1U
#define OSR_INT_HALF_MSK  0x2U
#define OSR_INT_FULL_MSK  0x4U
#define OSR_INT_OVF_MSK   0x8U

#define OSR_ID_EXPECTED 0xA05B0002UL

#define OSR_MODE_NB  0U
#define OSR_MODE_WB  1U
#define OSR_MODE_SWB 2U

static inline void osr_hal_write(uint32_t offset, uint32_t val)
{
    *(volatile uint32_t *)(OSR_BASE_ADDR + offset) = val;
}

static inline uint32_t osr_hal_read(uint32_t offset)
{
    return *(volatile uint32_t *)(OSR_BASE_ADDR + offset);
}

#endif
