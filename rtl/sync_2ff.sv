module sync_2ff #(
    parameter SIZE = 4
)(
    input  logic            clk,
    input  logic            rst_n,
    input  logic [SIZE-1:0] async_in,
    output logic [SIZE-1:0] sync_out
);

    logic [SIZE-1:0] sync_ff1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= '0;
            sync_out <= '0;
        end else begin
            sync_ff1 <= async_in;
            sync_out <= sync_ff1;
        end
    end

endmodule
