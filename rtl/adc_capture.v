`timescale 1ns / 1ps

module adc_capture (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        eoc,
    input  wire [11:0] adc_data,
    output reg  [11:0] data_out,
    output reg         data_valid
);

reg [11:0] neg_cap;
reg        neg_eoc;

always @(negedge clk or negedge rst_n) begin
    if (!rst_n) begin
        neg_cap <= 12'd0;
        neg_eoc <= 1'b0;
    end else begin
        neg_cap <= adc_data;
        neg_eoc <= eoc;
    end
end

reg [11:0] sync1;
reg        sync1_v;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sync1   <= 12'd0;
        sync1_v <= 1'b0;
        data_out   <= 12'd0;
        data_valid <= 1'b0;
    end else begin
        sync1   <= neg_cap;
        sync1_v <= neg_eoc;
        data_out   <= sync1;
        data_valid <= sync1_v;
    end
end

endmodule
