# Issue #11: Hardcode HPF alpha in HW, keep DGA programmable

## Description
HPF alpha is purely mode-dependent and never tuned independently. Hardcode it as a LUT in RTL indexed by mode[1:0]. Remove hpf_alpha_q15 from osr_top port list.

DGA gain varies with atten_db/headroom_db per application, so keep it programmable via ports (future APB register).

## HPF alpha values (fixed in HW)
| Mode | Alpha Q15 |
|------|-----------|
| NB (0)  | 27999 |
| WB (1)  | 30893 |
| SWB (2) | 31817 |

## Changes
- osr_top: remove hpf_alpha_q15 input, add internal wire driven by mode LUT
- hpf.v: no change (still takes alpha_q15 as input from parent)
- TB: remove hpf_alpha_q15 from DUT instantiation and configure_mode

## Status
Closed — implemented. HPF alpha LUT added to osr_top, port removed, TB updated.
