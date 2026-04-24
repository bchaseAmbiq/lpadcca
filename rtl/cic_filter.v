`timescale 1ns / 1ps

module cic_filter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        din_valid,
    input  wire signed [11:0] din,
    output reg  signed [17:0] dout,
    output reg         dout_valid
);

localparam [3:0] R = 4'd12;

reg signed [25:0] i0, i1, i2;
reg [3:0] phase;

reg signed [25:0] c0_z, c1_z, c2_z;

wire signed [25:0] din_ext = $signed({{14{din[11]}}, din});
wire signed [25:0] i0_nxt = i0 + din_ext;
wire signed [25:0] i1_nxt = i1 + i0_nxt;
wire signed [25:0] i2_nxt = i2 + i1_nxt;

wire signed [25:0] d1 = i2_nxt - c0_z;
wire signed [25:0] d2 = d1 - c1_z;
wire signed [25:0] d3 = d2 - c2_z;

wire signed [41:0] norm_prod = $signed(d3) * $signed(16'sd607);
wire signed [41:0] norm_rnd  = (norm_prod + $signed(42'sd524288)) >>> 20;
wire signed [25:0] norm_q11  = $signed(norm_rnd[25:0]);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        i0 <= 26'sd0;
        i1 <= 26'sd0;
        i2 <= 26'sd0;
        phase <= 4'd0;
        c0_z <= 26'sd0;
        c1_z <= 26'sd0;
        c2_z <= 26'sd0;
        dout <= 18'sd0;
        dout_valid <= 1'b0;
    end else begin
        dout_valid <= 1'b0;
        if (din_valid) begin
            i0 <= i0_nxt;
            i1 <= i1_nxt;
            i2 <= i2_nxt;

            if (phase == R - 4'd1) begin
                phase <= 4'd0;
                c0_z <= i2_nxt;
                c1_z <= d1;
                c2_z <= d2;
                dout <= $signed(norm_q11[17:0]) <<< 6;
                dout_valid <= 1'b1;
            end else begin
                phase <= phase + 4'd1;
            end
        end
    end
end

endmodule
