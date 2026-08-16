module xy_routing #(
    parameter ROUTER_X = 0,
    parameter ROUTER_Y = 0
)(
    input      [31:0] flit,      
    input              valid,     
    output reg [4:0]  req_dir    
);
    wire [1:0] dest_x = flit[27:26];
    wire [1:0] dest_y = flit[25:24];
    always @(*) begin
        req_dir = 5'b00000;
        if (valid) begin
            if (dest_x > ROUTER_X)
                req_dir = 5'b00100;      // EAST
            else if (dest_x < ROUTER_X)
                req_dir = 5'b01000;      // WEST
            else if (dest_y > ROUTER_Y)
                req_dir = 5'b00001;      // NORTH
            else if (dest_y < ROUTER_Y)
                req_dir = 5'b00010;      // SOUTH
            else
                req_dir = 5'b10000;      // dest_x==X, dest_y==Y -> LOCAL
        end
    end
endmodule
