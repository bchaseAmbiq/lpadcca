`timescale 1ns / 1ps

/*
 * dump_rtl_vectors.sv — Bit-exact RTL vector dump testbench.
 *
 * Reads stimulus from "stim.txt" (one signed 12-bit integer per line),
 * drives each value into osr_top via adc_data/eoc with the same timing
 * as the main osr_tb.sv push_adc_sample task, and writes every data_valid
 * output sample ($signed(data_out)) to "rtl_out.txt" (one integer per line).
 *
 * Plusargs:
 *   +MODE=0        OSR mode (0=NB, 1=WB, 2=SWB)
 *   +DGA_SHIFT=-3  DGA barrel-shift exponent (signed)
 *   +DGA_FRAC=130637  DGA Q16 fractional multiplier
 *   +STIM_FILE=stim.txt   stimulus input file
 *   +RTL_OUT=rtl_out.txt  RTL output file
 */

module dump_rtl_vectors;

localparam real CLK_PERIOD = 325.52;  // 3.072 MHz

reg         clk;
reg         rst_n;
reg         eoc;
reg  [11:0] adc_data;
reg  [1:0]  mode;
reg  signed [3:0]  dga_shift;
reg  [16:0] dga_frac_q16;
wire signed [15:0] data_out;
wire        data_valid;

osr_top u_dut (
    .clk           (clk),
    .rst_n         (rst_n),
    .eoc           (eoc),
    .adc_data      (adc_data),
    .mode          (mode),
    .dga_shift     (dga_shift),
    .dga_frac_q16  (dga_frac_q16),
    .data_out      (data_out),
    .data_valid    (data_valid)
);

initial clk = 1'b0;
always #(CLK_PERIOD/2.0) clk = ~clk;

/* ------ Plusarg parsing ------ */
integer pa_mode, pa_shift, pa_frac;
string stim_file, out_file;

initial begin
    if (!$value$plusargs("MODE=%d", pa_mode))     pa_mode  = 0;
    if (!$value$plusargs("DGA_SHIFT=%d", pa_shift)) pa_shift = -3;
    if (!$value$plusargs("DGA_FRAC=%d", pa_frac))   pa_frac  = 130637;
    if (!$value$plusargs("STIM_FILE=%s", stim_file)) stim_file = "stim.txt";
    if (!$value$plusargs("RTL_OUT=%s", out_file))     out_file  = "rtl_out.txt";
end

/* ------ push_adc_sample — identical timing to osr_tb.sv ------ */
task push_adc_sample(input signed [11:0] samp);
begin
    @(negedge clk);
    adc_data = samp[11:0];
    eoc = 1'b1;
    @(negedge clk);
    eoc = 1'b0;
    @(posedge clk);
end
endtask

/* ------ reset ------ */
task do_reset;
begin
    rst_n    = 1'b0;
    eoc      = 1'b0;
    adc_data = 12'd0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
end
endtask

/* ------ Output capture (runs in parallel) ------ */
integer out_fd;
integer out_count;

initial begin
    out_count = 0;
    // Wait for reset to complete
    @(posedge rst_n);
    forever begin
        @(posedge clk);
        if (data_valid) begin
            $fwrite(out_fd, "%0d\n", $signed(data_out));
            out_count = out_count + 1;
        end
    end
end

/* ------ Main stimulus ------ */
integer stim_fd;
integer scan_ret;
integer sval;
integer stim_count;

initial begin
    // Wait for plusargs to be parsed (they're in the same initial block above,
    // but we need a small delay so the string values are ready)
    #1;

    mode         = pa_mode[1:0];
    dga_shift    = $signed(pa_shift[3:0]);
    dga_frac_q16 = pa_frac[16:0];

    $display("dump_rtl_vectors: MODE=%0d  DGA_SHIFT=%0d  DGA_FRAC=%0d",
             pa_mode, pa_shift, pa_frac);
    $display("dump_rtl_vectors: stim=%s  out=%s", stim_file, out_file);

    do_reset();

    /* Open output file */
    out_fd = $fopen(out_file, "w");
    if (out_fd == 0) begin
        $display("ERROR: cannot open output file %s", out_file);
        $finish;
    end

    /* Open stimulus file */
    stim_fd = $fopen(stim_file, "r");
    if (stim_fd == 0) begin
        $display("ERROR: cannot open stimulus file %s", stim_file);
        $finish;
    end

    stim_count = 0;
    while (!$feof(stim_fd)) begin
        scan_ret = $fscanf(stim_fd, "%d", sval);
        if (scan_ret != 1) begin
            // Skip blank/comment lines or EOF
            if (!$feof(stim_fd)) begin
                // Try to advance past bad line
                scan_ret = $fscanf(stim_fd, "%*[^\n]\n");
            end
        end else begin
            push_adc_sample($signed(sval[11:0]));
            stim_count = stim_count + 1;
        end
    end
    $fclose(stim_fd);

    /* Flush pipeline: run a few thousand extra clocks */
    repeat (8000) @(posedge clk);

    $fclose(out_fd);
    $display("dump_rtl_vectors: %0d stim samples -> %0d output samples",
             stim_count, out_count);
    $finish;
end

endmodule
