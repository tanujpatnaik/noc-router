module async_fifo #(
    parameter WIDTH = 32,
    parameter DEPTH = 8          
)(
    // write side
    input                    w_clk,
    input                    rst_w_n,      // active-low, asynchronous
    input                    w_en,
    input      [WIDTH-1:0]   w_data,
    output                   full,

    // read side
    input                    r_clk,
    input                    rst_r_n,      // active-low, asynchronous
    input                    r_en,
    output     [WIDTH-1:0]   r_data,
    output                   empty
);

    localparam PTR_WIDTH = $clog2(DEPTH);

    reg [WIDTH-1:0] fifo [0:DEPTH-1];

    reg  [PTR_WIDTH:0] w_ptr_bin, r_ptr_bin;
    wire [PTR_WIDTH:0] w_ptr_gray, r_ptr_gray;

    wire w_fire = w_en && !full;
    wire r_fire = r_en && !empty;

    wire [PTR_WIDTH:0] w_ptr_bin_next = w_ptr_bin + w_fire;
    wire [PTR_WIDTH:0] r_ptr_bin_next = r_ptr_bin + r_fire;

    assign w_ptr_gray = (w_ptr_bin >> 1) ^ w_ptr_bin;
    assign r_ptr_gray = (r_ptr_bin >> 1) ^ r_ptr_bin;

    wire [PTR_WIDTH:0] w_ptr_gray_next = (w_ptr_bin_next >> 1) ^ w_ptr_bin_next;
    wire [PTR_WIDTH:0] r_ptr_gray_next = (r_ptr_bin_next >> 1) ^ r_ptr_bin_next;

    //  pointer registers 
    always @(posedge w_clk or negedge rst_w_n) begin
        if (!rst_w_n)
            w_ptr_bin <= 0;
        else
            w_ptr_bin <= w_ptr_bin_next;
    end

    always @(posedge r_clk or negedge rst_r_n) begin
        if (!rst_r_n)
            r_ptr_bin <= 0;
        else
            r_ptr_bin <= r_ptr_bin_next;
    end

    //  memory write 
    always @(posedge w_clk) begin
        if (w_fire)
            fifo[w_ptr_bin[PTR_WIDTH-1:0]] <= w_data;
    end

    //  show-ahead read 
    assign r_data = fifo[r_ptr_bin[PTR_WIDTH-1:0]];

    //  pointer synchronizers 
    reg [PTR_WIDTH:0] w_ptr_gray_sync1, w_ptr_gray_sync2;
    reg [PTR_WIDTH:0] r_ptr_gray_sync1, r_ptr_gray_sync2;

    always @(posedge r_clk or negedge rst_r_n) begin
        if (!rst_r_n) begin
            w_ptr_gray_sync1 <= 0;
            w_ptr_gray_sync2 <= 0;
        end else begin
            w_ptr_gray_sync1 <= w_ptr_gray;
            w_ptr_gray_sync2 <= w_ptr_gray_sync1;
        end
    end

    always @(posedge w_clk or negedge rst_w_n) begin
        if (!rst_w_n) begin
            r_ptr_gray_sync1 <= 0;
            r_ptr_gray_sync2 <= 0;
        end else begin
            r_ptr_gray_sync1 <= r_ptr_gray;
            r_ptr_gray_sync2 <= r_ptr_gray_sync1;
        end
    end

    //  next-state empty / full 
    reg empty_reg, full_reg;

    always @(posedge r_clk or negedge rst_r_n) begin
        if (!rst_r_n)
            empty_reg <= 1'b1;
        else
            empty_reg <= (r_ptr_gray_next == w_ptr_gray_sync2);
    end

    always @(posedge w_clk or negedge rst_w_n) begin
        if (!rst_w_n)
            full_reg <= 1'b0;
        else
            full_reg <= (w_ptr_gray_next == {~r_ptr_gray_sync2[PTR_WIDTH:PTR_WIDTH-1],r_ptr_gray_sync2[PTR_WIDTH-2:0]});
    end
    assign empty = empty_reg;
    assign full  = full_reg;
endmodule
