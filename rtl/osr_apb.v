`timescale 1ns / 1ps
// ============================================================================
// osr_apb.v — APB3 slave wrapper for osr_top with 16-deep output FIFO
//
// Register map (byte offsets):
//   0x00 CTRL         RW     [1:0] mode, [2] enable, [7:4] dga_shift
//   0x04 DGA_FRAC     RW     [16:0] dga_frac_q16
//   0x08 FIFO_STATUS  RO/W1C [0]empty [1]half [2]full [3]ovf [7:4]count
//   0x0C FIFO_DATA    RO     pop & return top entry (sign-extended 32b)
//   0x10 INTEN        RW     [3:0] per-flag interrupt enable
//   0x14 INTSTAT      RO     [3:0] raw flag status
//   0x18 INTCLR       W1C    [3:0] clear sticky flags (OVF)
//   0x1C FIFO_THRESH  RW     [3:0] half-full threshold (default 8)
//   0x20 FIFO_FLUSH   WO     [0] write 1 to flush FIFO
//   0x24 ID           RO     32'hA05B_0002
//
// Interrupt: irq = |(INTSTAT[3:0] & INTEN[3:0])
//   Bit 0 = EMPTY, 1 = HALF, 2 = FULL, 3 = OVF
//
// Clock domains:
//   PCLK    — APB bus, register file, FIFO
//   clk_adc — osr_top core
// ============================================================================

module osr_apb (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [7:0]  PADDR,
    input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,

    input  wire        clk_adc,
    input  wire        eoc,
    input  wire [11:0] adc_data,

    output wire        irq
);

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    // ----------------------------------------------------------------
    // Address map
    // ----------------------------------------------------------------
    localparam [7:0] ADDR_CTRL        = 8'h00,
                     ADDR_DGA_FRAC    = 8'h04,
                     ADDR_FIFO_STATUS = 8'h08,
                     ADDR_FIFO_DATA   = 8'h0C,
                     ADDR_INTEN       = 8'h10,
                     ADDR_INTSTAT     = 8'h14,
                     ADDR_INTCLR      = 8'h18,
                     ADDR_FIFO_THRESH = 8'h1C,
                     ADDR_FIFO_FLUSH  = 8'h20,
                     ADDR_ID          = 8'h24;

    localparam [31:0] IP_ID = 32'hA05B_0002;

    wire apb_wr = PSEL & PENABLE & PWRITE;
    wire apb_rd = PSEL & PENABLE & ~PWRITE;

    // ----------------------------------------------------------------
    // PCLK-domain config registers
    // ----------------------------------------------------------------
    reg [1:0]        reg_mode;
    reg              reg_enable;
    reg signed [3:0] reg_dga_shift;
    reg [16:0]       reg_dga_frac;
    reg [3:0]        reg_inten;
    reg [3:0]        reg_fifo_thresh;

    // ----------------------------------------------------------------
    // CDC: data_valid pulse clk_adc → PCLK (toggle synchroniser)
    // ----------------------------------------------------------------
    wire              core_data_valid;
    wire signed [15:0] core_data_out;

    reg               dv_toggle_adc;
    reg signed [15:0] data_hold_adc;
    reg               dv_sync1, dv_sync2, dv_sync3;

    always @(posedge clk_adc or negedge PRESETn) begin
        if (!PRESETn) begin
            dv_toggle_adc <= 1'b0;
            data_hold_adc <= 16'sd0;
        end else if (core_data_valid) begin
            dv_toggle_adc <= ~dv_toggle_adc;
            data_hold_adc <= core_data_out;
        end
    end

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            dv_sync1 <= 1'b0;
            dv_sync2 <= 1'b0;
            dv_sync3 <= 1'b0;
        end else begin
            dv_sync1 <= dv_toggle_adc;
            dv_sync2 <= dv_sync1;
            dv_sync3 <= dv_sync2;
        end
    end

    wire new_sample_pclk = dv_sync2 ^ dv_sync3;

    reg signed [15:0] data_hold_pclk;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            data_hold_pclk <= 16'sd0;
        else if (new_sample_pclk)
            data_hold_pclk <= data_hold_adc;
    end

    // ----------------------------------------------------------------
    // FIFO instance (PCLK domain)
    // ----------------------------------------------------------------
    wire        fifo_rd_en = apb_rd & (PADDR == ADDR_FIFO_DATA);
    wire        fifo_flush;
    wire signed [15:0] fifo_rd_data;
    wire        fifo_empty, fifo_half, fifo_full;
    wire [4:0]  fifo_count;

    osr_fifo u_fifo (
        .clk     (PCLK),
        .rst_n   (PRESETn),
        .wr_en   (new_sample_pclk),
        .wr_data (data_hold_pclk),
        .rd_en   (fifo_rd_en),
        .rd_data (fifo_rd_data),
        .flush   (fifo_flush),
        .thresh  (reg_fifo_thresh),
        .empty   (fifo_empty),
        .half    (fifo_half),
        .full    (fifo_full),
        .count   (fifo_count)
    );

    // ----------------------------------------------------------------
    // Overflow (sticky, W1C via INTCLR[3] or FIFO_STATUS write)
    // ----------------------------------------------------------------
    reg reg_ovf;
    wire intclr_wr = apb_wr & (PADDR == ADDR_INTCLR);
    wire status_wr = apb_wr & (PADDR == ADDR_FIFO_STATUS);

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            reg_ovf <= 1'b0;
        else if (fifo_flush)
            reg_ovf <= 1'b0;
        else if ((intclr_wr && PWDATA[3]) || (status_wr && PWDATA[3]))
            reg_ovf <= 1'b0;
        else if (new_sample_pclk && fifo_full)
            reg_ovf <= 1'b1;
    end

    // ----------------------------------------------------------------
    // FIFO flush
    // ----------------------------------------------------------------
    reg reg_flush;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            reg_flush <= 1'b0;
        else if (apb_wr && PADDR == ADDR_FIFO_FLUSH && PWDATA[0])
            reg_flush <= 1'b1;
        else
            reg_flush <= 1'b0;
    end
    assign fifo_flush = reg_flush;

    // ----------------------------------------------------------------
    // Interrupt logic
    // ----------------------------------------------------------------
    wire [3:0] int_flags = {reg_ovf, fifo_full, fifo_half, fifo_empty};

    assign irq = |(int_flags & reg_inten);

    // ----------------------------------------------------------------
    // APB register writes
    // ----------------------------------------------------------------
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            reg_mode        <= 2'd0;
            reg_enable      <= 1'b0;
            reg_dga_shift   <= 4'sd0;
            reg_dga_frac    <= 17'd0;
            reg_inten       <= 4'd0;
            reg_fifo_thresh <= 4'd8;
        end else if (apb_wr) begin
            case (PADDR)
                ADDR_CTRL: begin
                    reg_mode      <= PWDATA[1:0];
                    reg_enable    <= PWDATA[2];
                    reg_dga_shift <= $signed(PWDATA[7:4]);
                end
                ADDR_DGA_FRAC:    reg_dga_frac    <= PWDATA[16:0];
                ADDR_INTEN:       reg_inten       <= PWDATA[3:0];
                ADDR_FIFO_THRESH: reg_fifo_thresh <= PWDATA[3:0];
                default: ;
            endcase
        end
    end

    // ----------------------------------------------------------------
    // APB register reads
    // ----------------------------------------------------------------
    always @(*) begin
        case (PADDR)
            ADDR_CTRL:        PRDATA = {24'd0, reg_dga_shift,
                                        1'b0, reg_enable, reg_mode};
            ADDR_DGA_FRAC:    PRDATA = {15'd0, reg_dga_frac};
            ADDR_FIFO_STATUS: PRDATA = {24'd0,
                                        fifo_count[3:0],
                                        reg_ovf, fifo_full,
                                        fifo_half, fifo_empty};
            ADDR_FIFO_DATA:   PRDATA = {{16{fifo_rd_data[15]}},
                                        fifo_rd_data};
            ADDR_INTEN:       PRDATA = {28'd0, reg_inten};
            ADDR_INTSTAT:     PRDATA = {28'd0, int_flags};
            ADDR_INTCLR:      PRDATA = 32'd0;
            ADDR_FIFO_THRESH: PRDATA = {28'd0, reg_fifo_thresh};
            ADDR_FIFO_FLUSH:  PRDATA = 32'd0;
            ADDR_ID:          PRDATA = IP_ID;
            default:          PRDATA = 32'd0;
        endcase
    end

    // ----------------------------------------------------------------
    // CDC: config PCLK → clk_adc (2-FF, quasi-static)
    // ----------------------------------------------------------------
    reg [1:0]        mode_sync1,      mode_sync2;
    reg signed [3:0] dga_shift_sync1, dga_shift_sync2;
    reg [16:0]       dga_frac_sync1,  dga_frac_sync2;
    reg              enable_sync1,    enable_sync2;

    always @(posedge clk_adc or negedge PRESETn) begin
        if (!PRESETn) begin
            mode_sync1      <= 2'd0;
            mode_sync2      <= 2'd0;
            dga_shift_sync1 <= 4'sd0;
            dga_shift_sync2 <= 4'sd0;
            dga_frac_sync1  <= 17'd0;
            dga_frac_sync2  <= 17'd0;
            enable_sync1    <= 1'b0;
            enable_sync2    <= 1'b0;
        end else begin
            mode_sync1      <= reg_mode;
            mode_sync2      <= mode_sync1;
            dga_shift_sync1 <= reg_dga_shift;
            dga_shift_sync2 <= dga_shift_sync1;
            dga_frac_sync1  <= reg_dga_frac;
            dga_frac_sync2  <= dga_frac_sync1;
            enable_sync1    <= reg_enable;
            enable_sync2    <= enable_sync1;
        end
    end

    wire core_rst_n = PRESETn & enable_sync2;

    // ----------------------------------------------------------------
    // osr_top (clk_adc domain)
    // ----------------------------------------------------------------
    osr_top u_osr_top (
        .clk          (clk_adc),
        .rst_n        (core_rst_n),
        .eoc          (eoc),
        .adc_data     (adc_data),
        .mode         (mode_sync2),
        .dga_shift    (dga_shift_sync2),
        .dga_frac_q16 (dga_frac_sync2),
        .data_out     (core_data_out),
        .data_valid   (core_data_valid)
    );

endmodule
