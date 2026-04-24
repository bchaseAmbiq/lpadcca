##############################################################################
# Genus Synthesis Script — osr_top with VCD-annotated power
#
# Requires: power.vcd in syn/ directory (from power_vcd_tb sim)
##############################################################################

#--- TECHNOLOGY SETUP -------------------------------------------------------
set LIB_ROOT /tech/hardip/12nm/ambiq/fip/v1p0
set CORNER "tt"

if {$CORNER eq "tt"} {
    set _sfx tt0p668v25c
    puts "INFO: Library corner = TT 0.668V 25C (power estimation)"
} else {
    set _sfx ssgnp0p735vm40c
    puts "INFO: Library corner = SS 0.735V -40C (timing signoff)"
}

read_libs [list \
    $LIB_ROOT/BASE/SVT24/ccs_lvf/tcbn12ffcplusbwp6tsa24p96cpd_${_sfx}_ccs_lvf.lib.gz \
    $LIB_ROOT/BASE/LVT24/ccs_lvf/tcbn12ffcplusbwp6tsa24p96cpdlvt_${_sfx}_ccs_lvf.lib.gz \
    $LIB_ROOT/BASE/EHVT24/ccs_lvf/tcbn12ffcplusbwp6tsa24p96cpdehvt_${_sfx}_ccs_lvf.lib.gz \
    $LIB_ROOT/MBFF/SVT24/ccs_lvf/tcbn12ffcplusbwp6tsa24p96cpdmb_${_sfx}_ccs_lvf.lib.gz \
    $LIB_ROOT/PM/SVT24/ccs_lvf/tcbn12ffcplusbwp6tsa24p96cpdpm_power_sw_rechar_${_sfx}_ccs_lvf.lib.gz \
]
#--- END TECHNOLOGY SETUP ---------------------------------------------------

set DESIGN    osr_top
set CLK_NAME  clk
set CLK_FREQ  3.072
set CLK_PER   [expr {1000.0 / $CLK_FREQ}]
set RTL_PATH  "../rtl"

set_db lp_insert_clock_gating true

read_hdl -v2001 \
    $RTL_PATH/adc_capture.v \
    $RTL_PATH/cic_filter.v \
    $RTL_PATH/hb1_fir.v \
    $RTL_PATH/hb19_mux.v \
    $RTL_PATH/lpf_fir.v \
    $RTL_PATH/dga.v \
    $RTL_PATH/hpf.v \
    $RTL_PATH/osr_top.v

elaborate $DESIGN

create_clock -name $CLK_NAME -period $CLK_PER [get_ports $CLK_NAME]
set_clock_uncertainty 0.1 [get_clocks $CLK_NAME]

set_input_delay  -clock $CLK_NAME [expr {$CLK_PER * 0.2}] [all_inputs]
set_output_delay -clock $CLK_NAME [expr {$CLK_PER * 0.2}] [all_outputs]

set_dont_touch_network [get_ports $CLK_NAME]
set_dont_touch_network [get_ports rst_n]

set_db optimize_constant_feedback_seqs false
set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium

syn_generic
syn_map
syn_opt

# Default-toggle power (for comparison)
report_timing > reports/timing.rpt
report_area   > reports/area.rpt
report_power  > reports/power_default.rpt
report_gates  > reports/gates.rpt

# Read VCD for realistic switching activity
if {[file exists "power.vcd"]} {
    puts "INFO: Reading VCD for power annotation..."
    read_stimulus -format vcd -file power.vcd -dut_instance power_vcd_tb/u_dut
    report_power > reports/power_vcd.rpt
    puts "INFO: VCD-annotated power written to reports/power_vcd.rpt"
} else {
    puts "WARNING: power.vcd not found — only default-toggle power available"
}

puts "============================================"
puts "  Synthesis + power analysis complete for $DESIGN"
puts "  Clock: $CLK_FREQ MHz ($CLK_PER ns period)"
puts "  See reports/ for results"
puts "  power_vcd.rpt     = VCD-annotated (realistic)"
puts "  power_default.rpt = default toggle (pessimistic)"
puts "============================================"

write_hdl > outputs/${DESIGN}_syn.v
write_sdc > outputs/${DESIGN}.sdc

exit
