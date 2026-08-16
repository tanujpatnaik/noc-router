`timescale 1ns / 1ps
module tb_noc_top;

    localparam DATA_WIDTH       = 32;
    localparam LOCAL_FIFO_DEPTH = 8;
    localparam LINK_FIFO_DEPTH  = 8;
    localparam AGE_WIDTH        = 3;

    // different, non-multiple clock periods .
    localparam CLK00_PERIOD = 10;
    localparam CLK10_PERIOD = 7;
    localparam CLK01_PERIOD = 13;
    localparam CLK11_PERIOD = 9;

    localparam RUN_TIME   = 20000;  // ns of randomized injection
    localparam DRAIN_TIME = 6000;   // ns to let in-flight flits finish after injection stops
    localparam MAX_FLITS  = 20000;  // scoreboard capacity -- generous for the run length above

    // source_id / dest_id encoding, shared: 0=R00 1=R10 2=R01 3=R11
    localparam SRC_R00 = 2'd0, SRC_R10 = 2'd1, SRC_R01 = 2'd2, SRC_R11 = 2'd3;

    // Clocks / resets (active-low)
    reg clk00 = 1'b0, clk10 = 1'b0, clk01 = 1'b0, clk11 = 1'b0;
    reg rst00_n = 1'b0, rst10_n = 1'b0, rst01_n = 1'b0, rst11_n = 1'b0;

    always #(CLK00_PERIOD/2) clk00 = ~clk00;
    always #(CLK10_PERIOD/2) clk10 = ~clk10;
    always #(CLK01_PERIOD/2) clk01 = ~clk01;
    always #(CLK11_PERIOD/2) clk11 = ~clk11;

    // DUT LOCAL port signals
    
    reg  [DATA_WIDTH-1:0] r00_local_in_data,  r10_local_in_data,  r01_local_in_data,  r11_local_in_data;
    reg                   r00_local_in_valid, r10_local_in_valid, r01_local_in_valid, r11_local_in_valid;
    wire                  r00_local_in_ready, r10_local_in_ready, r01_local_in_ready, r11_local_in_ready;

    wire [DATA_WIDTH-1:0] r00_local_out_data,  r10_local_out_data,  r01_local_out_data,  r11_local_out_data;
    wire                  r00_local_out_valid, r10_local_out_valid, r01_local_out_valid, r11_local_out_valid;
    reg                   r00_local_out_ready, r10_local_out_ready, r01_local_out_ready, r11_local_out_ready;

    // DUT
    noc_top #(
        .DATA_WIDTH(DATA_WIDTH), .LOCAL_FIFO_DEPTH(LOCAL_FIFO_DEPTH),
        .LINK_FIFO_DEPTH(LINK_FIFO_DEPTH), .AGE_WIDTH(AGE_WIDTH)
    ) dut (
        .clk00(clk00), .rst00_n(rst00_n),
        .clk10(clk10), .rst10_n(rst10_n),
        .clk01(clk01), .rst01_n(rst01_n),
        .clk11(clk11), .rst11_n(rst11_n),

        .r00_local_in_data(r00_local_in_data), .r00_local_in_valid(r00_local_in_valid), .r00_local_in_ready(r00_local_in_ready),
        .r00_local_out_data(r00_local_out_data), .r00_local_out_valid(r00_local_out_valid), .r00_local_out_ready(r00_local_out_ready),

        .r10_local_in_data(r10_local_in_data), .r10_local_in_valid(r10_local_in_valid), .r10_local_in_ready(r10_local_in_ready),
        .r10_local_out_data(r10_local_out_data), .r10_local_out_valid(r10_local_out_valid), .r10_local_out_ready(r10_local_out_ready),

        .r01_local_in_data(r01_local_in_data), .r01_local_in_valid(r01_local_in_valid), .r01_local_in_ready(r01_local_in_ready),
        .r01_local_out_data(r01_local_out_data), .r01_local_out_valid(r01_local_out_valid), .r01_local_out_ready(r01_local_out_ready),

        .r11_local_in_data(r11_local_in_data), .r11_local_in_valid(r11_local_in_valid), .r11_local_in_ready(r11_local_in_ready),
        .r11_local_out_data(r11_local_out_data), .r11_local_out_valid(r11_local_out_valid), .r11_local_out_ready(r11_local_out_ready)
    );

    // Scoreboard
    // (dest_id, payload) is now provably unique because payload embeds
    // a 2-bit source tag in its top bits -- see header.
    reg [23:0] exp_payload [0:MAX_FLITS-1];
    reg [1:0]  exp_dest    [0:MAX_FLITS-1];
    reg [63:0] exp_time    [0:MAX_FLITS-1];
    reg        exp_valid   [0:MAX_FLITS-1];
    integer    exp_count;
    integer    received_count;
    integer    error_count;
    reg        test_active;

    function [1:0] dest_id_of(input [1:0] dx, input [1:0] dy);
        dest_id_of = {dy[0], dx[0]};
    endfunction

    task automatic sb_push(input [1:0] dest_id, input [23:0] payload);
        begin
            if (exp_count >= MAX_FLITS) begin
                $display("[%0t] SCOREBOARD OVERFLOW -- increase MAX_FLITS", $time);
                error_count = error_count + 1;
            end else begin
                exp_dest[exp_count]    = dest_id;
                exp_payload[exp_count] = payload;
                exp_time[exp_count]    = $time;
                exp_valid[exp_count]   = 1'b1;
                exp_count = exp_count + 1;
            end
        end
    endtask

    task automatic sb_check(input [1:0] dest_id, input [23:0] payload);
        integer k;
        reg found;
        begin
            found = 1'b0;
            for (k = 0; k < exp_count; k = k + 1) begin
                if (!found && exp_valid[k] && exp_dest[k] == dest_id && exp_payload[k] == payload) begin
                    exp_valid[k] = 1'b0;
                    found = 1'b1;
                end
            end
            if (found) begin
                received_count = received_count + 1;
            end else begin
                $display("[%0t] ERROR: unexpected/duplicate/misrouted flit at router %0d, payload=%0h (src tag=%0d)",
                          $time, dest_id, payload, payload[23:22]);
                error_count = error_count + 1;
            end
        end
    endtask

    // R00 LOCAL driver + monitor  (own coords 0,0 -> dest_id 0)
    // payload = {SRC_R00, 22-bit counter} -- see header
    reg [1:0] r00_dx, r00_dy;
    reg [21:0] r00_payload_ctr;

    initial begin
        r00_local_in_valid = 1'b0;
        r00_local_in_data  = {DATA_WIDTH{1'b0}};
        r00_payload_ctr    = 22'd0;
    end

    always @(posedge clk00) begin
        if (!rst00_n) begin
            r00_local_in_valid <= 1'b0;
        end else if (r00_local_in_valid && r00_local_in_ready) begin
            sb_push(dest_id_of(r00_local_in_data[27:26], r00_local_in_data[25:24]),
                    r00_local_in_data[23:0]);
            if (test_active && ($random % 4 != 0)) begin
                r00_dx = $urandom_range(0, 1); r00_dy = $urandom_range(0, 1);
                r00_local_in_data  <= {4'b0011, r00_dx, r00_dy, SRC_R00, r00_payload_ctr};
                r00_local_in_valid <= 1'b1;
                r00_payload_ctr    <= r00_payload_ctr + 1'b1;
            end else begin
                r00_local_in_valid <= 1'b0;
            end
        end else if (!r00_local_in_valid && test_active && ($random % 3 != 0)) begin
            r00_dx = $urandom_range(0, 1); r00_dy = $urandom_range(0, 1);
            r00_local_in_data  <= {4'b0011, r00_dx, r00_dy, SRC_R00, r00_payload_ctr};
            r00_local_in_valid <= 1'b1;
            r00_payload_ctr    <= r00_payload_ctr + 1'b1;
        end
    end

    always @(posedge clk00) begin
        if (!rst00_n)
            r00_local_out_ready <= 1'b0;
        else
            r00_local_out_ready <= ($random % 5 != 0);
    end

    always @(posedge clk00) begin
        if (rst00_n && r00_local_out_valid && r00_local_out_ready) begin
            if (r00_local_out_data[27:26] != 2'd0 || r00_local_out_data[25:24] != 2'd0) begin
                $display("[%0t] ERROR: flit arrived at R00 with wrong dest field (%0d,%0d)",
                          $time, r00_local_out_data[27:26], r00_local_out_data[25:24]);
                error_count = error_count + 1;
            end
            sb_check(2'd0, r00_local_out_data[23:0]);
        end
    end
    // R10 LOCAL driver + monitor  (own coords 1,0 -> dest_id 1)
    reg [1:0] r10_dx, r10_dy;
    reg [21:0] r10_payload_ctr;

    initial begin
        r10_local_in_valid = 1'b0;
        r10_local_in_data  = {DATA_WIDTH{1'b0}};
        r10_payload_ctr    = 22'd0;
    end

    always @(posedge clk10) begin
        if (!rst10_n) begin
            r10_local_in_valid <= 1'b0;
        end else if (r10_local_in_valid && r10_local_in_ready) begin
            sb_push(dest_id_of(r10_local_in_data[27:26], r10_local_in_data[25:24]),
                    r10_local_in_data[23:0]);
            if (test_active && ($random % 4 != 0)) begin
                r10_dx = $urandom_range(0, 1); r10_dy = $urandom_range(0, 1);
                r10_local_in_data  <= {4'b0011, r10_dx, r10_dy, SRC_R10, r10_payload_ctr};
                r10_local_in_valid <= 1'b1;
                r10_payload_ctr    <= r10_payload_ctr + 1'b1;
            end else begin
                r10_local_in_valid <= 1'b0;
            end
        end else if (!r10_local_in_valid && test_active && ($random % 3 != 0)) begin
            r10_dx = $urandom_range(0, 1); r10_dy = $urandom_range(0, 1);
            r10_local_in_data  <= {4'b0011, r10_dx, r10_dy, SRC_R10, r10_payload_ctr};
            r10_local_in_valid <= 1'b1;
            r10_payload_ctr    <= r10_payload_ctr + 1'b1;
        end
    end

    always @(posedge clk10) begin
        if (!rst10_n)
            r10_local_out_ready <= 1'b0;
        else
            r10_local_out_ready <= ($random % 5 != 0);
    end

    always @(posedge clk10) begin
        if (rst10_n && r10_local_out_valid && r10_local_out_ready) begin
            if (r10_local_out_data[27:26] != 2'd1 || r10_local_out_data[25:24] != 2'd0) begin
                $display("[%0t] ERROR: flit arrived at R10 with wrong dest field (%0d,%0d)",
                          $time, r10_local_out_data[27:26], r10_local_out_data[25:24]);
                error_count = error_count + 1;
            end
            sb_check(2'd1, r10_local_out_data[23:0]);
        end
    end
    // R01 LOCAL driver + monitor  (own coords 0,1 -> dest_id 2)
    reg [1:0] r01_dx, r01_dy;
    reg [21:0] r01_payload_ctr;

    initial begin
        r01_local_in_valid = 1'b0;
        r01_local_in_data  = {DATA_WIDTH{1'b0}};
        r01_payload_ctr    = 22'd0;
    end

    always @(posedge clk01) begin
        if (!rst01_n) begin
            r01_local_in_valid <= 1'b0;
        end else if (r01_local_in_valid && r01_local_in_ready) begin
            sb_push(dest_id_of(r01_local_in_data[27:26], r01_local_in_data[25:24]),
                    r01_local_in_data[23:0]);
            if (test_active && ($random % 4 != 0)) begin
                r01_dx = $urandom_range(0, 1); r01_dy = $urandom_range(0, 1);
                r01_local_in_data  <= {4'b0011, r01_dx, r01_dy, SRC_R01, r01_payload_ctr};
                r01_local_in_valid <= 1'b1;
                r01_payload_ctr    <= r01_payload_ctr + 1'b1;
            end else begin
                r01_local_in_valid <= 1'b0;
            end
        end else if (!r01_local_in_valid && test_active && ($random % 3 != 0)) begin
            r01_dx = $urandom_range(0, 1); r01_dy = $urandom_range(0, 1);
            r01_local_in_data  <= {4'b0011, r01_dx, r01_dy, SRC_R01, r01_payload_ctr};
            r01_local_in_valid <= 1'b1;
            r01_payload_ctr    <= r01_payload_ctr + 1'b1;
        end
    end

    always @(posedge clk01) begin
        if (!rst01_n)
            r01_local_out_ready <= 1'b0;
        else
            r01_local_out_ready <= ($random % 5 != 0);
    end

    always @(posedge clk01) begin
        if (rst01_n && r01_local_out_valid && r01_local_out_ready) begin
            if (r01_local_out_data[27:26] != 2'd0 || r01_local_out_data[25:24] != 2'd1) begin
                $display("[%0t] ERROR: flit arrived at R01 with wrong dest field (%0d,%0d)",
                          $time, r01_local_out_data[27:26], r01_local_out_data[25:24]);
                error_count = error_count + 1;
            end
            sb_check(2'd2, r01_local_out_data[23:0]);
        end
    end
    // R11 LOCAL driver + monitor  (own coords 1,1 -> dest_id 3)
    reg [1:0] r11_dx, r11_dy;
    reg [21:0] r11_payload_ctr;

    initial begin
        r11_local_in_valid = 1'b0;
        r11_local_in_data  = {DATA_WIDTH{1'b0}};
        r11_payload_ctr    = 22'd0;
    end

    always @(posedge clk11) begin
        if (!rst11_n) begin
            r11_local_in_valid <= 1'b0;
        end else if (r11_local_in_valid && r11_local_in_ready) begin
            sb_push(dest_id_of(r11_local_in_data[27:26], r11_local_in_data[25:24]),
                    r11_local_in_data[23:0]);
            if (test_active && ($random % 4 != 0)) begin
                r11_dx = $urandom_range(0, 1); r11_dy = $urandom_range(0, 1);
                r11_local_in_data  <= {4'b0011, r11_dx, r11_dy, SRC_R11, r11_payload_ctr};
                r11_local_in_valid <= 1'b1;
                r11_payload_ctr    <= r11_payload_ctr + 1'b1;
            end else begin
                r11_local_in_valid <= 1'b0;
            end
        end else if (!r11_local_in_valid && test_active && ($random % 3 != 0)) begin
            r11_dx = $urandom_range(0, 1); r11_dy = $urandom_range(0, 1);
            r11_local_in_data  <= {4'b0011, r11_dx, r11_dy, SRC_R11, r11_payload_ctr};
            r11_local_in_valid <= 1'b1;
            r11_payload_ctr    <= r11_payload_ctr + 1'b1;
        end
    end

    always @(posedge clk11) begin
        if (!rst11_n)
            r11_local_out_ready <= 1'b0;
        else
            r11_local_out_ready <= ($random % 5 != 0);
    end

    always @(posedge clk11) begin
        if (rst11_n && r11_local_out_valid && r11_local_out_ready) begin
            if (r11_local_out_data[27:26] != 2'd1 || r11_local_out_data[25:24] != 2'd1) begin
                $display("[%0t] ERROR: flit arrived at R11 with wrong dest field (%0d,%0d)",
                          $time, r11_local_out_data[27:26], r11_local_out_data[25:24]);
                error_count = error_count + 1;
            end
            sb_check(2'd3, r11_local_out_data[23:0]);
        end
    end
    // Test sequencing
    integer li, lost;

    initial begin
        exp_count      = 0;
        received_count = 0;
        error_count    = 0;
        test_active    = 1'b0;

        #50;

        #7  rst00_n = 1'b1;
        #5  rst10_n = 1'b1;
        #9  rst01_n = 1'b1;
        #6  rst11_n = 1'b1;

        #100;
        test_active = 1'b1;

        #(RUN_TIME);
        test_active = 1'b0;

        #(DRAIN_TIME);

        $display("==========================================================");
        $display(" NoC 2x2 mesh self-checking testbench report");
        $display(" Total injected : %0d", exp_count);
        $display(" Total received : %0d", received_count);
        $display(" Errors (unexpected/duplicate/misrouted) : %0d", error_count);

        lost = 0;
        for (li = 0; li < exp_count; li = li + 1) begin
            if (exp_valid[li]) begin
                lost = lost + 1;
                $display("  LOST flit: src_tag=%0d dest_id=%0d payload=%0h  injected_at=%0t  age=%0t",
                          exp_payload[li][23:22], exp_dest[li], exp_payload[li], exp_time[li], $time - exp_time[li]);
            end
        end
        $display(" Lost flits     : %0d", lost);

        if (error_count == 0 && lost == 0)
            $display(" RESULT: PASS");
        else
            $display(" RESULT: FAIL");
        $display("==========================================================");

        $finish;
    end

    // Simulation timeout safety net, in case something deadlocks
    initial begin
        #(RUN_TIME + DRAIN_TIME + 10000);
        $display("[%0t] TIMEOUT -- simulation did not finish as expected", $time);
        $finish;
    end

endmodule
