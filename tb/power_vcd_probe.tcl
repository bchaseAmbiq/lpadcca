database -open power_vcd -vcd -into power.vcd -default
probe -create u_dut -all -depth all -database power_vcd
run
exit
