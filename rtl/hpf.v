`timescale 1ns / 1ps

module hpf (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        din_valid,
    input  wire signed [17:0] din,
    input  wire signed [15:0] alpha_q15,
    output reg  signed [15:0] dout,
    output reg         dout_valid
);

reg signed [17:0] x1;
reg signed [17:0] y1;

wire signed [17:0] y1_ext   = y1;
wire signed [17:0] alp_ext  = $signed({{2{alpha_q15[15]}}, alpha_q15});
wire signed [35:0] fb_prod  = y1_ext * alp_ext;
wire signed [17:0] fb       = $signed(fb_prod[32:15]) + $signed({{17{1'b0}}, fb_prod[14]});

wire signed [17:0] y_raw = (din - x1) + fb;

wire signed [15:0] y_clamp = (y_raw > $signed(18'sd32767))  ? 16'sd32767 :
                              (y_raw < -$signed(18'sd32768)) ? -16'sd32768 :
                              $signed(y_raw[15:0]);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x1   <= 18'sd0;
        y1   <= 18'sd0;
        dout <= 16'sd0;
        dout_valid <= 1'b0;
    end else begin
        dout_valid <= 1'b0;
        if (din_valid) begin
            x1   <= din;
            y1   <= y_raw;
            dout <= y_clamp;
            dout_valid <= 1'b1;
        end
    end
end

endmodule
