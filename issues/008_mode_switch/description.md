# Issue #8: Clean mode switch test

## Description
Verify that mode switching is clean when the application follows the expected sequence: stop the circuit, change mode, then re-enable it.

## Test Plan
- Run mode A (e.g. NB) with a 1 kHz tone, collect output, verify valid
- Assert reset (rst_n=0)
- Change mode to B (e.g. WB), change DGA/HPF params
- De-assert reset (rst_n=1)
- Run mode B, verify output settles cleanly with correct rate and amplitude
- Repeat for all mode transitions: NB→WB, WB→SWB, SWB→NB
- Check: no glitches, no overflow, correct output rate after switch

## Assumption
The application will stop the circuit (reset), change modes, then enable it. No glitch-free dynamic mode switching required.

## Status
Open — ready to implement.
