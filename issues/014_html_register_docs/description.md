# Issue #14: HTML Register Documentation for OSR IP

## Summary
Generate production-quality HTML register documentation for the OSR APB register interface, similar to existing `issues/003_register_html_docs/osr_regs.html`. User will provide an example HTML document as a style reference.

## Requirements
- Self-contained HTML file with register name, offset, bit-field table, reset values, R/W access type
- Consistent style with existing ADC/I2S register docs
- Auto-generation script preferred (Python)

## How to provide the example
Place the example HTML file in `issues/014_html_register_docs/example.html` or attach it to this issue directory. The style, layout, and formatting will be replicated for the OSR register set.

## Dependencies
- #12 (APB interface defines the register map)
- #3 (existing placeholder — this issue supersedes #3 for the OSR block)

## Deliverables
- `docs/osr_regs.html`
- Generation script if applicable
