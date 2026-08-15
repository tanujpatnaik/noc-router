module noc_link #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 8      
)(

    input                    src_clk,
    input                    src_rst_n,      // active-low, asynchronous
    input  [DATA_WIDTH-1:0]  src_data,
    input                    src_valid,
    output                   src_ready,

    input                    dst_clk,
    input                    dst_rst_n,      // active-low, asynchronous
    output [DATA_WIDTH-1:0]  dst_data,
    output                   dst_valid,
    input                    dst_pop
);

    wire link_full;
    wire link_empty;

    async_fifo #(
        .WIDTH (DATA_WIDTH),
        .DEPTH (FIFO_DEPTH)
    ) u_async_fifo (
        // write side = source router's output
        .w_clk   (src_clk),
        .rst_w_n (src_rst_n),
        .w_en    (src_valid),
        .w_data  (src_data),
        .full    (link_full),

        // read side = destination router's input
        .r_clk   (dst_clk),
        .rst_r_n (dst_rst_n),
        .r_en    (dst_pop),
        .r_data  (dst_data),
        .empty   (link_empty)
    );

    assign src_ready = ~link_full;
    assign dst_valid = ~link_empty;

endmodule
