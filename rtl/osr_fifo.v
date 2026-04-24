`timescale 1ns / 1ps

module osr_fifo (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        wr_en,
    input  wire signed [15:0] wr_data,
    input  wire        rd_en,
    output wire signed [15:0] rd_data,
    input  wire        flush,
    input  wire [3:0]  thresh,
    output wire        empty,
    output wire        half,
    output wire        full,
    output wire [4:0]  count
);

    localparam DEPTH = 16;
    localparam AW    = 4;

    reg signed [15:0] mem [0:DEPTH-1];
    reg [AW:0] wr_ptr;
    reg [AW:0] rd_ptr;

    wire [AW:0] cnt = wr_ptr - rd_ptr;

    assign count = cnt;
    assign empty = (cnt == 5'd0);
    assign full  = (cnt == DEPTH[4:0]);
    assign half  = (cnt >= {1'b0, thresh});
    assign rd_data = mem[rd_ptr[AW-1:0]];

    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= {(AW+1){1'b0}};
            rd_ptr <= {(AW+1){1'b0}};
            for (k = 0; k < DEPTH; k = k + 1)
                mem[k] <= 16'sd0;
        end else if (flush) begin
            wr_ptr <= {(AW+1){1'b0}};
            rd_ptr <= {(AW+1){1'b0}};
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr[AW-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

endmodule
