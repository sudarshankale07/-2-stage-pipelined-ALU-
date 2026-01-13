// tb_alu_pipelined_simple.sv
`timescale 1ns/1ps

import alu_defines::*;

module tb_alu_pipelined;

    localparam int DATA_WIDTH = 32;
    localparam int LATENCY    = 2;

    logic clk, rst_n, flush, valid_in, valid_out;
    logic [DATA_WIDTH-1:0] a, b, y;
    alu_op_t op;

    // Transaction queue with simplified struct (no cycle tracking)
    typedef struct {
        logic [DATA_WIDTH-1:0] a;
        logic [DATA_WIDTH-1:0] b;
        alu_op_t               op;
    } txn_t;

    txn_t expected_queue[$];

    // DUT
    alu_pipelined #(.DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(clk), .rst_n(rst_n), .flush(flush),
        .valid_in(valid_in), .a(a), .b(b), .op(op),
        .valid_out(valid_out), .y(y)
    );

    // Golden function
    function automatic logic [DATA_WIDTH-1:0] golden(
        input logic [DATA_WIDTH-1:0] a,
        input logic [DATA_WIDTH-1:0] b,
        input alu_op_t op
    );
        automatic logic [4:0] shamt = b[4:0];
        case (op)
            ALU_ADD: return a + b;
            ALU_SUB: return a - b;
            ALU_AND: return a & b;
            ALU_OR:  return a | b;
            ALU_XOR: return a ^ b;
            ALU_SLL: return a << shamt;
            ALU_SRL: return a >> shamt;
            default: return 'x;
        endcase
    endfunction

    // Checker variables
    txn_t checker_exp;
    logic [DATA_WIDTH-1:0] checker_ref;

    // Checker block
    always @(posedge clk) begin
        if (valid_out) begin
            if (expected_queue.size() == 0) begin
                $error("[%0t] Unexpected valid_out with empty queue!", $time);
                $finish;
            end else begin
                checker_exp = expected_queue.pop_front();
                checker_ref = golden(checker_exp.a, checker_exp.b, checker_exp.op);
                
                if (y !== checker_ref) begin
                    $error("[%0t] MISMATCH! %s(0x%0h, 0x%0h): y=0x%0h, expected=0x%0h",
                        $time, checker_exp.op.name(), checker_exp.a, checker_exp.b, y, checker_ref);
                    $finish;
                end else begin
                    $display("[%0t] PASS: %s(0x%0h, 0x%0h) = 0x%0h", 
                        $time, checker_exp.op.name(), checker_exp.a, checker_exp.b, y);
                end
            end
        end
    end

    // Send transaction task - FIXED VERSION
    task send_txn(
        input logic [DATA_WIDTH-1:0] a_val,
        input logic [DATA_WIDTH-1:0] b_val,
        input alu_op_t op_val,
        input bit do_flush = 0
    );
        // Set up inputs BEFORE the clock edge
        @(negedge clk);  // Use negedge to avoid race conditions
        valid_in = 1'b1;
        a = a_val;
        b = b_val;
        op = op_val;
        flush = do_flush;
        
        // Wait for the posedge when DUT samples
        @(posedge clk);
        
        // Add to expected queue AFTER DUT has sampled (if not flushing)
        if (!do_flush) begin
            txn_t t;
            t.a = a_val;
            t.b = b_val;
            t.op = op_val;
            expected_queue.push_back(t);
        end
        
        // Clear control signals
        @(negedge clk);
        valid_in = 1'b0;
        flush = 1'b0;
    endtask

    // Test sequence
    initial begin
        clk = 0;
        rst_n = 0;
        flush = 0;
        valid_in = 0;
        a = 0;
        b = 0;
        op = ALU_ADD;

        // Hold reset for a few cycles
        repeat(3) @(posedge clk);
        @(negedge clk);
        rst_n = 1;
        
        // Wait for reset to take effect
        repeat(2) @(posedge clk);

        $display("=== Basic Tests ===");
        send_txn(16, 5, ALU_ADD);
        send_txn(32, 8, ALU_SUB);
        send_txn(255, 15, ALU_AND);
        send_txn(1, 2, ALU_OR);
        send_txn(170, 85, ALU_XOR);
        send_txn(1, 4, ALU_SLL);
        send_txn(16, 2, ALU_SRL);

        // Wait for all outputs
        repeat(10) @(posedge clk);

        $display("\n=== Flush Test ===");
        send_txn(100, 50, ALU_ADD);
        send_txn(200, 10, ALU_SUB);
        send_txn(300, 30, ALU_XOR, 1); // flushed - should not appear in output
        send_txn(400, 40, ALU_OR);

        repeat(10) @(posedge clk);

        $display("\n=== Reset Test ===");
        send_txn(999, 111, ALU_ADD);
        @(posedge clk);
        @(negedge clk);
        rst_n = 0;  // Assert reset while transaction is in pipeline
        expected_queue.delete();  // Clear queue - reset discards in-flight transactions
        repeat(2) @(posedge clk);
        @(negedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);

        // Check if queue is empty (all transactions processed)
        if (expected_queue.size() != 0) begin
            $error("Test ended with %0d transactions still in queue!", expected_queue.size());
        end else begin
            $display("\n✅ All Tests Passed!");
        end
        
        $finish;
    end

    // Clock generator
    always #5 clk = ~clk;

endmodule