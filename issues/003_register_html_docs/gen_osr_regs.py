#!/usr/bin/env python3
"""Generate OSR register documentation HTML in Ambiq Apollo510L style."""

REGS = [
    {
        "name": "CFG", "long": "Configuration", "offset": 0x00, "reset": 0x0,
        "desc": "OSR signal chain configuration. The ENABLE bit must be cleared before changing MODE or writing coefficients. Setting SOFT_RST resets the data path (CIC, HB, LPF, DGA, HPF, FIFO) and self-clears after one clock cycle.",
        "fields": [
            (31, 4, "RSVD", "RO", "0x0", "RESERVED."),
            (3, 1, "SOFT_RST", "W1", "0x0", "Write 1 to reset the data path. Self-clearing."),
            (2, 2, "MODE", "RW", "0x0",
             "Operating mode selection. Only change when ENABLE=0.<br><br>"
             " NB = 0x0 - Narrowband, 8 kHz output<br>"
             " WB = 0x1 - Wideband, 16 kHz output<br>"
             " SWB = 0x2 - Super-wideband, 32 kHz output<br>"
             " RSVD = 0x3 - Reserved"),
            (0, 1, "ENABLE", "RW", "0x0",
             "Enable the OSR signal chain. When set, data flows from ADC capture through to FIFO. Must be cleared before changing MODE, DGA_GAIN, or coefficients.<br><br>"
             " DIS = 0x0 - Disabled<br>"
             " EN = 0x1 - Enabled"),
        ]
    },
    {
        "name": "DGA_GAIN", "long": "Digital Gain Adjust", "offset": 0x04, "reset": 0x10000,
        "desc": "DGA gain control. Gain = (FRAC_Q16 / 65536) &times; 2^SHIFT. Only writable when CFG.ENABLE = 0. The DGA compensates for FIR chain DC gain and application-specific attenuation.",
        "fields": [
            (31, 11, "RSVD", "RO", "0x0", "RESERVED."),
            (20, 4, "SHIFT", "RW", "0x0",
             "Signed barrel-shift exponent (two's complement). Positive = left shift (gain), negative = right shift (attenuation). Range: -8 to +7."),
            (16, 17, "FRAC_Q16", "RW", "0x10000",
             "Unsigned Q16 fractional multiplier. 0x10000 = 1.0. Range: 0x10000 (1.0) to 0x1FFFF (~2.0)."),
        ]
    },
    {
        "name": "STAT", "long": "Status", "offset": 0x08, "reset": 0x01,
        "desc": "Read-only status register. OVERFLOW is sticky and cleared by writing INTCLR.OVERFLOW or by SOFT_RST.",
        "fields": [
            (31, 27, "RSVD", "RO", "0x0", "RESERVED."),
            (4, 1, "ENABLED", "RO", "0x0", "Data path is running (synchronised to data-clock domain)."),
            (3, 1, "OVERFLOW", "RO", "0x0", "HPF output clamp occurred (sticky). Clear via INTCLR or SOFT_RST."),
            (2, 1, "FIFO_HALF", "RO", "0x0", "FIFO contains &ge; 16 entries."),
            (1, 1, "FIFO_FULL", "RO", "0x0", "FIFO contains 32 entries. Further writes are dropped."),
            (0, 1, "FIFO_EMPTY", "RO", "0x1", "FIFO contains 0 entries."),
        ]
    },
    {
        "name": "FIFODATA", "long": "FIFO Read Data", "offset": 0x0C, "reset": 0x0,
        "desc": "Reading this register pops one 16-bit signed sample from the output FIFO. Returns 0x0000 if FIFO is empty.",
        "fields": [
            (31, 16, "RSVD", "RO", "0x0", "RESERVED."),
            (15, 16, "DATA", "RO", "0x0", "Signed 16-bit output sample (Q15)."),
        ]
    },
    {
        "name": "FIFOCNT", "long": "FIFO Entry Count", "offset": 0x10, "reset": 0x0,
        "desc": "Number of valid entries currently in the output FIFO (0 to 32).",
        "fields": [
            (31, 26, "RSVD", "RO", "0x0", "RESERVED."),
            (5, 6, "COUNT", "RO", "0x0", "FIFO occupancy (0&ndash;32)."),
        ]
    },
    {
        "name": "INTEN", "long": "Interrupt Enable", "offset": 0x14, "reset": 0x0,
        "desc": "Interrupt enable mask. Set bits to allow corresponding events to assert the OSR interrupt to the M55 NVIC.",
        "fields": [
            (31, 29, "RSVD", "RO", "0x0", "RESERVED."),
            (2, 1, "OVERFLOW", "RW", "0x0", "Enable interrupt on HPF overflow/clamp."),
            (1, 1, "FIFO_FULL", "RW", "0x0", "Enable interrupt on FIFO full."),
            (0, 1, "FIFO_HALF", "RW", "0x0", "Enable interrupt on FIFO half-full (&ge;16 entries)."),
        ]
    },
    {
        "name": "INTSTAT", "long": "Interrupt Status", "offset": 0x18, "reset": 0x0,
        "desc": "Interrupt status (read-only). Reflects raw event status ANDed with INTEN.",
        "fields": [
            (31, 29, "RSVD", "RO", "0x0", "RESERVED."),
            (2, 1, "OVERFLOW", "RO", "0x0", "HPF overflow interrupt pending."),
            (1, 1, "FIFO_FULL", "RO", "0x0", "FIFO full interrupt pending."),
            (0, 1, "FIFO_HALF", "RO", "0x0", "FIFO half-full interrupt pending."),
        ]
    },
    {
        "name": "INTCLR", "long": "Interrupt Clear", "offset": 0x1C, "reset": 0x0,
        "desc": "Write-1-to-clear. Writing a 1 to a bit clears the corresponding INTSTAT bit and the sticky STAT.OVERFLOW flag.",
        "fields": [
            (31, 29, "RSVD", "RO", "0x0", "RESERVED."),
            (2, 1, "OVERFLOW", "WO", "0x0", "Write 1 to clear OVERFLOW."),
            (1, 1, "FIFO_FULL", "WO", "0x0", "Write 1 to clear FIFO_FULL."),
            (0, 1, "FIFO_HALF", "WO", "0x0", "Write 1 to clear FIFO_HALF."),
        ]
    },
    {
        "name": "INTSET", "long": "Interrupt Set (Debug)", "offset": 0x20, "reset": 0x0,
        "desc": "Write-1-to-set. Writing a 1 to a bit forces the corresponding INTSTAT bit high. Intended for debug/test only.",
        "fields": [
            (31, 29, "RSVD", "RO", "0x0", "RESERVED."),
            (2, 1, "OVERFLOW", "WO", "0x0", "Write 1 to force OVERFLOW."),
            (1, 1, "FIFO_FULL", "WO", "0x0", "Write 1 to force FIFO_FULL."),
            (0, 1, "FIFO_HALF", "WO", "0x0", "Write 1 to force FIFO_HALF."),
        ]
    },
    {
        "name": "COEF_KEY", "long": "Coefficient Unlock Key", "offset": 0x24, "reset": 0x0,
        "desc": "Write the magic value 0x4F535200 to unlock coefficient writes. The lock re-engages when: CFG.ENABLE is set to 1, WRITES_LEFT reaches 0, or an incorrect key is written. This prevents rogue software from corrupting filter coefficients.",
        "fields": [
            (31, 32, "KEY", "WO", "0x0",
             "Write 0x4F535200 to unlock. Any other value re-locks immediately."),
        ]
    },
    {
        "name": "COEF_ADDR", "long": "Coefficient Address", "offset": 0x28, "reset": 0x0,
        "desc": "Selects the coefficient bank and tap index for read/write via COEF_DATA. INDEX auto-increments on each COEF_DATA write.",
        "fields": [
            (31, 21, "RSVD", "RO", "0x0", "RESERVED."),
            (10, 3, "BANK", "RW", "0x0",
             "Coefficient bank select.<br><br>"
             " HB1 = 0x0 - 11-tap halfband 1 (taps 0&ndash;10)<br>"
             " HB2 = 0x1 - 19-tap halfband 2 (taps 0&ndash;18)<br>"
             " LP8 = 0x2 - 21-tap LPF for NB/8 kHz (taps 0&ndash;20)<br>"
             " LP16 = 0x3 - 21-tap LPF for WB/16 kHz (taps 0&ndash;20)<br>"
             " LP32 = 0x4 - 21-tap LPF for SWB/32 kHz (taps 0&ndash;20)"),
            (7, 1, "RSVD", "RO", "0x0", "RESERVED."),
            (6, 7, "INDEX", "RW", "0x0", "Tap index within the selected bank. Auto-increments after each COEF_DATA write."),
        ]
    },
    {
        "name": "COEF_DATA", "long": "Coefficient Data", "offset": 0x2C, "reset": 0x0,
        "desc": "Read or write the Q15 coefficient at COEF_ADDR[BANK][INDEX]. Writes are only accepted when COEF_STAT.LOCKED = 0 AND CFG.ENABLE = 0. Each write auto-increments COEF_ADDR.INDEX and decrements COEF_STAT.WRITES_LEFT.",
        "fields": [
            (31, 16, "RSVD", "RO", "0x0", "RESERVED."),
            (15, 16, "DATA", "RW", "0x0", "Signed Q1.15 coefficient value. Range: -32768 to +32767."),
        ]
    },
    {
        "name": "COEF_STAT", "long": "Coefficient Lock Status", "offset": 0x30, "reset": 0x01,
        "desc": "Shows the current coefficient protection state.",
        "fields": [
            (31, 24, "RSVD", "RO", "0x0", "RESERVED."),
            (7, 7, "WRITES_LEFT", "RO", "0x0", "Number of coefficient writes remaining before auto-lock (0&ndash;16). Reset to 16 on valid COEF_KEY write."),
            (0, 1, "LOCKED", "RO", "0x1",
             "Coefficient write-protect status.<br><br>"
             " LOCKED = 0x1 - Writes to COEF_DATA are ignored<br>"
             " UNLOCKED = 0x0 - Writes to COEF_DATA are accepted"),
        ]
    },
]

def bit_header():
    return "".join(f"                            <th>{i}</th>\n" for i in range(31, -1, -1))

def bit_row(fields):
    cells = []
    for msb, width, name, rw, reset, desc in fields:
        cells.append(
            f'                            <td align="center" colspan="{width}">{name}\n'
            f'                                <br>{reset}</td>\n')
    return "".join(cells)

def field_rows(fields):
    rows = []
    for msb, width, name, rw, reset, desc in fields:
        lsb = msb - width + 1
        bits = f"{msb}" if width == 1 else f"{msb}:{lsb}"
        rows.append(
            f"                        <tr>\n"
            f"                            <td>{bits}</td>\n"
            f"                            <td>{name}</td>\n"
            f"                            <td>{rw}</td>\n"
            f"                            <td>{desc}<br><br>\n"
            f"                                </td>\n"
            f"                        </tr>\n")
    return "".join(rows)

def reg_index():
    rows = []
    for r in REGS:
        rows.append(
            f'                    <tr id="row_0_0_">\n'
            f'                        <td class="entry">\n'
            f'                            <span style="width:32px;display:inline-block;">&#160;</span>\n'
            f'                            <span class="h5">0x{r["offset"]:08X}:</span>\n'
            f'                        </td>\n'
            f'                        <td class="entry">\n'
            f'                            <span style="width:32px;display:inline-block;">&#160;</span>\n'
            f'                            <a class="el" href="#{r["name"]}" target="_self">{r["name"]} - {r["long"]}</a>\n'
            f'                        </td>\n'
            f'                    </tr>\n')
    return "".join(rows)

def reg_panel(r):
    return (
        f'        <div class="panel panel-default">\n'
        f'            <div class="panel-heading">\n'
        f'                <h3 id="{r["name"]}" class="panel-title">{r["name"]} - {r["long"]}</h3>\n'
        f'            </div>\n'
        f'            <div class="panel-body">\n'
        f'                <h3>Address:</h3>\n'
        f'                <table style="margin:10px">\n'
        f'                    <tr id="row_0_0_">\n'
        f'                        <td class="entry">\n'
        f'                            <span style="width:32px;display:inline-block;">&#160;</span>\n'
        f'                            <span class="h5">Offset:</span>\n'
        f'                        </td>\n'
        f'                        <td class="entry">\n'
        f'                            <span style="width:32px;display:inline-block;">&#160;</span>\n'
        f'                            <span class="h5">0x{r["offset"]:08X}</span>\n'
        f'                        </td>\n'
        f'                    </tr>\n'
        f'                    <tr id="row_0_0_">\n'
        f'                        <td class="entry">\n'
        f'                            <span style="width:32px;display:inline-block;">&#160;</span>\n'
        f'                            <span class="h5">Reset:</span>\n'
        f'                        </td>\n'
        f'                        <td class="entry">\n'
        f'                            <span style="width:32px;display:inline-block;">&#160;</span>\n'
        f'                            <span class="h5">0x{r["reset"]:08X}</span>\n'
        f'                        </td>\n'
        f'                    </tr>\n'
        f'                </table>\n'
        f'                <h3>Description:</h3>\n'
        f'                <p>{r["desc"]}</p>\n'
        f'                <h3>Register Fields:</h3>\n'
        f'                <table style="margin:10px" class="table table-bordered table-condensed">\n'
        f'                    <thead>\n'
        f'                        <tr>\n'
        f'{bit_header()}'
        f'                        </tr>\n'
        f'                    </thead>\n'
        f'                    <tbody>\n'
        f'                        <tr>\n'
        f'{bit_row(r["fields"])}'
        f'                        </tr>\n'
        f'                    </tbody>\n'
        f'                </table>\n'
        f'                <br>\n'
        f'\n'
        f'                <table style="margin:10px" class="table table-bordered table-condensed">\n'
        f'                    <thead>\n'
        f'                        <tr>\n'
        f'                            <th>Bits</th>\n'
        f'                            <th>Name</th>\n'
        f'                            <th>RW</th>\n'
        f'                            <th>Description</th>\n'
        f'                        </tr>\n'
        f'                    </thead>\n'
        f'                    <tbody>\n'
        f'{field_rows(r["fields"])}'
        f'                    </tbody>\n'
        f'                </table>\n'
        f'                <br>\n'
        f'            </div>\n'
        f'        </div>\n'
    )

html = f'''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

<head>
    <meta http-equiv="Content-Type" content="text/xhtml;charset=UTF-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=9" />
    <meta name="generator" content="AmbiqMicro" />
    <title>Apollo510L OSR</title>
    <link href="../resources/tabs.css" rel="stylesheet" type="text/css" />
    <link href="../resources/bootstrap.css" rel="stylesheet" type="text/css" />
    <script type="text/javascript" src="../resources/jquery.js"></script>
    <script type="text/javascript" src="../resources/dynsections.js"></script>
    <link href="search/search.css" rel="stylesheet" type="text/css" />
    <link href="../resources/customdoxygen.css" rel="stylesheet" type="text/css" />
</head>

<body>
    <div id="top">
        <div id="titlearea">
            <table cellspacing="0" cellpadding="0">
                <tbody>
                    <tr style="height: 56px;">
                        <td id="projectlogo">
                            <img alt="Logo" src="../resources/am_logo.png" />
                        </td>
                        <td style="padding-left: 0.5em;">
                            <div id="projectname">Apollo510L  Register Documentation &#160;<span id="projectnumber">lpadcca</span></div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        <div id="navrow1" class="tabs">
            <ul class="tablist">
                <li class="current"><a href="../index.html"><span>Main&#160;Page</span></a>
                </li>
        </div>
        </li>
        </ul>
    </div>
    </div>
    <div class="header">
        <div class="headertitle">
            <div class="title">OSR - Oversampled Decimation Signal Chain</div>
        </div>
    </div>
    <body>
        <br>
        <div class="panel panel-default">
            <div class="panel-heading">
                <h3 class="panel-title"> OSR Register Index</h3>
            </div>
            <div class="panel-body">
                <table>
{reg_index()}
                </table>
            </div>
        </div>

{"".join(reg_panel(r) for r in REGS)}
    </body>

    <hr size="1">
    <body>
        <div id="footer" align="right">
            <small>
                AmbiqSuite Register Documentation&nbsp;
                <a href="http://www.ambiqmicro.com">
                <img class="footer" src="../resources/ambiqmicro_logo.png" alt="Ambiq Micro"/></a>&nbsp&nbsp Copyright &copy; 2025&nbsp&nbsp<br />
                This documentation is licensed and distributed under the <a rel="license" href="http://opensource.org/licenses/BSD-3-Clause">BSD 3-Clause License</a>.&nbsp&nbsp<br/>
            </small>
        </div>
    </body>
</html>
'''

with open("osr_regs.html", "w") as f:
    f.write(html)
print(f"Generated osr_regs.html ({len(REGS)} registers)")
