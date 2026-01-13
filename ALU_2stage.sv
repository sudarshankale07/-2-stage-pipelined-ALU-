
import alu_defines::*;

module alu_pipelined #(
    parameter int DATA_WIDTH = 32
    
)(
    input clk,
    input rst_n,      
    input flush,     

    
    input  logic valid_in,
    input  logic [DATA_WIDTH-1:0] a,
    input  logic [DATA_WIDTH-1:0] b,
    input  alu_op_t               op,

   
    output logic  valid_out,
    output logic [DATA_WIDTH-1:0] y
);

  
    // Stage 1: Input register stage
   
    logic s1_valid;
    logic [DATA_WIDTH-1:0]   s1_a, s1_b;
    alu_op_t  s1_op;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_valid <= 1'b0;
            s1_a     <= '0;
            s1_b     <= '0;
            s1_op    <= ALU_ADD;
        end else begin
            if (flush) begin
                s1_valid <= 1'b0;
            end else begin
                s1_valid <= valid_in;
                s1_a     <= a;
                s1_b     <= b;
                s1_op    <= op;
            end
        end
    end

   
    // Stage 2: Execute and output stage
   
    logic s2_valid;
    logic [DATA_WIDTH-1:0]   s2_y;

  
    always_comb begin
        automatic logic [4:0] shamt = s1_b[4:0]; 
        unique case (s1_op)
            ALU_ADD: s2_y = s1_a + s1_b;
            ALU_SUB: s2_y = s1_a - s1_b;
            ALU_AND: s2_y = s1_a & s1_b;
            ALU_OR:  s2_y = s1_a | s1_b;
            ALU_XOR: s2_y = s1_a ^ s1_b;
            ALU_SLL: s2_y = s1_a << shamt;
            ALU_SRL: s2_y = s1_a >> shamt;
            default: s2_y = 'x;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2_valid <= 1'b0;
            y        <= '0;
        end else begin
            if (flush) begin
                s2_valid <= 1'b0;
                y        <= '0;
            end else begin
                s2_valid <= s1_valid;
                y        <= s2_y;
            end
        end
    end

    assign valid_out = s2_valid;

endmodule
