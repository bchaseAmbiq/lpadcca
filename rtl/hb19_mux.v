`timescale 1ns / 1ps

module hb19_mux (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        din_valid,
    input  wire signed [17:0] din,
    input  wire [1:0]  mode,
    output reg  signed [17:0] dout,
    output reg         dout_valid
);

localparam signed [15:0] H0  =  16'sd1476;
localparam signed [15:0] H2  = -16'sd1134;
localparam signed [15:0] H4  =  16'sd1759;
localparam signed [15:0] H6  = -16'sd3139;
localparam signed [15:0] H8  =  16'sd9740;
localparam signed [15:0] H9  =  16'sd15367;

reg [2:0] num_stages;
always @(*) begin
    case (mode)
        2'd0:    num_stages = 3'd4;
        2'd1:    num_stages = 3'd3;
        default: num_stages = 3'd2;
    endcase
end

reg signed [17:0] dl0 [0:18];
reg signed [17:0] dl1 [0:18];
reg signed [17:0] dl2 [0:18];
reg signed [17:0] dl3 [0:18];

reg [3:0] ph;

localparam S_IDLE    = 2'd0;
localparam S_PUSH    = 2'd1;
localparam S_COMPUTE = 2'd2;

reg [1:0] state;
reg [1:0] cur_stg;
reg signed [17:0] cur_samp;

reg signed [17:0] rd [0:18];
always @(*) begin : rd_mux
    integer i;
    for (i = 0; i < 19; i = i + 1) begin
        case (cur_stg)
            2'd0:    rd[i] = dl0[i];
            2'd1:    rd[i] = dl1[i];
            2'd2:    rd[i] = dl2[i];
            default: rd[i] = dl3[i];
        endcase
    end
end

wire signed [18:0] s0 = $signed({rd[0][17],  rd[0]})  + $signed({rd[18][17], rd[18]});
wire signed [18:0] s2 = $signed({rd[2][17],  rd[2]})  + $signed({rd[16][17], rd[16]});
wire signed [18:0] s4 = $signed({rd[4][17],  rd[4]})  + $signed({rd[14][17], rd[14]});
wire signed [18:0] s6 = $signed({rd[6][17],  rd[6]})  + $signed({rd[12][17], rd[12]});
wire signed [18:0] s8 = $signed({rd[8][17],  rd[8]})  + $signed({rd[10][17], rd[10]});

wire signed [63:0] mac =
    $signed({{46{rd[9][17]}}, rd[9]}) * $signed({{48{H9[15]}}, H9}) +
    $signed({{45{s0[18]}}, s0})       * $signed({{48{H0[15]}}, H0}) +
    $signed({{45{s2[18]}}, s2})       * $signed({{48{H2[15]}}, H2}) +
    $signed({{45{s4[18]}}, s4})       * $signed({{48{H4[15]}}, H4}) +
    $signed({{45{s6[18]}}, s6})       * $signed({{48{H6[15]}}, H6}) +
    $signed({{45{s8[18]}}, s8})       * $signed({{48{H8[15]}}, H8});

wire signed [63:0] mac_rnd = (mac + 64'sd16384) >>> 15;

integer k;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state    <= S_IDLE;
        cur_stg  <= 2'd0;
        cur_samp <= 18'sd0;
        ph       <= 4'd0;
        dout     <= 18'sd0;
        dout_valid <= 1'b0;
        for (k = 0; k < 19; k = k + 1) begin
            dl0[k] <= 18'sd0;
            dl1[k] <= 18'sd0;
            dl2[k] <= 18'sd0;
            dl3[k] <= 18'sd0;
        end
    end else begin
        dout_valid <= 1'b0;
        case (state)
            S_IDLE: begin
                if (din_valid) begin
                    cur_samp <= din;
                    cur_stg  <= 2'd0;
                    state    <= S_PUSH;
                end
            end
            S_PUSH: begin
                case (cur_stg)
                    2'd0: begin
                        dl0[0] <= cur_samp;
                        for (k = 1; k < 19; k = k + 1) dl0[k] <= dl0[k-1];
                    end
                    2'd1: begin
                        dl1[0] <= cur_samp;
                        for (k = 1; k < 19; k = k + 1) dl1[k] <= dl1[k-1];
                    end
                    2'd2: begin
                        dl2[0] <= cur_samp;
                        for (k = 1; k < 19; k = k + 1) dl2[k] <= dl2[k-1];
                    end
                    default: begin
                        dl3[0] <= cur_samp;
                        for (k = 1; k < 19; k = k + 1) dl3[k] <= dl3[k-1];
                    end
                endcase
                ph[cur_stg] <= ~ph[cur_stg];
                if (!ph[cur_stg]) begin
                    state <= S_IDLE;
                end else begin
                    state <= S_COMPUTE;
                end
            end
            S_COMPUTE: begin
                cur_samp <= $signed(mac_rnd[17:0]);
                if ({1'b0, cur_stg} == num_stages - 3'd1) begin
                    dout       <= $signed(mac_rnd[17:0]);
                    dout_valid <= 1'b1;
                    state      <= S_IDLE;
                end else begin
                    cur_stg <= cur_stg + 2'd1;
                    state   <= S_PUSH;
                end
            end
            default: state <= S_IDLE;
        endcase
    end
end

endmodule
