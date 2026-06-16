module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 8
)(
    input  logic                  wr_clk,
    input  logic                  rd_clk,
    input  logic                  rst_n,
    input  logic                  wr_en,
    input  logic                  rd_en,
    input  logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out,
    output logic                  full,
    output logic                  empty
);

    localparam PTR_WIDTH = $clog2(DEPTH) + 1;

    // FIFO Memory
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Pointer Signals
    logic [PTR_WIDTH-1:0] wr_ptr_bin;
    logic [PTR_WIDTH-1:0] rd_ptr_bin;
    logic [PTR_WIDTH-1:0] wr_ptr_gray;
    logic [PTR_WIDTH-1:0] rd_ptr_gray;

    // Synchronized Pointer Signals
    logic [PTR_WIDTH-1:0] wr_ptr_gray_sync;
    logic [PTR_WIDTH-1:0] rd_ptr_gray_sync;

    // Write Pointer Handler
    wr_ptr_handler #(
        .PTR_WIDTH(PTR_WIDTH)
    ) u_wr_ptr (
        .wr_clk          (wr_clk),
        .rst_n           (rst_n),
        .wr_en           (wr_en),
        .rd_ptr_gray_sync(rd_ptr_gray_sync),
        .wr_ptr_bin      (wr_ptr_bin),
        .wr_ptr_gray     (wr_ptr_gray),
        .full            (full)
    );

    // Read Pointer Handler
    rd_ptr_handler #(
        .PTR_WIDTH(PTR_WIDTH)
    ) u_rd_ptr (
        .rd_clk          (rd_clk),
        .rst_n           (rst_n),
        .rd_en           (rd_en),
        .wr_ptr_gray_sync(wr_ptr_gray_sync),
        .rd_ptr_bin      (rd_ptr_bin),
        .rd_ptr_gray     (rd_ptr_gray),
        .empty           (empty)
    );

    // Write Pointer Synchronizer (wr_clk -> rd_clk)
    sync_2ff #(
        .SIZE(PTR_WIDTH)
    ) u_sync_wr2rd (
        .clk      (rd_clk),
        .rst_n    (rst_n),
        .async_in (wr_ptr_gray),
        .sync_out (wr_ptr_gray_sync)
    );

    // Read Pointer Synchronizer (rd_clk -> wr_clk)
    sync_2ff #(
        .SIZE(PTR_WIDTH)
    ) u_sync_rd2wr (
        .clk      (wr_clk),
        .rst_n    (rst_n),
        .async_in (rd_ptr_gray),
        .sync_out (rd_ptr_gray_sync)
    );

    // Memory Write - synchronous, write clock domain
    always_ff @(posedge wr_clk) begin
        if (wr_en && !full)
            mem[wr_ptr_bin[PTR_WIDTH-2:0]] <= data_in;
    end

    // Memory Read - combinational, no clock delay on data_out
    always_comb begin
        if (rd_en && !empty)
            data_out = mem[rd_ptr_bin[PTR_WIDTH-2:0]];
        else
            data_out = '0;
    end

endmodule
