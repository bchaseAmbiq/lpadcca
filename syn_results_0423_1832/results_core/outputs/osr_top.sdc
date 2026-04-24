# ####################################################################

#  Created by Genus(TM) Synthesis Solution 23.12-s086_1 on Thu Apr 23 20:38:47 CDT 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design osr_top

create_clock -name "clk" -period 325.52083 -waveform {0.0 162.760415} [get_ports clk]
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports rst_n]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports eoc]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {adc_data[11]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {adc_data[10]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {adc_data[9]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {adc_data[8]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {adc_data[7]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {adc_data[6]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {adc_data[5]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {adc_data[4]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {adc_data[3]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {adc_data[2]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {adc_data[1]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {adc_data[0]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {mode[1]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {mode[0]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_shift[3]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_shift[2]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_shift[1]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_shift[0]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[16]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[15]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[14]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[13]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[12]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[11]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[10]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[9]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[8]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[7]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[6]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[5]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[4]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[3]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[2]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[1]}]
set_input_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {dga_frac_q16[0]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[15]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[14]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[13]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[12]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[11]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[10]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[9]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[8]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[7]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[6]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[5]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[4]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[3]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[2]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[1]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports {data_out[0]}]
set_output_delay -clock [get_clocks clk] -add_delay 65.1042 [get_ports data_valid]
set_dont_touch_network [get_ports clk]
set_dont_touch_network [get_ports rst_n]
set_wire_load_mode "enclosed"
set_clock_uncertainty -setup 0.1 [get_clocks clk]
set_clock_uncertainty -hold 0.1 [get_clocks clk]
