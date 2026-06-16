module tb_async_fifo;

    parameter DATA_WIDTH = 8;
    parameter DEPTH      = 8;

    logic                  wr_clk;
    logic                  rd_clk;
    logic                  rst_n;
    logic                  wr_en;
    logic                  rd_en;
    logic [DATA_WIDTH-1:0] data_in;
    logic [DATA_WIDTH-1:0] data_out;
    logic                  full;
    logic                  empty;

    //--------------------------------------------------
    // DUT Instantiation
    //--------------------------------------------------
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH     (DEPTH)
    ) dut (
        .wr_clk  (wr_clk),
        .rd_clk  (rd_clk),
        .rst_n   (rst_n),
        .wr_en   (wr_en),
        .rd_en   (rd_en),
        .data_in (data_in),
        .data_out(data_out),
        .full    (full),
        .empty   (empty)
    );

    //--------------------------------------------------
    // Write Clock: 10 ns period (100 MHz)
    //--------------------------------------------------
    initial wr_clk = 0;
    always #5 wr_clk = ~wr_clk;

    //--------------------------------------------------
    // Read Clock: 14 ns period (~71 MHz)
    //--------------------------------------------------
    initial rd_clk = 0;
    always #7 rd_clk = ~rd_clk;

    //--------------------------------------------------
    // Timeout Watchdog
    //--------------------------------------------------
    initial begin
        #10000;
        $display("TIMEOUT - simulation hung at %0t", $time);
        $finish;
    end

    //--------------------------------------------------
    // Test Sequence
    //--------------------------------------------------
    initial begin

        // Initialise all inputs
        rst_n   = 0;
        wr_en   = 0;
        rd_en   = 0;
        data_in = 8'h00;

        // Hold reset for two full write-clock cycles
        @(posedge wr_clk);
        @(posedge wr_clk);
        #1;
        rst_n = 1;
        $display("TIME=%0t | Reset released", $time);

        //----------------------------------------------
        // WRITE PHASE - write 8 bytes (0x01 to 0x08)
        //----------------------------------------------
        repeat (8) begin
            @(posedge wr_clk); #1;
            if (!full) begin
                wr_en   = 1;
                data_in = data_in + 1;
                $display("TIME=%0t | WRITE data_in=0x%02h", $time, data_in);
            end
            @(posedge wr_clk); #1;
            wr_en = 0;
        end

        $display("TIME=%0t | Write phase done. Waiting for CDC propagation...", $time);

        // Wait for write pointer to propagate through 2FF synchronizer
        repeat (20) @(posedge rd_clk);

        $display("TIME=%0t | Starting read phase. empty=%b", $time, empty);

        //----------------------------------------------
        // READ PHASE - read all 8 bytes
        //----------------------------------------------
        repeat (8) begin
            @(posedge rd_clk); #1;
            if (!empty) begin
                rd_en = 1;
                $display("TIME=%0t | READ  data_out=0x%02h", $time, data_out);
            end
            @(posedge rd_clk); #1;
            rd_en = 0;
        end

        // Let waveform settle
        repeat (4) @(posedge rd_clk);

        $display("TIME=%0t | Simulation complete. full=%b empty=%b", $time, full, empty);
        $finish;
    end

    //--------------------------------------------------
    // Monitor
    //--------------------------------------------------
    initial begin
        $monitor(
            "TIME=%0t | wr_en=%b rd_en=%b data_in=0x%02h data_out=0x%02h full=%b empty=%b",
            $time,
            wr_en, rd_en,
            data_in, data_out,
            full, empty
        );
    end

    //--------------------------------------------------
    // Waveform Dump
    //--------------------------------------------------
    initial begin
        $dumpfile("async_fifo_tb.vcd");
        $dumpvars(0, tb_async_fifo);
    end

endmodule
