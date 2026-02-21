# Single-Cycle MIPS Processor (Verilog)

This project implements a 32-bit single-cycle MIPS processor in Verilog HDL.

## Architecture
- Single-cycle datapath
- Modular RTL design
- Separate instruction and data memory

## Modules
- processor.v (Top module)
- control.v (Main control unit)
- alucont.v (ALU control)
- alu32.v (32-bit ALU)

## Supported Instructions
R-Type:
- ADD
- SUB
- AND
- OR
- SLT

I-Type:
- LW
- SW
- BEQ
- ADDI

J-Type:
- J

## Features
- 32-bit architecture
- Zero flag generation
- Branch and jump support
- Memory initialization via .dat files
