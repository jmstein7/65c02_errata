#!/bin/bash

iverilog top_tb.v top.sv cpu_65c02.v SFOT_RAM32.v rom_unit.v ALU.v m6522.v 6551-ACIA-Verilog/*.v
./a.out
gtkwave  dump.vcd top_tb.gtkw
