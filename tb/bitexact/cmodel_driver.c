/*
 * cmodel_driver.c — Standalone C driver for bit-exact OSR C-model output.
 *
 * Usage:
 *   ./cmodel_driver <mode> <stim_type> <freq> <amplitude> <nsamples>
 *
 * mode:       0 = NB (8 kHz), 1 = WB (16 kHz), 2 = SWB (32 kHz)
 * stim_type:  sine | dc | ramp
 * freq:       stimulus frequency in Hz (used for sine)
 * amplitude:  peak amplitude in ADC codes (e.g. 1449 for −3 dBFS)
 * nsamples:   number of ADC-rate (3.072 MHz) input samples
 *
 * Prints one signed-16-bit integer per line to stdout for each output sample.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>

#include "../../ref/lpadc_osr.h"   /* OSR_Context_t, LP_OSR_step */

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define FS_ADC 3072000.0

int main(int argc, char *argv[])
{
    if (argc != 6) {
        fprintf(stderr, "Usage: %s <mode> <stim_type> <freq> <amplitude> <nsamples>\n",
                argv[0]);
        return 1;
    }

    int mode      = atoi(argv[1]);
    const char *stype = argv[2];
    double freq   = atof(argv[3]);
    int amplitude = atoi(argv[4]);
    int nsamples  = atoi(argv[5]);

    /* Initialize configuration (unity gain: atten_db=0, headroom_db=0) */
    OSR_Config_t cfg;
    sysparm_init(&cfg, mode, 0.0f, 0.0f);

    /* Print DGA config to stderr for debugging */
    fprintf(stderr, "mode=%d  dga_shift=%d  dga_frac_q16=%u  hpf_alpha=%d\n",
            mode, cfg.dga_shift, cfg.dga_frac_q16, cfg.hpf_alpha_q15);

    /* Initialize context */
    OSR_Context_t ctx;
    memset(&ctx, 0, sizeof(ctx));

    int ramp_val = 0;

    for (int idx = 0; idx < nsamples; idx++) {
        int q;

        /* Generate stimulus — MUST match RTL testbench and gen_stim.py exactly */
        if (strcmp(stype, "sine") == 0) {
            double sv = sin(2.0 * M_PI * freq * (double)idx / FS_ADC);
            q = (int)(sv * (double)amplitude);
            if (q >  2047) q =  2047;
            if (q < -2048) q = -2048;
        } else if (strcmp(stype, "dc") == 0) {
            q = amplitude;
            if (q >  2047) q =  2047;
            if (q < -2048) q = -2048;
        } else if (strcmp(stype, "ramp") == 0) {
            /* Unsigned ramp 0..4095 offset to signed −2048..2047 */
            q = (ramp_val & 0xFFF) - 2048;
            ramp_val++;
        } else {
            fprintf(stderr, "Unknown stim_type: %s\n", stype);
            return 1;
        }

        /* Convert integer code to float [-1,1) as LP_OSR_step expects */
        float adc_in = (float)q / 2048.0f;

        float out;
        int   ready;
        LP_OSR_step(&ctx, &cfg, adc_in, &out, &ready);

        if (ready) {
            /*
             * Reconstruct the clamped integer from the float output.
             * LP_OSR_step returns (float)hpf / 32768.0f where hpf is
             * already clamped to [−32768, 32767].  Recovering via
             * lrintf(out * 32768.0f) is lossless for these integers.
             */
            int32_t ival = (int32_t)lrintf(out * 32768.0f);
            if (ival >  32767) ival =  32767;
            if (ival < -32768) ival = -32768;
            printf("%d\n", (int)ival);
        }
    }

    return 0;
}
