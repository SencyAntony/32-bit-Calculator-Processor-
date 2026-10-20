# 32-bit-Calculator-Processor

This project implements a simple 32-bit instruction-driven calculator processor using Verilog HDL. The design integrates a Register File, Arithmetic Logic Unit (ALU), Instruction Register, Write-Back Register, and FSM-based Control Unit.
The processor accepts 16-bit instructions, decodes the opcode and register fields, performs arithmetic or logical operations, and writes the result back to a destination register. The design was verified using Vivado simulation and implemented on FPGA hardware.

## 🎯 Project Objectives
 
- Design a 32-bit processor-like calculator architecture.
- Implement arithmetic and logical operations directly in hardware using Verilog HDL.
- Understand instruction encoding and decoding mechanisms.
- Design and implement an 8 × 32-bit register file with read and write functionality.
- Develop an FSM-based control unit for instruction execution and datapath control.
- Implement a write-back mechanism for storing computation results.
- Support immediate data loading using a signed 9-bit immediate field.
- Verify and validate the processor functionality through simulation and testbench development.
- Implement and demonstrate the design on FPGA hardware.
- Gain practical experience in RTL design, FPGA synthesis, and hardware debugging.
