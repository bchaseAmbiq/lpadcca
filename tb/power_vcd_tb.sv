`timescale 1ns / 1ps

module power_vcd_tb;

localparam real CLK_PERIOD = 325.52;
localparam real FS_ADC     = 3072000.0;
localparam real PI2        = 6.283185307179586;
localparam integer AMP     = 1449;
localparam real    FREQ    = 1000.0;
localparam integer N_ADC   = 60000;

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

integer adc_cnt, out_cnt;

initial begin
    rst_n    = 1'b0;
    eoc      = 1'b0;
    adc_data = 12'd0;
    mode          = 2'd0;
    dga_shift     = -4'sd3;
    dga_frac_q16  = 17'd130637;

    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    out_cnt = 0;
    for (adc_cnt = 0; adc_cnt < N_ADC; adc_cnt = adc_cnt + 1) begin
        @(negedge clk);
        begin : gen_samp
            real sv;
            integer q;
            sv = $sin(PI2 * FREQ * $itor(adc_cnt) / FS_ADC);
            q  = $rtoi(sv * $itor(AMP));
            if (q >  2047) q =  2047;
            if (q < -2048) q = -2048;
            adc_data = q[11:0];
        end
        eoc = 1'b1;
        @(negedge clk);
        eoc = 1'b0;
        @(posedge clk);
        if (data_valid) out_cnt = out_cnt + 1;
    end

    $display("power_vcd_tb: %0d ADC samples -> %0d output samples", N_ADC, out_cnt);
    $finish;
end

endmodule
