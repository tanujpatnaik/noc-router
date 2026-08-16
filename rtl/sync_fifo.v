module sync_fifo #(
    parameter WIDTH = 32,
    parameter DEPTH = 8
)(
    input                   clk,
    input                   rst_n,      // active-low, synchronous
    input                   wr_en,
    input                   rd_en,
    input      [WIDTH-1:0]  data_in,
    output     [WIDTH-1:0]  data_out,   
    output                  full,
    output                  empty
);
    localparam ADDR_W = $clog2(DEPTH);
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_W-1:0] wr_ptr, rd_ptr;
    reg [ADDR_W:0]   count;
    wire wr_fire = wr_en && !full;
    wire rd_fire = rd_en && !empty;
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
        end else begin
            if (wr_fire)
                mem[wr_ptr] <= data_in;
            case ({wr_fire, rd_fire})
                2'b10: begin
                    wr_ptr <= wr_ptr + 1;
                    count  <= count + 1;
                end
                2'b01: begin
                    rd_ptr <= rd_ptr + 1;
                    count  <= count - 1;
                end
                2'b11: begin
                    wr_ptr <= wr_ptr + 1;
                    rd_ptr <= rd_ptr + 1;
                end
                default: begin
                    // no operation
                end
            endcase
        end
    end
    assign data_out = mem[rd_ptr];
    assign empty = (count == 0);
    assign full  = (count == DEPTH);
endmodule
