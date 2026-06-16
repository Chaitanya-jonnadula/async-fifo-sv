module rd_ptr_handler #(
    parameter PTR_WIDTH = 4
)(
    input  logic                 rd_clk,
    input  logic                 rst_n,
    input  logic                 rd_en,
    input  logic [PTR_WIDTH-1:0] wr_ptr_gray_sync,
    output logic [PTR_WIDTH-1:0] rd_ptr_bin,
    output logic [PTR_WIDTH-1:0] rd_ptr_gray,
    output logic                 empty
);

    logic [PTR_WIDTH-1:0] rd_ptr_bin_next;
    logic [PTR_WIDTH-1:0] rd_ptr_gray_next;
    logic                 empty_next;

    // Next Binary Pointer - ternary breaks combinational loop
    always_comb begin
        rd_ptr_bin_next = (rd_en && !empty) ? (rd_ptr_bin + 1) : rd_ptr_bin;
    end

    // Binary to Gray conversion
    assign rd_ptr_gray_next = rd_ptr_bin_next ^ (rd_ptr_bin_next >> 1);

    // Empty Detection
    assign empty_next = (rd_ptr_gray_next == wr_ptr_gray_sync);

    // Sequential Logic
    always_ff @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin  <= '0;
            rd_ptr_gray <= '0;
            empty       <= 1'b1;
        end else begin
            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
            empty       <= empty_next;
        end
    end

endmodule
