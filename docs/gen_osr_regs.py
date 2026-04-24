#!/usr/bin/env python3
"""Generate docs/osr_regs.html from the register map definition."""

REGS = [
    {
        "name": "CTRL", "long": "OSR Control", "offset": 0x00,
        "addr": 0x40010000, "reset": 0x00000000,
        "fields_visual": [
            (24, "RSVD", "0x0"),
            (4, "DGASHIFT", "0x0"),
            (1, "RSVD", "0x0"),
            (1, "EN", "0x0"),
            (2, "MODE", "0x0"),
        ],
        "fields": [
            ("31:8", "RSVD", "RO", "Reserved"),
            ("7:4", "DGASHIFT", "RW",
             "DGA barrel-shift exponent (signed 4-bit two's complement, "
             "range −8 to +7). Gain = 2^DGASHIFT × DGAFRAC/65536."),
            ("3", "RSVD", "RO", "Reserved"),
            ("2", "EN", "RW",
             "OSR core enable. When cleared, the decimation core is held in reset.<br><br>\n"
             "                                 DIS                  = 0x0 - Core held in reset.<br>\n"
             "                             EN                   = 0x1 - Core enabled and processing."),
            ("1:0", "MODE", "RW",
             "Audio output sample-rate mode selection.<br><br>\n"
             "                                 NB                   = 0x0 - Narrowband: 8 kHz output.<br>\n"
             "                             WB                   = 0x1 - Wideband: 16 kHz output.<br>\n"
             "                             SWB                  = 0x2 - Super-wideband: 32 kHz output.<br>\n"
             "                             RSVD                 = 0x3 - Reserved (defaults to SWB)."),
        ],
    },
    {
        "name": "DGA_FRAC", "long": "DGA Fractional Gain", "offset": 0x04,
        "addr": 0x40010004, "reset": 0x00000000,
        "fields_visual": [(15, "RSVD", "0x0"), (17, "DGAFRAC", "0x0")],
        "fields": [
            ("31:17", "RSVD", "RO", "Reserved"),
            ("16:0", "DGAFRAC", "RW",
             "Unsigned Q16 fractional gain multiplier (17 bits). "
             "Range [65536, 131071] representing 1.0 to ~2.0. "
             "DGA computes: out = (in × DGAFRAC) &gt;&gt; 16, then barrel shift from CTRL.DGASHIFT."),
        ],
    },
    {
        "name": "FIFO_STATUS", "long": "FIFO Status", "offset": 0x08,
        "addr": 0x40010008, "reset": 0x00000001,
        "fields_visual": [
            (24, "RSVD", "0x0"), (4, "COUNT", "0x0"),
            (1, "OVF", "0x0"), (1, "FULL", "0x0"),
            (1, "HALF", "0x0"), (1, "EMPTY", "0x1"),
        ],
        "fields": [
            ("31:8", "RSVD", "RO", "Reserved"),
            ("7:4", "COUNT", "RO", "Number of valid entries in FIFO (0–15 in this 4-bit field; saturates at 15 for count=16)."),
            ("3", "OVF", "R/W1C", "Overflow (sticky). Set when a write is attempted while FIFO is full. Write 1 to INTCLR[3] or FIFO_STATUS[3] to clear."),
            ("2", "FULL", "RO", "FIFO full flag. Asserted when count == 16."),
            ("1", "HALF", "RO", "FIFO half-full flag. Asserted when count &gt;= FIFO_THRESH."),
            ("0", "EMPTY", "RO", "FIFO empty flag. Asserted when count == 0. Set after reset or flush."),
        ],
    },
    {
        "name": "FIFO_DATA", "long": "FIFO Data Read", "offset": 0x0C,
        "addr": 0x4001000C, "reset": 0x00000000,
        "fields_visual": [(16, "SIGN_EXT", "0x0"), (16, "SAMPLE", "0x0")],
        "fields": [
            ("31:16", "SIGN_EXT", "RO", "Sign extension of bit 15."),
            ("15:0", "SAMPLE", "RO", "Signed 16-bit PCM audio sample. Reading this register pops one entry from the FIFO."),
        ],
    },
    {
        "name": "INTEN", "long": "Interrupt Enable", "offset": 0x10,
        "addr": 0x40010010, "reset": 0x00000000,
        "fields_visual": [
            (28, "RSVD", "0x0"),
            (1, "OVF", "0x0"), (1, "FULL", "0x0"),
            (1, "HALF", "0x0"), (1, "EMPTY", "0x0"),
        ],
        "fields": [
            ("31:4", "RSVD", "RO", "Reserved"),
            ("3", "OVF", "RW", "Overflow interrupt enable."),
            ("2", "FULL", "RW", "FIFO full interrupt enable."),
            ("1", "HALF", "RW", "FIFO half-full interrupt enable."),
            ("0", "EMPTY", "RW", "FIFO empty interrupt enable."),
        ],
    },
    {
        "name": "INTSTAT", "long": "Interrupt Status", "offset": 0x14,
        "addr": 0x40010014, "reset": 0x00000001,
        "fields_visual": [
            (28, "RSVD", "0x0"),
            (1, "OVF", "0x0"), (1, "FULL", "0x0"),
            (1, "HALF", "0x0"), (1, "EMPTY", "0x1"),
        ],
        "fields": [
            ("31:4", "RSVD", "RO", "Reserved"),
            ("3", "OVF", "RO", "Overflow flag (mirrors FIFO_STATUS.OVF)."),
            ("2", "FULL", "RO", "FIFO full flag."),
            ("1", "HALF", "RO", "FIFO half-full flag."),
            ("0", "EMPTY", "RO", "FIFO empty flag."),
        ],
    },
    {
        "name": "INTCLR", "long": "Interrupt Clear", "offset": 0x18,
        "addr": 0x40010018, "reset": 0x00000000,
        "fields_visual": [
            (28, "RSVD", "0x0"),
            (1, "OVF", "0x0"), (1, "FULL", "0x0"),
            (1, "HALF", "0x0"), (1, "EMPTY", "0x0"),
        ],
        "fields": [
            ("31:4", "RSVD", "RO", "Reserved"),
            ("3", "OVF", "W1C", "Write 1 to clear the overflow sticky flag."),
            ("2", "FULL", "W1C", "No effect (FULL auto-clears when not full)."),
            ("1", "HALF", "W1C", "No effect (HALF auto-clears when below threshold)."),
            ("0", "EMPTY", "W1C", "No effect (EMPTY auto-clears when not empty)."),
        ],
    },
    {
        "name": "FIFO_THRESH", "long": "FIFO Threshold", "offset": 0x1C,
        "addr": 0x4001001C, "reset": 0x00000008,
        "fields_visual": [(28, "RSVD", "0x0"), (4, "FIFOTHR", "0x8")],
        "fields": [
            ("31:4", "RSVD", "RO", "Reserved"),
            ("3:0", "FIFOTHR", "RW",
             "Half-full threshold. The HALF flag asserts when FIFO count &gt;= FIFOTHR. Default 8 (half of 16-deep FIFO)."),
        ],
    },
    {
        "name": "FIFO_FLUSH", "long": "FIFO Flush", "offset": 0x20,
        "addr": 0x40010020, "reset": 0x00000000,
        "fields_visual": [(31, "RSVD", "0x0"), (1, "FLUSH", "0x0")],
        "fields": [
            ("31:1", "RSVD", "RO", "Reserved"),
            ("0", "FLUSH", "WO", "Write 1 to flush the FIFO, reset all pointers, and clear the OVF flag."),
        ],
    },
    {
        "name": "ID", "long": "IP Identification", "offset": 0x24,
        "addr": 0x40010024, "reset": 0xA05B0002,
        "fields_visual": [(32, "ID", "0xA05B0002")],
        "fields": [
            ("31:0", "ID", "RO",
             "IP identification. Fixed value 0xA05B0002. "
             "Upper 16 bits (0xA05B) = Ambiq OSR block identifier; "
             "lower 16 bits (0x0002) = revision 2."),
        ],
    },
]

def bit_header():
    return "".join(f"<th>{i}</th>" for i in range(31, -1, -1))

def visual_row(fields_visual):
    cells = []
    for span, name, rst in fields_visual:
        cells.append(
            f'<td align="center" colspan="{span}">{name}\n'
            f'                                <br>{rst}</td>\n'
        )
    return "".join(cells)

def field_rows(fields):
    rows = []
    for bits, name, rw, desc in fields:
        rows.append(
            f"                        <tr>\n"
            f"                            <td>{bits}</td>\n"
            f"                            <td>{name}</td>\n"
            f"                            <td>{rw}</td>\n"
            f"                            <td>{desc}<br><br>\n"
            f"                                </td>\n"
            f"                        </tr>\n"
        )
    return "".join(rows)

def index_entry(reg):
    return (
        f'                    <tr id="row_0_0_">\n'
        f'                        <td class="entry">\n'
        f'                            <span style="width:32px;display:inline-block;">&#160;</span>\n'
        f'                            <span class="h5">0x{reg["offset"]:08X}:</span>\n'
        f'                        </td>\n'
        f'                        <td class="entry">\n'
        f'                            <span style="width:32px;display:inline-block;">&#160;</span>\n'
        f'                            <a class="el" href="#{reg["name"]}" target="_self">'
        f'{reg["name"]} - {reg["long"]}</a>\n'
        f'                        </td>\n'
        f'                    </tr>\n'
    )

def reg_panel(reg):
    return (
        f'        <div class="panel panel-default">\n'
        f'            <div class="panel-heading">\n'
        f'                <h3 id="{reg["name"]}" class="panel-title">'
        f'{reg["name"]} - {reg["long"]}</h3>\n'
        f'            </div>\n'
        f'            <div class="panel-body">\n'
        f'                <h3>Address:</h3>\n'
        f'                <table style="margin:10px">\n'
        f'                    <tr id="row_0_0_">\n'
        f'                        <td class="entry">\n'
        f'                            <span style="width:32px;display:inline-block;">&#160;</span>\n'
        f'                            <span class="h5">Instance 0 Address:</span>\n'
        f'                        </td>\n'
        f'                        <td class="entry">\n'
        f'                            <span style="width:32px;display:inline-block;">&#160;</span>\n'
        f'                            <span class="h5">0x{reg["addr"]:08X}</span>\n'
        f'                        </td>\n'
        f'                    </tr>\n'
        f'                </table>\n'
        f'                <h3>Description:</h3>\n'
        f'                <p>{reg["long"]}</p>\n'
        f'                <h3>Register Fields:</h3>\n'
        f'                <table style="margin:10px" class="table table-bordered table-condensed">\n'
        f'                    <thead>\n'
        f'                        <tr>\n'
        f'                            {bit_header()}\n'
        f'                        </tr>\n'
        f'                    </thead>\n'
        f'                    <tbody>\n'
        f'                        <tr>\n'
        f'                            {visual_row(reg["fields_visual"])}\n'
        f'                        </tr>\n'
        f'                    </tbody>\n'
        f'                </table>\n'
        f'                <br>\n'
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
        f'{field_rows(reg["fields"])}\n'
        f'                    </tbody>\n'
        f'                </table>\n'
        f'                <br>\n'
        f'            </div>\n'
        f'        </div>\n'
    )

header = '''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="Content-Type" content="text/xhtml;charset=UTF-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=9" />
    <meta name="generator" content="AmbiqMicro" />
    <title>OSR Audio Decimation</title>
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
                        <td id="projectlogo"><img alt="Logo" src="../resources/am_logo.png" /></td>
                        <td style="padding-left: 0.5em;">
                            <div id="projectname">OSR  Register Documentation &#160;<span id="projectnumber">v2.0</span></div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        <div id="navrow1" class="tabs">
            <ul class="tablist">
                <li class="current"><a href="../index.html"><span>Main&#160;Page</span></a></li>
            </ul>
        </div>
    </div>
    <div class="header">
        <div class="headertitle">
            <div class="title">OSR - Audio Decimation (Oversampling Rate Converter)</div>
        </div>
    </div>
    <body>
        <br>
'''

footer = '''
    </body>
</body>
</html>
'''

with open("docs/osr_regs.html", "w") as f:
    f.write(header)
    f.write('        <div class="panel panel-default">\n')
    f.write('            <div class="panel-heading">\n')
    f.write('                <h3 class="panel-title"> OSR Register Index</h3>\n')
    f.write('            </div>\n')
    f.write('            <div class="panel-body">\n')
    f.write('                <table>\n')
    for r in REGS:
        f.write(index_entry(r))
    f.write('                </table>\n')
    f.write('            </div>\n')
    f.write('        </div>\n\n')
    for r in REGS:
        f.write(reg_panel(r))
        f.write('\n')
    f.write(footer)

print(f"Generated docs/osr_regs.html with {len(REGS)} registers")
