module wr_ptr_handler #(
    parameter PTR_WIDTH = 4
)(
    input  logic                 wr_clk,
    input  logic                 rst_n,
    input  logic                 wr_en,
    input  logic [PTR_WIDTH-1:0] rd_ptr_gray_sync,
    output logic [PTR_WIDTH-1:0] wr_ptr_bin,
    output logic [PTR_WIDTH-1:0] wr_ptr_gray,
    output logic                 full
);

    logic [PTR_WIDTH-1:0] wr_ptr_bin_next;
    logic [PTR_WIDTH-1:0] wr_ptr_gray_next;
    logic                 full_next;

    // Next Binary Pointer - ternary breaks combinational loop
    always_comb begin
        wr_ptr_bin_next = (wr_en && !full) ? (wr_ptr_bin + 1) : wr_ptr_bin;
    end

    // Binary to Gray conversion
    assign wr_ptr_gray_next = wr_ptr_bin_next ^ (wr_ptr_bin_next >> 1);

    // Full Detection
    assign full_next = (wr_ptr_gray_next == {
                            ~rd_ptr_gray_sync[PTR_WIDTH-1:PTR_WIDTH-2],
                             rd_ptr_gray_sync[PTR_WIDTH-3:0]
                        });

    // Sequential Logic
    always_ff @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin  <= '0;
            wr_ptr_gray <= '0;
            full        <= 1'b0;
        end else begin
            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
            full        <= full_next;
        end
    end

endmodule
