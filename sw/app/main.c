#include <stdint.h>
#include <stdio.h>
#include "../driver/osr_drv.h"
#include "../hal/osr_hal.h"

#define NUM_SAMPLES 256
#define TIMEOUT_US  100000

static const struct {
    const char *name;
    uint8_t     mode;
    int8_t      dga_shift;
    uint32_t    dga_frac;
} mode_table[] = {
    { "NB",  OSR_MODE_NB,  -3, 130637 },
    { "WB",  OSR_MODE_WB,  -3, 130828 },
    { "SWB", OSR_MODE_SWB, -2, 65672  },
};

static int16_t samples[NUM_SAMPLES];

static void run_capture(uint8_t idx)
{
    const char *name   = mode_table[idx].name;
    int8_t      shift  = mode_table[idx].dga_shift;
    uint32_t    frac   = mode_table[idx].dga_frac;
    uint8_t     m      = mode_table[idx].mode;

    printf("\n--- %s (mode=%u, shift=%d, frac=%lu) ---\n",
           name, m, shift, (unsigned long)frac);

    osr_config_t cfg = {
        .mode            = m,
        .dga_shift       = shift,
        .dga_frac_q16   = frac,
        .int_enable_mask = OSR_INT_HALF_MSK,
        .fifo_thresh     = 8
    };

    osr_status_t st = osr_init(&cfg);
    if (st != OSR_OK) {
        printf("  osr_init failed: %d\n", st);
        return;
    }
    osr_enable();

    st = osr_fifo_read_block(samples, NUM_SAMPLES, TIMEOUT_US);
    osr_disable();

    if (st == OSR_ERR_TMO) {
        printf("  timeout during capture\n");
        return;
    }

    int16_t pk_pos = -32768;
    int16_t pk_neg =  32767;
    for (uint32_t i = 0; i < NUM_SAMPLES; i++) {
        if (samples[i] > pk_pos) pk_pos = samples[i];
        if (samples[i] < pk_neg) pk_neg = samples[i];
    }

    uint32_t ovf = osr_fifo_overflow() ? 1 : 0;
    printf("  captured: %u  pk+=%d  pk-=%d  ovf=%lu\n",
           NUM_SAMPLES, pk_pos, pk_neg, (unsigned long)ovf);

    printf("  fifo count after: %lu\n",
           (unsigned long)osr_fifo_count());

    printf("  first 8:");
    for (uint32_t i = 0; i < 8; i++)
        printf(" %d", samples[i]);
    printf("\n");
}

int main(void)
{
    printf("=== OSR M55 Smoke Test ===\n");

    uint32_t id = osr_read_id();
    printf("OSR IP ID: 0x%08lX %s\n", (unsigned long)id,
           (id == OSR_ID_EXPECTED) ? "(OK)" : "(MISMATCH)");

    if (id != OSR_ID_EXPECTED) {
        printf("ABORT: unexpected IP ID\n");
        return 1;
    }

    for (uint32_t i = 0; i < sizeof(mode_table)/sizeof(mode_table[0]); i++)
        run_capture((uint8_t)i);

    printf("\n=== Done ===\n");
    return 0;
}
