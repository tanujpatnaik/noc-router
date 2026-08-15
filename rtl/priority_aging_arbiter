module priority_aging_arbiter #(
    parameter NUM_REQ    = 5,
    parameter AGE_WIDTH  = 3,      
    parameter BASE_PRI_0 = 0,      // NORTH
    parameter BASE_PRI_1 = 0,      // SOUTH
    parameter BASE_PRI_2 = 0,      // EAST
    parameter BASE_PRI_3 = 0,      // WEST
    parameter BASE_PRI_4 = 0       // LOCAL
)(
    input                      clk,
    input                      rst_n,        // active-low, asynchronous
    input      [NUM_REQ-1:0]   req,
    input                      out_ready,    // downstream can accept a transfer this cycle
    output reg [NUM_REQ-1:0]   grant,        
    output reg                 grant_valid,
    output                     transfer      // grant_valid & out_ready 
);

    localparam PTR_WIDTH = $clog2(NUM_REQ);
    localparam [AGE_WIDTH-1:0] MAX_AGE = {AGE_WIDTH{1'b1}};
    // Static base priority per requester (fixed to 5 ports)
    wire [AGE_WIDTH-1:0] base_pri [0:NUM_REQ-1];
    assign base_pri[0] = BASE_PRI_0[AGE_WIDTH-1:0];
    assign base_pri[1] = BASE_PRI_1[AGE_WIDTH-1:0];
    assign base_pri[2] = BASE_PRI_2[AGE_WIDTH-1:0];
    assign base_pri[3] = BASE_PRI_3[AGE_WIDTH-1:0];
    assign base_pri[4] = BASE_PRI_4[AGE_WIDTH-1:0];
    // Per-input waiting age
    reg [AGE_WIDTH-1:0] age [0:NUM_REQ-1];
    // Effective priority = base + age, saturating at MAX_AGE
    wire [AGE_WIDTH-1:0] eff_pri [0:NUM_REQ-1];

    genvar gk;
    generate
        for (gk = 0; gk < NUM_REQ; gk = gk + 1) begin : EFF_PRI
            wire [AGE_WIDTH:0] pri_sum = base_pri[gk] + age[gk]; // extra bit catches overflow
            assign eff_pri[gk] = (pri_sum > MAX_AGE) ? MAX_AGE : pri_sum[AGE_WIDTH-1:0];
        end
    endgenerate

    // highest effective priority among active requesters
   
    integer i;
    reg [AGE_WIDTH-1:0] max_pri;

    always @(*) begin
        max_pri = {AGE_WIDTH{1'b0}};
        for (i = 0; i < NUM_REQ; i = i + 1) begin
            if (req[i] && (eff_pri[i] > max_pri))
                max_pri = eff_pri[i];
        end
    end

    // eligible = requesting AND at max effective priority
    
    wire [NUM_REQ-1:0] eligible;
    generate
        for (gk = 0; gk < NUM_REQ; gk = gk + 1) begin : ELIGIBLE
            assign eligible[gk] = req[gk] && (eff_pri[gk] == max_pri);
        end
    endgenerate


    // round-robin tie-break among the eligible set
    
    reg [PTR_WIDTH-1:0] ptr;
    integer j;
    integer idx;
    reg [PTR_WIDTH-1:0] grant_idx;

    always @(*) begin
        grant       = {NUM_REQ{1'b0}};
        grant_valid = 1'b0;
        grant_idx   = {PTR_WIDTH{1'b0}};

        for (j = 0; j < NUM_REQ; j = j + 1) begin
            idx = ptr + j;
            if (idx >= NUM_REQ)
                idx = idx - NUM_REQ;

            if (!grant_valid && eligible[idx]) begin
                grant_idx   = idx[PTR_WIDTH-1:0];
                grant[idx]  = 1'b1;
                grant_valid = 1'b1;
            end
        end
    end

    assign transfer = grant_valid & out_ready;
    // RR pointer: rotates only on a completed transfer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ptr <= {PTR_WIDTH{1'b0}};
        else if (transfer)
            ptr <= (grant_idx == NUM_REQ-1) ? {PTR_WIDTH{1'b0}} : grant_idx + 1'b1;
    end

    // Age update
    generate
        for (gk = 0; gk < NUM_REQ; gk = gk + 1) begin : AGE_UPDATE
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    age[gk] <= {AGE_WIDTH{1'b0}};
                else if (!req[gk])
                    age[gk] <= {AGE_WIDTH{1'b0}};              // nothing pending -> no aging
                else if (grant[gk] && transfer)
                    age[gk] <= {AGE_WIDTH{1'b0}};              // serviced this cycle -> reset
                else if (age[gk] != MAX_AGE)
                    age[gk] <= age[gk] + 1'b1;                 // still waiting -> age up (saturating)
            end
        end
    endgenerate

endmodule
