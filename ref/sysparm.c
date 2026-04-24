#include <math.h>
#include <string.h>

#include "osr_decimators.h"   
#include "sysparm.h"

/* -------------------------------------------------------------------------
 * compatibility
 *
 * ------------------------------------------------------------------------- */

#ifndef HB1_TAPS
#  ifdef HB1_COEF_TAPS
#    define HB1_TAPS HB1_COEF_TAPS
#  endif
#endif
#ifndef HB2_TAPS
#  ifdef HB2_COEF_TAPS
#    define HB2_TAPS HB2_COEF_TAPS
#  endif
#endif

#ifndef LP8_TAPS
#  ifdef LP8_COEF_TAPS
#    define LP8_TAPS LP8_COEF_TAPS
#  endif
#endif
#ifndef LP16_TAPS
#  ifdef LP16_COEF_TAPS
#    define LP16_TAPS LP16_COEF_TAPS
#  endif
#endif
#ifndef LP32_TAPS
#  ifdef LP32_COEF_TAPS
#    define LP32_TAPS LP32_COEF_TAPS
#  endif
#endif

/* Q15 cached taps (quantized once at init) */
static int16_t HB1_Q15[HB1_TAPS];
static int16_t HB2_Q15[HB2_TAPS];
static int16_t LP8_Q15[LP8_TAPS];
static int16_t LP16_Q15[LP16_TAPS];
static int16_t LP32_Q15[LP32_TAPS];

static int g_q15_inited = 0;

static inline int16_t f_to_q15(float x)
{
    /* clamp to representable Q15 */
    if (x > 0.999969f) x = 0.999969f;
    if (x < -1.0f)     x = -1.0f;
    int v = (int)lrintf(x * 32768.0f);
    if (v > 32767)  v = 32767;
    if (v < -32768) v = -32768;
    return (int16_t)v;
}

static void quantize_q15(int16_t *dst, const float *src, int taps)
{
    for (int i = 0; i < taps; ++i) dst[i] = f_to_q15(src[i]);
}

static float coef_sum_f32(const float *h, int taps)
{
    double s = 0.0;
    for (int i = 0; i < taps; ++i) s += h[i];
    return (float)s;
}

/* Represent gain as (2^shift) * frac, with frac in [1,2). */
static void split_gain_to_q16(float linear_gain, int8_t *shift_out, uint32_t *frac_q16_out, float *frac_f_out)
{
    int shift = 0;
    float frac = linear_gain;

    if (!(frac > 0.0f)) {
        *shift_out = 0;
        *frac_q16_out = 0;
        if (frac_f_out) *frac_f_out = 0.0f;
        return;
    }

    while (frac >= 2.0f) { frac *= 0.5f; shift++; }
    while (frac <  1.0f) { frac *= 2.0f; shift--; }

    /* Q16 with 1.0 -> 65536. frac is in [1,2), so range [65536,131072). */
    uint32_t q16 = (uint32_t)lrintf(frac * 65536.0f);
    if (q16 < 65536u)  q16 = 65536u;
    if (q16 > 131071u) q16 = 131071u;

    *shift_out = (int8_t)shift;
    *frac_q16_out = q16;
    if (frac_f_out) *frac_f_out = frac;
}

void sysparm_init(OSR_Config_t *cfg, int mode_select, float atten_db, float headroom_db)
{
    memset(cfg, 0, sizeof(*cfg));

    /* clamp mode */
    if (mode_select < 0) mode_select = 0;
    if (mode_select > 2) mode_select = 2;

    cfg->mode = (AudioMode_t)mode_select;
    cfg->atten_db = atten_db;
    cfg->headroom_db = headroom_db;

    /* One-time coefficient quantization */
    if (!g_q15_inited) {
        quantize_q15(HB1_Q15, HB1_COEF, HB1_TAPS);
        quantize_q15(HB2_Q15, HB2_COEF, HB2_TAPS);
        quantize_q15(LP8_Q15,  LP8_COEF,  LP8_TAPS);
        quantize_q15(LP16_Q15, LP16_COEF, LP16_TAPS);
        quantize_q15(LP32_Q15, LP32_COEF, LP32_TAPS);
        g_q15_inited = 1;
    }

    /* Halfband plan: HB1 then HB2 reused */
    cfg->hb_coef[0] = HB1_Q15;
    cfg->hb_taps[0] = HB1_TAPS;
    cfg->hb_shift[0] = 0;
    for (int i = 1; i < 5; ++i) {
        cfg->hb_coef[i] = HB2_Q15;
        cfg->hb_taps[i] = HB2_TAPS;
        cfg->hb_shift[i] = 0;
    }

    /* Mode-specific staging: CIC gives 256 kHz; each HB stage halves */
    switch (cfg->mode) {
        case MODE_NB:
            cfg->fs_out = 8000;
            cfg->num_hb_stages = 5; /* 256k -> 8k */
            cfg->lpf_coef = LP8_Q15;
            cfg->lpf_taps = LP8_TAPS;
            cfg->lpf_shift = 0;
            cfg->hpf_alpha_q15 = f_to_q15(0.8546f);
            break;
        case MODE_WB:
            cfg->fs_out = 16000;
            cfg->num_hb_stages = 4; /* 256k -> 16k */
            cfg->lpf_coef = LP16_Q15;
            cfg->lpf_taps = LP16_TAPS;
            cfg->lpf_shift = 0;
            cfg->hpf_alpha_q15 = f_to_q15(0.9428f);
            break;
        case MODE_SWB:
        default:
            cfg->fs_out = 32000;
            cfg->num_hb_stages = 3; /* 256k -> 32k */
            cfg->lpf_coef = LP32_Q15;
            cfg->lpf_taps = LP32_TAPS;
            cfg->lpf_shift = 0;
            cfg->hpf_alpha_q15 = f_to_q15(0.9710f);
            break;
    }

    /* ---------------------------------------------------------------------
     * DGA recovery
     *
     * --------------------------------------------------------------------- */

    float recovery_db = -atten_db;
    if (headroom_db > 0.0f) {
        recovery_db -= headroom_db;
        if (recovery_db < 0.0f) recovery_db = 0.0f;
    }

    /* Compute DC gain of the FIR chain using the FLOAT coefficients */
    float g_fir = 1.0f;
    {
        /* HB1 always used as first stage */
        float g1 = coef_sum_f32(HB1_COEF, HB1_TAPS);
        if (g1 != 0.0f) g_fir *= g1;

        /* Remaining HB stages reuse HB2 */
        for (int st = 1; st < cfg->num_hb_stages; ++st) {
            float g2 = coef_sum_f32(HB2_COEF, HB2_TAPS);
            if (g2 != 0.0f) g_fir *= g2;
        }

        /* LPF depends on mode */
        if (cfg->mode == MODE_NB) {
            float gl = coef_sum_f32(LP8_COEF, LP8_TAPS);
            if (gl != 0.0f) g_fir *= gl;
        } else if (cfg->mode == MODE_WB) {
            float gl = coef_sum_f32(LP16_COEF, LP16_TAPS);
            if (gl != 0.0f) g_fir *= gl;
        } else {
            float gl = coef_sum_f32(LP32_COEF, LP32_TAPS);
            if (gl != 0.0f) g_fir *= gl;
        }
    }
    if (g_fir == 0.0f) g_fir = 1.0f;

    /*
     * Unity-gain calibration:
     * - pow(10, recovery_db/20) undoes the input attenuation used during RAW generation.
     * - dividing by g_fir removes the FIR chain DC-gain error (fixes ~+1.5 dB boost).
     *
     */
    /* Divide by 4: CIC output is Q17 (4x larger than Q15); DGA restores Q15. */
    float linear_gain = (powf(10.0f, recovery_db / 20.0f)) / (g_fir * 4.0f);

    split_gain_to_q16(linear_gain, &cfg->dga_shift, &cfg->dga_frac_q16, &cfg->dga_frac_f);
}
