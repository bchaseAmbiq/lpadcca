##############################################################################
# Genus Synthesis Script — osr_apb (full APB wrapper with FIFO)
#
# BEFORE RUNNING: Edit the TECHNOLOGY SETUP section below to point to
# your Liberty (.lib) and LEF files.
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

set DESIGN    osr_apb
set RTL_PATH  "../rtl"

read_hdl -v2001 \
    $RTL_PATH/adc_capture.v \
    $RTL_PATH/cic_filter.v \
    $RTL_PATH/hb1_fir.v \
    $RTL_PATH/hb19_mux.v \
    $RTL_PATH/lpf_fir.v \
    $RTL_PATH/dga.v \
    $RTL_PATH/hpf.v \
    $RTL_PATH/osr_top.v \
    $RTL_PATH/osr_fifo.v \
    $RTL_PATH/osr_apb.v

elaborate $DESIGN

# Two clock domains
set PCLK_FREQ  50.0
set PCLK_PER   [expr {1000.0 / $PCLK_FREQ}]
set ADC_FREQ   3.072
set ADC_PER    [expr {1000.0 / $ADC_FREQ}]

create_clock -name PCLK    -period $PCLK_PER [get_ports PCLK]
create_clock -name clk_adc -period $ADC_PER  [get_ports clk_adc]
set_clock_uncertainty 0.1 [get_clocks PCLK]
set_clock_uncertainty 0.1 [get_clocks clk_adc]
set_clock_groups -asynchronous -group {PCLK} -group {clk_adc}

set_input_delay  -clock PCLK    [expr {$PCLK_PER * 0.2}] [remove_from_collection [all_inputs] {PCLK clk_adc eoc adc_data}]
set_input_delay  -clock clk_adc [expr {$ADC_PER  * 0.2}] [get_ports {eoc adc_data}]
set_output_delay -clock PCLK    [expr {$PCLK_PER * 0.2}] [all_outputs]

set_dont_touch_network [get_ports PCLK]
set_dont_touch_network [get_ports clk_adc]
set_dont_touch_network [get_ports PRESETn]

# Synthesize
set_db optimize_constant_feedback_seqs false
set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium

syn_generic
syn_map
syn_opt

# Reports
report_timing > reports/timing.rpt
report_area   > reports/area.rpt
report_power  > reports/power.rpt
report_gates  > reports/gates.rpt

puts "============================================"
puts "  Synthesis complete for $DESIGN"
puts "  PCLK: $PCLK_FREQ MHz ($PCLK_PER ns)"
puts "  clk_adc: $ADC_FREQ MHz ($ADC_PER ns)"
puts "  See reports/ directory for results"
puts "============================================"

write_hdl > outputs/${DESIGN}_syn.v
write_sdc > outputs/${DESIGN}.sdc

exit
