#ifndef LPADC_OSR_H
#define LPADC_OSR_H

/*
 * OSR header (
 *
 * - OSR engine state (fixed-point friendly)
 * - LP_OSR_step() API used by the CLI/test program
 *
 * All programmable/runtime values live in sysparm.h (OSR_Config_t).
 */

#include <stdint.h>
#include "sysparm.h"

#define OSR_MAX_HB_STAGES 5

/* Power-of-2 circular buffers (must be > maximum taps used) */
#define OSR_BUF_SIZE_HB   32  /* > 19 taps */
#define OSR_BUF_SIZE_LPF  32  /* > 21 taps */

/*
 * OSR engine persistent state.
 *
 * Notes:
 * - Internal representation is fixed-point (int32) for HW fidelity.
 * - LP_OSR_step takes/returns float for convenience in the C test harness.
 */
typedef struct {
    /* CIC state (N=3) */
    int32_t i[3];
    int32_t c[3];
    int     cic_phase;

    /* Halfband chain state */
    uint8_t hb_phase[OSR_MAX_HB_STAGES];
    uint8_t hb_head[OSR_MAX_HB_STAGES];
    int32_t hb_buf[OSR_MAX_HB_STAGES][OSR_BUF_SIZE_HB];

    /* Final LPF state */
    uint8_t lpf_head;
    int32_t lpf_buf[OSR_BUF_SIZE_LPF];

    /* HPF state (DC blocker) */
    int32_t hpf_x1;
    int32_t hpf_y1;
} OSR_Context_t;

/*
 * Streaming step.
 *
 * adc_in: normalized float input in [-1,1) corresponding to Q1.11 raw codes.
 * out:    normalized float output in [-1,1) when ready=1.
 */
void LP_OSR_step(OSR_Context_t *ctx, OSR_Config_t *cfg, float adc_in, float *out, int *ready);

#endif /* LPADC_OSR_H */
