`timescale 1ns / 1ps

module lpf_fir (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        din_valid,
    input  wire signed [17:0] din,
    input  wire [1:0]  mode,
    output reg  signed [17:0] dout,
    output reg         dout_valid
);

localparam TAPS = 21;
localparam MID  = 10;

reg signed [17:0] dl [0:20];
reg [3:0] cyc;
reg        busy;
reg signed [63:0] acc;

reg signed [15:0] coef_rd;
always @(*) begin
    coef_rd = 16'sd0;
    case ({mode, cyc})
        {2'd0, 4'd0}:  coef_rd =  16'sd83;
        {2'd0, 4'd1}:  coef_rd = -16'sd106;
        {2'd0, 4'd2}:  coef_rd =  16'sd129;
        {2'd0, 4'd3}:  coef_rd = -16'sd63;
        {2'd0, 4'd4}:  coef_rd = -16'sd213;
        {2'd0, 4'd5}:  coef_rd =  16'sd797;
        {2'd0, 4'd6}:  coef_rd = -16'sd1692;
        {2'd0, 4'd7}:  coef_rd =  16'sd2782;
        {2'd0, 4'd8}:  coef_rd = -16'sd3843;
        {2'd0, 4'd9}:  coef_rd =  16'sd4630;
        {2'd0, 4'd10}: coef_rd =  16'sd27853;
        {2'd1, 4'd0}:  coef_rd =  16'sd59;
        {2'd1, 4'd1}:  coef_rd = -16'sd45;
        {2'd1, 4'd2}:  coef_rd =  16'sd0;
        {2'd1, 4'd3}:  coef_rd =  16'sd154;
        {2'd1, 4'd4}:  coef_rd = -16'sd489;
        {2'd1, 4'd5}:  coef_rd =  16'sd1040;
        {2'd1, 4'd6}:  coef_rd = -16'sd1780;
        {2'd1, 4'd7}:  coef_rd =  16'sd2600;
        {2'd1, 4'd8}:  coef_rd = -16'sd3366;
        {2'd1, 4'd9}:  coef_rd =  16'sd3899;
        {2'd1, 4'd10}: coef_rd =  16'sd28672;
        {2'd2, 4'd0}:  coef_rd = -16'sd79;
        {2'd2, 4'd1}:  coef_rd =  16'sd118;
        {2'd2, 4'd2}:  coef_rd = -16'sd218;
        {2'd2, 4'd3}:  coef_rd =  16'sd389;
        {2'd2, 4'd4}:  coef_rd = -16'sd626;
        {2'd2, 4'd5}:  coef_rd =  16'sd911;
        {2'd2, 4'd6}:  coef_rd = -16'sd1218;
        {2'd2, 4'd7}:  coef_rd =  16'sd1508;
        {2'd2, 4'd8}:  coef_rd = -16'sd1751;
        {2'd2, 4'd9}:  coef_rd =  16'sd1910;
        {2'd2, 4'd10}: coef_rd =  16'sd30802;
        default:        coef_rd =  16'sd0;
    endcase
end

wire [4:0] cyc_mir = TAPS[4:0] - 5'd1 - {1'b0, cyc};
wire signed [18:0] preadd = (cyc < MID[3:0]) ?
    ($signed({dl[cyc][17], dl[cyc]}) + $signed({dl[cyc_mir][17], dl[cyc_mir]})) :
    $signed({dl[MID][17], dl[MID]});

wire signed [63:0] prod = $signed({{45{preadd[18]}}, preadd}) *
                          $signed({{48{coef_rd[15]}}, coef_rd});

integer j;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (j = 0; j < TAPS; j = j + 1)
            dl[j] <= 18'sd0;
        cyc  <= 4'd0;
        busy <= 1'b0;
        acc  <= 64'sd0;
        dout <= 18'sd0;
        dout_valid <= 1'b0;
    end else begin
        dout_valid <= 1'b0;
        if (!busy) begin
            if (din_valid) begin
                dl[0] <= din;
                for (j = 1; j < TAPS; j = j + 1)
                    dl[j] <= dl[j-1];
                cyc  <= 4'd0;
                acc  <= 64'sd0;
                busy <= 1'b1;
            end
        end else begin
            acc <= acc + prod;
            if (cyc == MID[3:0]) begin
                busy <= 1'b0;
                dout_valid <= 1'b1;
                begin : rnd_out
                    reg signed [63:0] final_acc;
                    final_acc = acc + prod;
                    final_acc = (final_acc + 64'sd16384) >>> 15;
                    dout <= $signed(final_acc[17:0]);
                end
            end else begin
                cyc <= cyc + 4'd1;
            end
        end
    end
end

endmodule
