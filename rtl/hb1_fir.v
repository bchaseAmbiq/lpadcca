`timescale 1ns / 1ps

module hb1_fir (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        din_valid,
    input  wire signed [17:0] din,
    output reg  signed [17:0] dout,
    output reg         dout_valid
);

localparam signed [15:0] H0 =  16'sd3164;
localparam signed [15:0] H2 = -16'sd2941;
localparam signed [15:0] H4 =  16'sd9040;
localparam signed [15:0] H5 =  16'sd14246;

reg signed [17:0] dl [0:10];
reg phase;

wire signed [18:0] s0 = $signed({dl[0][17], dl[0]}) + $signed({dl[10][17], dl[10]});
wire signed [18:0] s2 = $signed({dl[2][17], dl[2]}) + $signed({dl[8][17],  dl[8]});
wire signed [18:0] s4 = $signed({dl[4][17], dl[4]}) + $signed({dl[6][17],  dl[6]});

wire signed [63:0] mac =
    $signed({{46{dl[5][17]}}, dl[5]}) * $signed({{48{H5[15]}}, H5}) +
    $signed({{45{s0[18]}}, s0})       * $signed({{48{H0[15]}}, H0}) +
    $signed({{45{s2[18]}}, s2})       * $signed({{48{H2[15]}}, H2}) +
    $signed({{45{s4[18]}}, s4})       * $signed({{48{H4[15]}}, H4});

wire signed [63:0] mac_rnd = (mac + 64'sd16384) >>> 15;

integer k;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 0; k < 11; k = k + 1)
            dl[k] <= 18'sd0;
    end else if (din_valid) begin
        dl[0] <= din;
        for (k = 1; k < 11; k = k + 1)
            dl[k] <= dl[k-1];
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phase <= 1'b0;
        dout <= 18'sd0;
        dout_valid <= 1'b0;
    end else begin
        dout_valid <= 1'b0;
        if (din_valid) begin
            phase <= ~phase;
            if (phase) begin
                dout_valid <= 1'b1;
                dout <= $signed(mac_rnd[17:0]);
            end
        end
    end
end

endmodule
