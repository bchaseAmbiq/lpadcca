`timescale 1ns / 1ps

module osr_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        eoc,
    input  wire [11:0] adc_data,
    input  wire [1:0]  mode,
    input  wire signed [3:0]  dga_shift,
    input  wire [16:0] dga_frac_q16,
    output wire signed [15:0] data_out,
    output wire        data_valid
);

reg signed [15:0] hpf_alpha_q15;
always @(*) begin
    case (mode)
        2'd0:    hpf_alpha_q15 = 16'sd27999;
        2'd1:    hpf_alpha_q15 = 16'sd30893;
        default: hpf_alpha_q15 = 16'sd31817;
    endcase
end

wire [11:0] cap_data;
wire        cap_valid;

adc_capture u_adc_capture (
    .clk       (clk),
    .rst_n     (rst_n),
    .eoc       (eoc),
    .adc_data  (adc_data),
    .data_out  (cap_data),
    .data_valid(cap_valid)
);

wire signed [17:0] cic_out;
wire        cic_valid;

cic_filter u_cic (
    .clk       (clk),
    .rst_n     (rst_n),
    .din_valid (cap_valid),
    .din       ($signed(cap_data)),
    .dout      (cic_out),
    .dout_valid(cic_valid)
);

wire signed [17:0] hb1_out;
wire        hb1_valid;

hb1_fir u_hb1 (
    .clk       (clk),
    .rst_n     (rst_n),
    .din_valid (cic_valid),
    .din       (cic_out),
    .dout      (hb1_out),
    .dout_valid(hb1_valid)
);

wire signed [17:0] hb19_out;
wire        hb19_valid;

hb19_mux u_hb19 (
    .clk       (clk),
    .rst_n     (rst_n),
    .din_valid (hb1_valid),
    .din       (hb1_out),
    .mode      (mode),
    .dout      (hb19_out),
    .dout_valid(hb19_valid)
);

wire signed [17:0] lpf_out;
wire        lpf_valid;

lpf_fir u_lpf (
    .clk       (clk),
    .rst_n     (rst_n),
    .din_valid (hb19_valid),
    .din       (hb19_out),
    .mode      (mode),
    .dout      (lpf_out),
    .dout_valid(lpf_valid)
);

wire signed [17:0] dga_out;
wire        dga_valid;

dga u_dga (
    .clk          (clk),
    .rst_n        (rst_n),
    .din_valid    (lpf_valid),
    .din          (lpf_out),
    .dga_shift    (dga_shift),
    .dga_frac_q16 (dga_frac_q16),
    .dout         (dga_out),
    .dout_valid   (dga_valid)
);

hpf u_hpf (
    .clk       (clk),
    .rst_n     (rst_n),
    .din_valid (dga_valid),
    .din       (dga_out),
    .alpha_q15 (hpf_alpha_q15),
    .dout      (data_out),
    .dout_valid(data_valid)
);

endmodule
