#include "osr_drv.h"
#include "../hal/osr_hal.h"

osr_status_t osr_init(const osr_config_t *cfg)
{
    if (osr_hal_read(OSR_ID_OFFSET) != OSR_ID_EXPECTED)
        return OSR_ERR_ID;

    osr_disable();

    uint32_t ctrl = ((uint32_t)(cfg->mode & 0x3U) << OSR_CTRL_MODE_POS)
                   | (((uint32_t)cfg->dga_shift & 0xFU) << OSR_CTRL_DGA_SHIFT_POS);
    osr_hal_write(OSR_CTRL_OFFSET, ctrl);
    osr_hal_write(OSR_DGA_FRAC_OFFSET, cfg->dga_frac_q16 & 0x1FFFFU);

    osr_fifo_flush();
    osr_clear_overflow();
    osr_fifo_set_thresh(cfg->fifo_thresh ? cfg->fifo_thresh : 8);
    osr_int_clear(0xFU);
    osr_hal_write(OSR_INTEN_OFFSET, cfg->int_enable_mask & 0xFU);

    return OSR_OK;
}

void osr_enable(void)
{
    uint32_t ctrl = osr_hal_read(OSR_CTRL_OFFSET);
    ctrl |= OSR_CTRL_ENABLE_MSK;
    osr_hal_write(OSR_CTRL_OFFSET, ctrl);
}

void osr_disable(void)
{
    uint32_t ctrl = osr_hal_read(OSR_CTRL_OFFSET);
    ctrl &= ~OSR_CTRL_ENABLE_MSK;
    osr_hal_write(OSR_CTRL_OFFSET, ctrl);
}

void osr_set_mode(uint8_t mode)
{
    uint32_t ctrl = osr_hal_read(OSR_CTRL_OFFSET);
    ctrl = (ctrl & ~OSR_CTRL_MODE_MSK)
         | ((uint32_t)(mode & 0x3U) << OSR_CTRL_MODE_POS);
    osr_hal_write(OSR_CTRL_OFFSET, ctrl);
}

void osr_set_gain(int8_t shift, uint32_t frac_q16)
{
    uint32_t ctrl = osr_hal_read(OSR_CTRL_OFFSET);
    ctrl = (ctrl & ~OSR_CTRL_DGA_SHIFT_MSK)
         | (((uint32_t)shift & 0xFU) << OSR_CTRL_DGA_SHIFT_POS);
    osr_hal_write(OSR_CTRL_OFFSET, ctrl);
    osr_hal_write(OSR_DGA_FRAC_OFFSET, frac_q16 & 0x1FFFFU);
}

osr_status_t osr_fifo_read(int16_t *sample)
{
    if (osr_hal_read(OSR_FIFO_STATUS_OFFSET) & OSR_FIFO_STATUS_EMPTY_MSK)
        return OSR_ERR_EMPTY;
    uint32_t raw = osr_hal_read(OSR_FIFO_DATA_OFFSET);
    *sample = (int16_t)(raw & 0xFFFFU);
    return OSR_OK;
}

osr_status_t osr_fifo_read_block(int16_t *buf, uint32_t count,
                                  uint32_t timeout_us)
{
    for (uint32_t i = 0; i < count; i++) {
        volatile uint32_t wait = 0;
        while (osr_hal_read(OSR_FIFO_STATUS_OFFSET) & OSR_FIFO_STATUS_EMPTY_MSK) {
            if (++wait >= timeout_us)
                return OSR_ERR_TMO;
        }
        uint32_t raw = osr_hal_read(OSR_FIFO_DATA_OFFSET);
        buf[i] = (int16_t)(raw & 0xFFFFU);
    }
    return OSR_OK;
}

uint32_t osr_fifo_count(void)
{
    return (osr_hal_read(OSR_FIFO_STATUS_OFFSET)
            & OSR_FIFO_STATUS_COUNT_MSK) >> OSR_FIFO_STATUS_COUNT_POS;
}

bool osr_fifo_empty(void)
{
    return (osr_hal_read(OSR_FIFO_STATUS_OFFSET)
            & OSR_FIFO_STATUS_EMPTY_MSK) != 0;
}

bool osr_fifo_full(void)
{
    return (osr_hal_read(OSR_FIFO_STATUS_OFFSET)
            & OSR_FIFO_STATUS_FULL_MSK) != 0;
}

bool osr_fifo_half(void)
{
    return (osr_hal_read(OSR_FIFO_STATUS_OFFSET)
            & OSR_FIFO_STATUS_HALF_MSK) != 0;
}

bool osr_fifo_overflow(void)
{
    return (osr_hal_read(OSR_FIFO_STATUS_OFFSET)
            & OSR_FIFO_STATUS_OVF_MSK) != 0;
}

void osr_fifo_flush(void)
{
    osr_hal_write(OSR_FIFO_FLUSH_OFFSET, 1U);
}

void osr_fifo_set_thresh(uint8_t thresh)
{
    osr_hal_write(OSR_FIFO_THRESH_OFFSET, (uint32_t)(thresh & 0xFU));
}

void osr_int_enable(uint32_t mask)
{
    uint32_t cur = osr_hal_read(OSR_INTEN_OFFSET);
    osr_hal_write(OSR_INTEN_OFFSET, cur | (mask & 0xFU));
}

void osr_int_disable(uint32_t mask)
{
    uint32_t cur = osr_hal_read(OSR_INTEN_OFFSET);
    osr_hal_write(OSR_INTEN_OFFSET, cur & ~(mask & 0xFU));
}

uint32_t osr_int_status(void)
{
    return osr_hal_read(OSR_INTSTAT_OFFSET) & 0xFU;
}

void osr_int_clear(uint32_t mask)
{
    osr_hal_write(OSR_INTCLR_OFFSET, mask & 0xFU);
}

void osr_clear_overflow(void)
{
    osr_hal_write(OSR_INTCLR_OFFSET, OSR_INT_OVF_MSK);
}

uint32_t osr_read_id(void)
{
    return osr_hal_read(OSR_ID_OFFSET);
}
