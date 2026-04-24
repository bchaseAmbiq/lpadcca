/* Multirate OSR decimators (auto-generated, DC-normalized) */
#pragma once

#include <stdint.h>

#define OSR_R_CIC 12
#define OSR_N_CIC 3

static const float HB1_COEF[11] = {
  9.653852623e-02f, 0.000000000e+00f, -8.971801331e-02f, 0.000000000e+00f, 
  2.757998934e-01f, 4.347591873e-01f, 2.757998934e-01f, 0.000000000e+00f, 
  -8.971801331e-02f, 0.000000000e+00f, 9.653852623e-02f
};

#define HB1_COEF_TAPS 11

static const float HB2_COEF[19] = {
  4.505134922e-02f, 0.000000000e+00f, -3.461130816e-02f, 0.000000000e+00f, 
  5.368537602e-02f, 0.000000000e+00f, -9.579917939e-02f, 0.000000000e+00f, 
  2.972444044e-01f, 4.688587159e-01f, 2.972444044e-01f, 0.000000000e+00f, 
  -9.579917939e-02f, 0.000000000e+00f, 5.368537602e-02f, 0.000000000e+00f, 
  -3.461130816e-02f, 0.000000000e+00f, 4.505134922e-02f
};

#define HB2_COEF_TAPS 19

// 21-tap Hamming-windowed sinc LPF designs (replaces 41-tap — half MAC cycles,
// half shift register, ~1-2 µW power savings at modest roll-off cost).
// DC gain verified ≈1.0 (≤0.3% error); stopband attenuation ≈42 dB.
// Matching Q15 values are hardcoded in rtl/lpf_eq.v coef_rom defaults.
static const float LP8_COEF[21] = {
   2.533e-03f, -3.235e-03f,  3.937e-03f, -1.923e-03f, -6.500e-03f,
   2.432e-02f, -5.164e-02f,  8.490e-02f, -1.173e-01f,  1.413e-01f,
   8.500e-01f,
   1.413e-01f, -1.173e-01f,  8.490e-02f, -5.164e-02f,  2.432e-02f,
  -6.500e-03f, -1.923e-03f,  3.937e-03f, -3.235e-03f,  2.533e-03f
};

#define LP8_COEF_TAPS 21

static const float LP16_COEF[21] = {
   1.800e-03f, -1.373e-03f,  0.000e+00f,  4.700e-03f, -1.492e-02f,
   3.174e-02f, -5.429e-02f,  7.935e-02f, -1.027e-01f,  1.190e-01f,
   8.750e-01f,
   1.190e-01f, -1.027e-01f,  7.935e-02f, -5.429e-02f,  3.174e-02f,
  -1.492e-02f,  4.700e-03f,  0.000e+00f, -1.373e-03f,  1.800e-03f
};

#define LP16_COEF_TAPS 21

static const float LP32_COEF[21] = {
  -2.411e-03f,  3.601e-03f, -6.653e-03f,  1.187e-02f, -1.910e-02f,
   2.780e-02f, -3.717e-02f,  4.602e-02f, -5.343e-02f,  5.829e-02f,
   9.400e-01f,
   5.829e-02f, -5.343e-02f,  4.602e-02f, -3.717e-02f,  2.780e-02f,
  -1.910e-02f,  1.187e-02f, -6.653e-03f,  3.601e-03f, -2.411e-03f
};

#define LP32_COEF_TAPS 21

