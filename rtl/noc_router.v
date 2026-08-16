module noc_router #(
    parameter DATA_WIDTH      = 32,
    parameter LOCAL_FIFO_DEPTH = 8,
    parameter AGE_WIDTH       = 3,
    parameter ROUTER_X        = 0,
    parameter ROUTER_Y        = 0
)(
    input clk,
    input rst_n,                      // active-low, synchronous

    // NORTH -- fed by an external async_fifo link, see header comment
    input  [DATA_WIDTH-1:0] north_in_data,
    input                   north_in_valid,
    output                  north_in_pop,
    output [DATA_WIDTH-1:0] north_out_data,
    output                  north_out_valid,
    input                   north_out_ready,

    // SOUTH
    input  [DATA_WIDTH-1:0] south_in_data,
    input                   south_in_valid,
    output                  south_in_pop,
    output [DATA_WIDTH-1:0] south_out_data,
    output                  south_out_valid,
    input                   south_out_ready,

    // EAST
    input  [DATA_WIDTH-1:0] east_in_data,
    input                   east_in_valid,
    output                  east_in_pop,
    output [DATA_WIDTH-1:0] east_out_data,
    output                  east_out_valid,
    input                   east_out_ready,

    // WEST
    input  [DATA_WIDTH-1:0] west_in_data,
    input                   west_in_valid,
    output                  west_in_pop,
    output [DATA_WIDTH-1:0] west_out_data,
    output                  west_out_valid,
    input                   west_out_ready,

    // LOCAL -- raw producer handshake, buffered by an internal sync_fifo
    input  [DATA_WIDTH-1:0] local_in_data,
    input                   local_in_valid,
    output                  local_in_ready,
    output [DATA_WIDTH-1:0] local_out_data,
    output                  local_out_valid,
    input                   local_out_ready
);

    localparam NUM_PORTS = 5;
    localparam DIR_N = 0, DIR_S = 1, DIR_E = 2, DIR_W = 3, DIR_L = 4;

    // LOCAL's internal sync FIFO (the only FIFO this router owns)
    wire                   local_fifo_full;
    wire                   local_fifo_empty;
    wire [DATA_WIDTH-1:0]  local_fifo_rdata;
    wire                   local_pop;

    sync_fifo #(
        .WIDTH (DATA_WIDTH),
        .DEPTH (LOCAL_FIFO_DEPTH)
    ) u_local_fifo (
        .clk      (clk),
        .rst_n    (rst_n),
        .wr_en    (local_in_valid && local_in_ready),
        .rd_en    (local_pop),
        .data_in  (local_in_data),
        .data_out (local_fifo_rdata),
        .full     (local_fifo_full),
        .empty    (local_fifo_empty)
    );

    assign local_in_ready = ~local_fifo_full;

    // Per-input head data / head valid / pop, indexed [DIR_N..DIR_L]
    
    wire [DATA_WIDTH-1:0] in_data       [0:NUM_PORTS-1];
    wire                  in_head_valid [0:NUM_PORTS-1];
    wire                  pop_sig       [0:NUM_PORTS-1];

    assign in_data[DIR_N] = north_in_data;      assign in_head_valid[DIR_N] = north_in_valid;
    assign in_data[DIR_S] = south_in_data;      assign in_head_valid[DIR_S] = south_in_valid;
    assign in_data[DIR_E] = east_in_data;       assign in_head_valid[DIR_E] = east_in_valid;
    assign in_data[DIR_W] = west_in_data;       assign in_head_valid[DIR_W] = west_in_valid;
    assign in_data[DIR_L] = local_fifo_rdata;   assign in_head_valid[DIR_L] = ~local_fifo_empty;

    assign north_in_pop = pop_sig[DIR_N];
    assign south_in_pop = pop_sig[DIR_S];
    assign east_in_pop  = pop_sig[DIR_E];
    assign west_in_pop  = pop_sig[DIR_W];
    assign local_pop    = pop_sig[DIR_L];   // internal only, not a port

    // Per-input XY routing decode
    wire [NUM_PORTS-1:0] req_dir [0:NUM_PORTS-1];   // req_dir[input] = one-hot output request

    genvar gi, go, gj;
    generate
        for (gi = 0; gi < NUM_PORTS; gi = gi + 1) begin : ROUTE
            xy_routing #(
                .ROUTER_X (ROUTER_X),
                .ROUTER_Y (ROUTER_Y)
            ) u_route (
                .flit    (in_data[gi]),
                .valid   (in_head_valid[gi]),
                .req_dir (req_dir[gi])
            );
        end
    endgenerate
    // Request matrix: transpose req_dir[input][output] -> out_req[output][input]
    wire [NUM_PORTS-1:0] out_req [0:NUM_PORTS-1];

    generate
        for (go = 0; go < NUM_PORTS; go = go + 1) begin : REQ_MATRIX
            wire [NUM_PORTS-1:0] col;
            for (gj = 0; gj < NUM_PORTS; gj = gj + 1) begin : REQ_COL
                assign col[gj] = req_dir[gj][go];
            end
            assign out_req[go] = col;
        end
    endgenerate
    // One priority+aging arbiter per output port
    // out_grant[output][input]
    wire [NUM_PORTS-1:0] out_grant  [0:NUM_PORTS-1];
    wire                 out_gvalid [0:NUM_PORTS-1];
    wire                 out_ready_w[0:NUM_PORTS-1];
    wire                 out_xfer   [0:NUM_PORTS-1];   

    assign out_ready_w[DIR_N] = north_out_ready;
    assign out_ready_w[DIR_S] = south_out_ready;
    assign out_ready_w[DIR_E] = east_out_ready;
    assign out_ready_w[DIR_W] = west_out_ready;
    assign out_ready_w[DIR_L] = local_out_ready;

    generate
        for (go = 0; go < NUM_PORTS; go = go + 1) begin : ARBITERS
            priority_aging_arbiter #(
                .NUM_REQ   (NUM_PORTS),
                .AGE_WIDTH (AGE_WIDTH)
            ) u_arb (
                .clk         (clk),
                .rst_n       (rst_n),
                .req         (out_req[go]),
                .out_ready   (out_ready_w[go]),
                .grant       (out_grant[go]),
                .grant_valid (out_gvalid[go]),
                .transfer    (out_xfer[go])
            );
        end
    endgenerate

    // Crossbar: one-hot mux of input head data onto each output
    wire [DATA_WIDTH-1:0] out_data [0:NUM_PORTS-1];

    generate
        for (go = 0; go < NUM_PORTS; go = go + 1) begin : XBAR
            wire [DATA_WIDTH-1:0] terms [0:NUM_PORTS-1];
            for (gj = 0; gj < NUM_PORTS; gj = gj + 1) begin : XBAR_TERMS
                assign terms[gj] = out_grant[go][gj] ? in_data[gj] : {DATA_WIDTH{1'b0}};
            end
            assign out_data[go] = terms[0] | terms[1] | terms[2] | terms[3] | terms[4];
        end
    endgenerate

    assign north_out_data  = out_data[DIR_N];
    assign south_out_data  = out_data[DIR_S];
    assign east_out_data   = out_data[DIR_E];
    assign west_out_data   = out_data[DIR_W];
    assign local_out_data  = out_data[DIR_L];

    assign north_out_valid = out_gvalid[DIR_N];
    assign south_out_valid = out_gvalid[DIR_S];
    assign east_out_valid  = out_gvalid[DIR_E];
    assign west_out_valid  = out_gvalid[DIR_W];
    assign local_out_valid = out_gvalid[DIR_L];

    generate
        for (gi = 0; gi < NUM_PORTS; gi = gi + 1) begin : POP_LOGIC
            assign pop_sig[gi] = (out_xfer[DIR_N] & out_grant[DIR_N][gi]) |
                                 (out_xfer[DIR_S] & out_grant[DIR_S][gi]) |
                                 (out_xfer[DIR_E] & out_grant[DIR_E][gi]) |
                                 (out_xfer[DIR_W] & out_grant[DIR_W][gi]) |
                                 (out_xfer[DIR_L] & out_grant[DIR_L][gi]);
        end
    endgenerate

endmodule
