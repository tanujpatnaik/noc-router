module noc_top #(
    parameter DATA_WIDTH       = 32,
    parameter LOCAL_FIFO_DEPTH = 8,
    parameter LINK_FIFO_DEPTH  = 8,
    parameter AGE_WIDTH        = 3
)(
    input clk00, input rst00_n,     // R00 (0,0) clock domain
    input clk10, input rst10_n,     // R10 (1,0) clock domain
    input clk01, input rst01_n,     // R01 (0,1) clock domain
    input clk11, input rst11_n,     // R11 (1,1) clock domain

    // R00 LOCAL
    input  [DATA_WIDTH-1:0] r00_local_in_data,
    input                   r00_local_in_valid,
    output                  r00_local_in_ready,
    output [DATA_WIDTH-1:0] r00_local_out_data,
    output                  r00_local_out_valid,
    input                   r00_local_out_ready,

    // R10 LOCAL
    input  [DATA_WIDTH-1:0] r10_local_in_data,
    input                   r10_local_in_valid,
    output                  r10_local_in_ready,
    output [DATA_WIDTH-1:0] r10_local_out_data,
    output                  r10_local_out_valid,
    input                   r10_local_out_ready,

    // R01 LOCAL
    input  [DATA_WIDTH-1:0] r01_local_in_data,
    input                   r01_local_in_valid,
    output                  r01_local_in_ready,
    output [DATA_WIDTH-1:0] r01_local_out_data,
    output                  r01_local_out_valid,
    input                   r01_local_out_ready,

    // R11 LOCAL
    input  [DATA_WIDTH-1:0] r11_local_in_data,
    input                   r11_local_in_valid,
    output                  r11_local_in_ready,
    output [DATA_WIDTH-1:0] r11_local_out_data,
    output                  r11_local_out_valid,
    input                   r11_local_out_ready
);
    // R00 (0,0) -- neighbors: EAST=R10, NORTH=R01. No WEST, no SOUTH.
    wire [DATA_WIDTH-1:0] r00_n_in_data,  r00_s_in_data,  r00_e_in_data,  r00_w_in_data;
    wire                  r00_n_in_valid, r00_s_in_valid, r00_e_in_valid, r00_w_in_valid;
    wire                  r00_n_in_pop,   r00_s_in_pop,   r00_e_in_pop,   r00_w_in_pop;
    wire [DATA_WIDTH-1:0] r00_n_out_data, r00_s_out_data, r00_e_out_data, r00_w_out_data;
    wire                  r00_n_out_valid,r00_s_out_valid,r00_e_out_valid,r00_w_out_valid;
    wire                  r00_n_out_ready,r00_s_out_ready,r00_e_out_ready,r00_w_out_ready;

    noc_router #(
        .DATA_WIDTH(DATA_WIDTH), .LOCAL_FIFO_DEPTH(LOCAL_FIFO_DEPTH),
        .AGE_WIDTH(AGE_WIDTH), .ROUTER_X(0), .ROUTER_Y(0)
    ) u_r00 (
        .clk (clk00), .rst_n (rst00_n),
        .north_in_data(r00_n_in_data), .north_in_valid(r00_n_in_valid), .north_in_pop(r00_n_in_pop),
        .north_out_data(r00_n_out_data), .north_out_valid(r00_n_out_valid), .north_out_ready(r00_n_out_ready),
        .south_in_data(r00_s_in_data), .south_in_valid(r00_s_in_valid), .south_in_pop(r00_s_in_pop),
        .south_out_data(r00_s_out_data), .south_out_valid(r00_s_out_valid), .south_out_ready(r00_s_out_ready),
        .east_in_data(r00_e_in_data), .east_in_valid(r00_e_in_valid), .east_in_pop(r00_e_in_pop),
        .east_out_data(r00_e_out_data), .east_out_valid(r00_e_out_valid), .east_out_ready(r00_e_out_ready),
        .west_in_data(r00_w_in_data), .west_in_valid(r00_w_in_valid), .west_in_pop(r00_w_in_pop),
        .west_out_data(r00_w_out_data), .west_out_valid(r00_w_out_valid), .west_out_ready(r00_w_out_ready),
        .local_in_data(r00_local_in_data), .local_in_valid(r00_local_in_valid), .local_in_ready(r00_local_in_ready),
        .local_out_data(r00_local_out_data), .local_out_valid(r00_local_out_valid), .local_out_ready(r00_local_out_ready)
    );

    // R10 (1,0) -- neighbors: WEST=R00, NORTH=R11. No EAST, no SOUTH.
    wire [DATA_WIDTH-1:0] r10_n_in_data,  r10_s_in_data,  r10_e_in_data,  r10_w_in_data;
    wire                  r10_n_in_valid, r10_s_in_valid, r10_e_in_valid, r10_w_in_valid;
    wire                  r10_n_in_pop,   r10_s_in_pop,   r10_e_in_pop,   r10_w_in_pop;
    wire [DATA_WIDTH-1:0] r10_n_out_data, r10_s_out_data, r10_e_out_data, r10_w_out_data;
    wire                  r10_n_out_valid,r10_s_out_valid,r10_e_out_valid,r10_w_out_valid;
    wire                  r10_n_out_ready,r10_s_out_ready,r10_e_out_ready,r10_w_out_ready;

    noc_router #(
        .DATA_WIDTH(DATA_WIDTH), .LOCAL_FIFO_DEPTH(LOCAL_FIFO_DEPTH),
        .AGE_WIDTH(AGE_WIDTH), .ROUTER_X(1), .ROUTER_Y(0)
    ) u_r10 (
        .clk (clk10), .rst_n (rst10_n),
        .north_in_data(r10_n_in_data), .north_in_valid(r10_n_in_valid), .north_in_pop(r10_n_in_pop),
        .north_out_data(r10_n_out_data), .north_out_valid(r10_n_out_valid), .north_out_ready(r10_n_out_ready),
        .south_in_data(r10_s_in_data), .south_in_valid(r10_s_in_valid), .south_in_pop(r10_s_in_pop),
        .south_out_data(r10_s_out_data), .south_out_valid(r10_s_out_valid), .south_out_ready(r10_s_out_ready),
        .east_in_data(r10_e_in_data), .east_in_valid(r10_e_in_valid), .east_in_pop(r10_e_in_pop),
        .east_out_data(r10_e_out_data), .east_out_valid(r10_e_out_valid), .east_out_ready(r10_e_out_ready),
        .west_in_data(r10_w_in_data), .west_in_valid(r10_w_in_valid), .west_in_pop(r10_w_in_pop),
        .west_out_data(r10_w_out_data), .west_out_valid(r10_w_out_valid), .west_out_ready(r10_w_out_ready),
        .local_in_data(r10_local_in_data), .local_in_valid(r10_local_in_valid), .local_in_ready(r10_local_in_ready),
        .local_out_data(r10_local_out_data), .local_out_valid(r10_local_out_valid), .local_out_ready(r10_local_out_ready)
    );

    // R01 (0,1) -- neighbors: EAST=R11, SOUTH=R00. No WEST, no NORTH.
    wire [DATA_WIDTH-1:0] r01_n_in_data,  r01_s_in_data,  r01_e_in_data,  r01_w_in_data;
    wire                  r01_n_in_valid, r01_s_in_valid, r01_e_in_valid, r01_w_in_valid;
    wire                  r01_n_in_pop,   r01_s_in_pop,   r01_e_in_pop,   r01_w_in_pop;
    wire [DATA_WIDTH-1:0] r01_n_out_data, r01_s_out_data, r01_e_out_data, r01_w_out_data;
    wire                  r01_n_out_valid,r01_s_out_valid,r01_e_out_valid,r01_w_out_valid;
    wire                  r01_n_out_ready,r01_s_out_ready,r01_e_out_ready,r01_w_out_ready;

    noc_router #(
        .DATA_WIDTH(DATA_WIDTH), .LOCAL_FIFO_DEPTH(LOCAL_FIFO_DEPTH),
        .AGE_WIDTH(AGE_WIDTH), .ROUTER_X(0), .ROUTER_Y(1)
    ) u_r01 (
        .clk (clk01), .rst_n (rst01_n),
        .north_in_data(r01_n_in_data), .north_in_valid(r01_n_in_valid), .north_in_pop(r01_n_in_pop),
        .north_out_data(r01_n_out_data), .north_out_valid(r01_n_out_valid), .north_out_ready(r01_n_out_ready),
        .south_in_data(r01_s_in_data), .south_in_valid(r01_s_in_valid), .south_in_pop(r01_s_in_pop),
        .south_out_data(r01_s_out_data), .south_out_valid(r01_s_out_valid), .south_out_ready(r01_s_out_ready),
        .east_in_data(r01_e_in_data), .east_in_valid(r01_e_in_valid), .east_in_pop(r01_e_in_pop),
        .east_out_data(r01_e_out_data), .east_out_valid(r01_e_out_valid), .east_out_ready(r01_e_out_ready),
        .west_in_data(r01_w_in_data), .west_in_valid(r01_w_in_valid), .west_in_pop(r01_w_in_pop),
        .west_out_data(r01_w_out_data), .west_out_valid(r01_w_out_valid), .west_out_ready(r01_w_out_ready),
        .local_in_data(r01_local_in_data), .local_in_valid(r01_local_in_valid), .local_in_ready(r01_local_in_ready),
        .local_out_data(r01_local_out_data), .local_out_valid(r01_local_out_valid), .local_out_ready(r01_local_out_ready)
    );

    // R11 (1,1) -- neighbors: WEST=R01, SOUTH=R10. No EAST, no NORTH.
    wire [DATA_WIDTH-1:0] r11_n_in_data,  r11_s_in_data,  r11_e_in_data,  r11_w_in_data;
    wire                  r11_n_in_valid, r11_s_in_valid, r11_e_in_valid, r11_w_in_valid;
    wire                  r11_n_in_pop,   r11_s_in_pop,   r11_e_in_pop,   r11_w_in_pop;
    wire [DATA_WIDTH-1:0] r11_n_out_data, r11_s_out_data, r11_e_out_data, r11_w_out_data;
    wire                  r11_n_out_valid,r11_s_out_valid,r11_e_out_valid,r11_w_out_valid;
    wire                  r11_n_out_ready,r11_s_out_ready,r11_e_out_ready,r11_w_out_ready;

    noc_router #(
        .DATA_WIDTH(DATA_WIDTH), .LOCAL_FIFO_DEPTH(LOCAL_FIFO_DEPTH),
        .AGE_WIDTH(AGE_WIDTH), .ROUTER_X(1), .ROUTER_Y(1)
    ) u_r11 (
        .clk (clk11), .rst_n (rst11_n),
        .north_in_data(r11_n_in_data), .north_in_valid(r11_n_in_valid), .north_in_pop(r11_n_in_pop),
        .north_out_data(r11_n_out_data), .north_out_valid(r11_n_out_valid), .north_out_ready(r11_n_out_ready),
        .south_in_data(r11_s_in_data), .south_in_valid(r11_s_in_valid), .south_in_pop(r11_s_in_pop),
        .south_out_data(r11_s_out_data), .south_out_valid(r11_s_out_valid), .south_out_ready(r11_s_out_ready),
        .east_in_data(r11_e_in_data), .east_in_valid(r11_e_in_valid), .east_in_pop(r11_e_in_pop),
        .east_out_data(r11_e_out_data), .east_out_valid(r11_e_out_valid), .east_out_ready(r11_e_out_ready),
        .west_in_data(r11_w_in_data), .west_in_valid(r11_w_in_valid), .west_in_pop(r11_w_in_pop),
        .west_out_data(r11_w_out_data), .west_out_valid(r11_w_out_valid), .west_out_ready(r11_w_out_ready),
        .local_in_data(r11_local_in_data), .local_in_valid(r11_local_in_valid), .local_in_ready(r11_local_in_ready),
        .local_out_data(r11_local_out_data), .local_out_valid(r11_local_out_valid), .local_out_ready(r11_local_out_ready)
    );

    // Inter-router links : two per edge, one per direction.

    // R00 EAST <-> R10 WEST
    noc_link #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(LINK_FIFO_DEPTH)) u_link_r00e_r10w (
        .src_clk(clk00), .src_rst_n(rst00_n),
        .src_data(r00_e_out_data), .src_valid(r00_e_out_valid), .src_ready(r00_e_out_ready),
        .dst_clk(clk10), .dst_rst_n(rst10_n),
        .dst_data(r10_w_in_data), .dst_valid(r10_w_in_valid), .dst_pop(r10_w_in_pop)
    );
    noc_link #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(LINK_FIFO_DEPTH)) u_link_r10w_r00e (
        .src_clk(clk10), .src_rst_n(rst10_n),
        .src_data(r10_w_out_data), .src_valid(r10_w_out_valid), .src_ready(r10_w_out_ready),
        .dst_clk(clk00), .dst_rst_n(rst00_n),
        .dst_data(r00_e_in_data), .dst_valid(r00_e_in_valid), .dst_pop(r00_e_in_pop)
    );

    // R01 EAST <-> R11 WEST
    noc_link #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(LINK_FIFO_DEPTH)) u_link_r01e_r11w (
        .src_clk(clk01), .src_rst_n(rst01_n),
        .src_data(r01_e_out_data), .src_valid(r01_e_out_valid), .src_ready(r01_e_out_ready),
        .dst_clk(clk11), .dst_rst_n(rst11_n),
        .dst_data(r11_w_in_data), .dst_valid(r11_w_in_valid), .dst_pop(r11_w_in_pop)
    );
    noc_link #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(LINK_FIFO_DEPTH)) u_link_r11w_r01e (
        .src_clk(clk11), .src_rst_n(rst11_n),
        .src_data(r11_w_out_data), .src_valid(r11_w_out_valid), .src_ready(r11_w_out_ready),
        .dst_clk(clk01), .dst_rst_n(rst01_n),
        .dst_data(r01_e_in_data), .dst_valid(r01_e_in_valid), .dst_pop(r01_e_in_pop)
    );

    // R00 NORTH <-> R01 SOUTH
    noc_link #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(LINK_FIFO_DEPTH)) u_link_r00n_r01s (
        .src_clk(clk00), .src_rst_n(rst00_n),
        .src_data(r00_n_out_data), .src_valid(r00_n_out_valid), .src_ready(r00_n_out_ready),
        .dst_clk(clk01), .dst_rst_n(rst01_n),
        .dst_data(r01_s_in_data), .dst_valid(r01_s_in_valid), .dst_pop(r01_s_in_pop)
    );
    noc_link #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(LINK_FIFO_DEPTH)) u_link_r01s_r00n (
        .src_clk(clk01), .src_rst_n(rst01_n),
        .src_data(r01_s_out_data), .src_valid(r01_s_out_valid), .src_ready(r01_s_out_ready),
        .dst_clk(clk00), .dst_rst_n(rst00_n),
        .dst_data(r00_n_in_data), .dst_valid(r00_n_in_valid), .dst_pop(r00_n_in_pop)
    );

    // R10 NORTH <-> R11 SOUTH
    noc_link #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(LINK_FIFO_DEPTH)) u_link_r10n_r11s (
        .src_clk(clk10), .src_rst_n(rst10_n),
        .src_data(r10_n_out_data), .src_valid(r10_n_out_valid), .src_ready(r10_n_out_ready),
        .dst_clk(clk11), .dst_rst_n(rst11_n),
        .dst_data(r11_s_in_data), .dst_valid(r11_s_in_valid), .dst_pop(r11_s_in_pop)
    );
    noc_link #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(LINK_FIFO_DEPTH)) u_link_r11s_r10n (
        .src_clk(clk11), .src_rst_n(rst11_n),
        .src_data(r11_s_out_data), .src_valid(r11_s_out_valid), .src_ready(r11_s_out_ready),
        .dst_clk(clk10), .dst_rst_n(rst10_n),
        .dst_data(r10_n_in_data), .dst_valid(r10_n_in_valid), .dst_pop(r10_n_in_pop)
    );

    // Tie-offs for directions with no neighbor at this mesh edge
    

    // R00: no WEST, no SOUTH
    assign r00_w_in_data  = {DATA_WIDTH{1'b0}};
    assign r00_w_in_valid = 1'b0;
    assign r00_w_out_ready = 1'b0;
    assign r00_s_in_data  = {DATA_WIDTH{1'b0}};
    assign r00_s_in_valid = 1'b0;
    assign r00_s_out_ready = 1'b0;

    // R10: no EAST, no SOUTH
    assign r10_e_in_data  = {DATA_WIDTH{1'b0}};
    assign r10_e_in_valid = 1'b0;
    assign r10_e_out_ready = 1'b0;
    assign r10_s_in_data  = {DATA_WIDTH{1'b0}};
    assign r10_s_in_valid = 1'b0;
    assign r10_s_out_ready = 1'b0;

    // R01: no WEST, no NORTH
    assign r01_w_in_data  = {DATA_WIDTH{1'b0}};
    assign r01_w_in_valid = 1'b0;
    assign r01_w_out_ready = 1'b0;
    assign r01_n_in_data  = {DATA_WIDTH{1'b0}};
    assign r01_n_in_valid = 1'b0;
    assign r01_n_out_ready = 1'b0;

    // R11: no EAST, no NORTH
    assign r11_e_in_data  = {DATA_WIDTH{1'b0}};
    assign r11_e_in_valid = 1'b0;
    assign r11_e_out_ready = 1'b0;
    assign r11_n_in_data  = {DATA_WIDTH{1'b0}};
    assign r11_n_in_valid = 1'b0;
    assign r11_n_out_ready = 1'b0;

endmodule
