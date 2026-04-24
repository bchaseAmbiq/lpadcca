#ifndef OSR_DRV_H
#define OSR_DRV_H

#include <stdint.h>
#include <stdbool.h>

typedef enum {
    OSR_OK       = 0,
    OSR_ERR_ID   = -1,
    OSR_ERR_TMO  = -2,
    OSR_ERR_EMPTY= -3
} osr_status_t;

typedef struct {
    uint8_t  mode;
    int8_t   dga_shift;
    uint32_t dga_frac_q16;
    uint32_t int_enable_mask;
    uint8_t  fifo_thresh;
} osr_config_t;

osr_status_t osr_init(const osr_config_t *cfg);
void         osr_enable(void);
void         osr_disable(void);
void         osr_set_mode(uint8_t mode);
void         osr_set_gain(int8_t shift, uint32_t frac_q16);

osr_status_t osr_fifo_read(int16_t *sample);
osr_status_t osr_fifo_read_block(int16_t *buf, uint32_t count,
                                  uint32_t timeout_us);
uint32_t     osr_fifo_count(void);
bool         osr_fifo_empty(void);
bool         osr_fifo_full(void);
bool         osr_fifo_half(void);
bool         osr_fifo_overflow(void);
void         osr_fifo_flush(void);
void         osr_fifo_set_thresh(uint8_t thresh);

void         osr_int_enable(uint32_t mask);
void         osr_int_disable(uint32_t mask);
uint32_t     osr_int_status(void);
void         osr_int_clear(uint32_t mask);

void         osr_clear_overflow(void);
uint32_t     osr_read_id(void);

#endif
