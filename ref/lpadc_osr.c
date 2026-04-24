#include <math.h>
#include <string.h>

#include "lpadc_osr.h"
#include "osr_decimators.h" /* OSR_R_CIC / OSR_N_CIC */

/* Single Q15 multiply with round-to-nearest (used for scalar feedback paths) */
#define MUL_Q15(a, b) (int32_t)((((int64_t)(a) * (int64_t)(b)) + 16384) >> 15)

/* Q16 gain multiply: (x * g)>>16, keeps x in Qn if x is Qn and g is Q16 */
#define MUL_Q16(a, g_q16) (int32_t)(((int64_t)(a) * (int64_t)(g_q16)) >> 16)

/* -------------------------------------------------------------------------
 * Halfband FIR (symmetric, zero-skipping) evaluated only on the kept phase.
 * Accumulates full-precision 64-bit products then rounds once at the end,
 * matching RTL serial-MAC accumulate-then-round behavior.
 * ------------------------------------------------------------------------- */
static int32_t fir_hb_q15_keptphase(const int16_t *h, const int32_t *buf, uint8_t head, int taps)
{
    const int mid = (taps - 1) / 2;

    /* center tap — exact product, no per-tap rounding */
    int idx_c = (head + OSR_BUF_SIZE_HB - mid) & (OSR_BUF_SIZE_HB - 1);
    int64_t acc = (int64_t)buf[idx_c] * h[mid];

    /* symmetric pairs; halfband has zeros at odd indices, so step by 2 */
    for (int i = 0; i < mid; i += 2) {
        int idx_a = (head + OSR_BUF_SIZE_HB - i) & (OSR_BUF_SIZE_HB - 1);
        int idx_b = (head + OSR_BUF_SIZE_HB - (taps - 1 - i)) & (OSR_BUF_SIZE_HB - 1);
        int32_t sum = buf[idx_a] + buf[idx_b];
        acc += (int64_t)sum * h[i];
    }
    /* single round-to-nearest at end, matching RTL (acc + 2^14) >> 15 */
    return (int32_t)((acc + 16384) >> 15);
}

/* -------------------------------------------------------------------------
 * Symmetric FIR for LPF (odd taps).
 * Accumulates full-precision 64-bit products then rounds once at the end,
 * matching RTL serial-MAC accumulate-then-round behavior.
 * ------------------------------------------------------------------------- */
static int32_t fir_sym_q15(const int16_t *h, const int32_t *buf, uint8_t head, int taps)
{
    const int mid = (taps - 1) / 2;
    int idx_c = (head + OSR_BUF_SIZE_LPF - mid) & (OSR_BUF_SIZE_LPF - 1);

    int64_t acc = (int64_t)buf[idx_c] * h[mid];
    for (int i = 0; i < mid; ++i) {
        int idx_a = (head + OSR_BUF_SIZE_LPF - i) & (OSR_BUF_SIZE_LPF - 1);
        int idx_b = (head + OSR_BUF_SIZE_LPF - (taps - 1 - i)) & (OSR_BUF_SIZE_LPF - 1);
        int32_t sum = buf[idx_a] + buf[idx_b];
        acc += (int64_t)sum * h[i];
    }
    return (int32_t)((acc + 16384) >> 15);
}

/* -------------------------------------------------------------------------
 * CIC normalize helper: divide by 12^3 = 1728 (unity DC gain)
 * Uses a fixed reciprocal: 2^20/1728 ≈ 607.0
 * ------------------------------------------------------------------------- */
static inline int32_t cic_norm_q11(int32_t x_q11)
{
    /* x_q11 * 607 >> 20 approximates /1728 with ~0.03% error */
    return (int32_t)(((int64_t)x_q11 * 607 + (1 << 19)) >> 20);
}

/* -------------------------------------------------------------------------
 * Public streaming step
 * ------------------------------------------------------------------------- */
void LP_OSR_step(OSR_Context_t *ctx, OSR_Config_t *cfg, float adc_in, float *out, int *ready)
{
    *ready = 0;

    /* float [-1,1) -> Q1.11 counts [-2048..2047] */
    int32_t adc_q11 = (int32_t)lrintf(adc_in * 2048.0f);
    if (adc_q11 > 2047)  adc_q11 = 2047;
    if (adc_q11 < -2048) adc_q11 = -2048;

    /* -------------------- CIC (N=3, R=12) at 3.072 MHz -------------------- */
    ctx->i[0] += adc_q11;
    ctx->i[1] += ctx->i[0];
    ctx->i[2] += ctx->i[1];

    if (++ctx->cic_phase < OSR_R_CIC) {
        return;
    }
    ctx->cic_phase = 0;

    /* Comb at decimated rate */
    int32_t v  = ctx->i[2];
    int32_t d1 = v  - ctx->c[0]; ctx->c[0] = v;
    int32_t d2 = d1 - ctx->c[1]; ctx->c[1] = d1;
    int32_t d3 = d2 - ctx->c[2]; ctx->c[2] = d2;

    /* Normalize CIC DC gain to unity and convert Q11 -> Q17 */
    int32_t s_q11 = cic_norm_q11(d3);
    int32_t s = s_q11 << 6; /* Q17 */

    /* -------------------- Halfband chain (polyphase: compute only on kept output) */
    const int stages = cfg->num_hb_stages;
    for (int st = 0; st < stages; ++st) {
        uint8_t head = (uint8_t)((ctx->hb_head[st] + 1u) & (OSR_BUF_SIZE_HB - 1u));
        ctx->hb_head[st] = head;
        ctx->hb_buf[st][head] = s;

        ctx->hb_phase[st] ^= 1u;
        if (ctx->hb_phase[st] != 0u) {
            return; /* not a kept-phase sample */
        }

        int32_t y = fir_hb_q15_keptphase(cfg->hb_coef[st], ctx->hb_buf[st], head, cfg->hb_taps[st]);
        int8_t sh = cfg->hb_shift[st];
        if (sh > 0) y >>= sh;
        s = y;
    }

    /* -------------------- Final LPF (symmetric) --------------------------- */
    uint8_t lh = (uint8_t)((ctx->lpf_head + 1u) & (OSR_BUF_SIZE_LPF - 1u));
    ctx->lpf_head = lh;
    ctx->lpf_buf[lh] = s;

    int32_t y = fir_sym_q15(cfg->lpf_coef, ctx->lpf_buf, lh, cfg->lpf_taps);
    if (cfg->lpf_shift > 0) y >>= cfg->lpf_shift;

    /* -------------------- DGA -------------------------------------------- */
    int32_t dga = MUL_Q16(y, cfg->dga_frac_q16);
    if (cfg->dga_shift >= 0) dga <<= cfg->dga_shift;
    else                     dga >>= (-cfg->dga_shift);

    /* -------------------- HPF (DC blocker) ------------------------------- */
    int32_t fb = MUL_Q15(ctx->hpf_y1, cfg->hpf_alpha_q15);
    int32_t hpf = (dga - ctx->hpf_x1) + fb;
    ctx->hpf_x1 = dga;
    ctx->hpf_y1 = hpf;

    /* Output clamp to Q15 range */
    if (hpf > 32767) hpf = 32767;
    if (hpf < -32768) hpf = -32768;

    if (out) *out = (float)hpf / 32768.0f;
    *ready = 1;
}
