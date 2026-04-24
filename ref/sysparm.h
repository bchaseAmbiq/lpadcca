#ifndef SYSPARM_H
#define SYSPARM_H

#include <stdint.h>

/* Output mode selection */
typedef enum {
    MODE_NB  = 0,  /* 8 kHz */
    MODE_WB  = 1,  /* 16 kHz */
    MODE_SWB = 2   /* 32 kHz */
} AudioMode_t;

/*
 * Runtime configuration "downloaded" into the OSR engine.
 *
 * Conventions:
 * - FIR coefficients are Q1.15 (int16_t)
 * - HPF alpha is Q1.15
 * - DGA gain is represented as (2^dga_shift) * dga_frac_q16,
 *   where dga_frac_q16 is Q16 with 1.0 -> 65536 and frac in [1,2).
 */
typedef struct {
    AudioMode_t mode;
    int         fs_out;

    /* Decimation plan */
    int         num_hb_stages;              /* number of halfband stages after CIC */

    /* Halfband FIR stages (polyphase compute-on-kept-phase, zero-skip, symmetric) */
    const int16_t *hb_coef[5];              /* Q15 */
    int         hb_taps[5];
    int8_t      hb_shift[5];                /* post-accum right shift */

    /* Final audio LPF (symmetric) */
    const int16_t *lpf_coef;                /* Q15 */
    int         lpf_taps;
    int8_t      lpf_shift;                  /* post-accum right shift */

    /* HPF (DC blocker) */
    int16_t     hpf_alpha_q15;

    /* DGA */
    int8_t      dga_shift;
    uint32_t    dga_frac_q16;

    /* For logging/debug */
    float       atten_db;
    float       headroom_db;
    float       dga_frac_f;
} OSR_Config_t;

/* Initialize cfg for a given mode and input attenuation.
 * mode_select: 0=NB, 1=WB, 2=SWB
 * atten_db: attenuation applied when generating the raw (e.g. 0, -12, -15.5)
 * headroom_db: subtract from recovery when boosting to avoid clipping (0 for unity tests)
 */
void sysparm_init(OSR_Config_t *cfg, int mode_select, float atten_db, float headroom_db);

#endif /* SYSPARM_H */
