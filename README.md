# -2-stage-pipelined-ALU-
This project implements a parameterized 2-stage pipelined ALU that performs arithmetic and logical operations with configurable data width and built-in pipeline control features including flush and reset.
7 ALU Operations:
Addition (ADD)
Subtraction (SUB)
Bitwise AND
Bitwise OR
Bitwise XOR
Logical Shift Left (SLL)
Logical Shift Right (SRL)


Pipeline Control:
Asynchronous active-low reset
Synchronous flush capability
Valid signal propagation


Comprehensive Verification: Self-checking testbench with golden reference model
Pipeline Latency: 2 clock cycles from input to output

.📁 Project Structure
├── alu_defines.sv           # ALU operation type definitions
├── ALU_2stage.sv            # Pipelined ALU RTL implementation
└── ALU_2stage_tb.sv         # Self-checking testbench
