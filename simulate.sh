#!/bin/bash

iverilog top_tb.v top.sv cpu_65c02.v SFOT_RAM32.v rom_unit.v ALU.v
./a.out
gtkwave  dump.vcd top_tb.gtkw
