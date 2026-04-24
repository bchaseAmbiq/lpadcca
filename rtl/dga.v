`timescale 1ns / 1ps

module dga (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        din_valid,
    input  wire signed [17:0] din,
    input  wire signed [3:0]  dga_shift,
    input  wire [16:0] dga_frac_q16,
    output reg  signed [17:0] dout,
    output reg         dout_valid
);

wire signed [35:0] frac_prod = $signed(din) * $signed({1'b0, dga_frac_q16});
wire signed [17:0] frac_out  = $signed(frac_prod[33:16]);

reg signed [17:0] shifted;
always @(*) begin
    case (dga_shift)
        -4'sd8:  shifted = frac_out >>> 8;
        -4'sd7:  shifted = frac_out >>> 7;
        -4'sd6:  shifted = frac_out >>> 6;
        -4'sd5:  shifted = frac_out >>> 5;
        -4'sd4:  shifted = frac_out >>> 4;
        -4'sd3:  shifted = frac_out >>> 3;
        -4'sd2:  shifted = frac_out >>> 2;
        -4'sd1:  shifted = frac_out >>> 1;
        4'sd0:   shifted = frac_out;
        4'sd1:   shifted = frac_out <<< 1;
        4'sd2:   shifted = frac_out <<< 2;
        4'sd3:   shifted = frac_out <<< 3;
        4'sd4:   shifted = frac_out <<< 4;
        4'sd5:   shifted = frac_out <<< 5;
        4'sd6:   shifted = frac_out <<< 6;
        4'sd7:   shifted = frac_out <<< 7;
        default: shifted = frac_out;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= 18'sd0;
        dout_valid <= 1'b0;
    end else begin
        dout_valid <= 1'b0;
        if (din_valid) begin
            dout <= shifted;
            dout_valid <= 1'b1;
        end
    end
end

endmodule
