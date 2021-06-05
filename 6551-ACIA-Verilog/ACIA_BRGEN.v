// File ACIA_BRGEN.vhd translated with vhd2vl v3.0 VHDL to Verilog RTL translator
// vhd2vl settings:
//  * Verilog Module Declaration Style: 2001

// vhd2vl is Free (libre) Software:
//   Copyright (C) 2001 Vincenzo Liguori - Ocean Logic Pty Ltd
//     http://www.ocean-logic.com
//   Modifications Copyright (C) 2006 Mark Gonzales - PMC Sierra Inc
//   Modifications (C) 2010 Shankar Giri
//   Modifications Copyright (C) 2002-2017 Larry Doolittle
//     http://doolittle.icarus.com/~larry/vhd2vl/
//   Modifications (C) 2017 Rodrigo A. Melo
//
//   vhd2vl comes with ABSOLUTELY NO WARRANTY.  Always check the resulting
//   Verilog for correctness, ideally with a formal verification tool.
//
//   You are welcome to redistribute vhd2vl under certain conditions.
//   See the license (GPLv2) file included with the source for details.

// The result of translation follows.  Its copyright status should be
// considered unchanged from the original VHDL.

// no timescale needed

module ACIA_BRGEN(
input wire RESET,
input wire XTLI,
output wire BCLK,
input wire [3:0] R_SBR
);




reg [31:0] r_clk = 0;
reg r_bclk = 1'b0;

  assign BCLK = (R_SBR == 3'b000) ? XTLI : r_bclk;
  always @(posedge XTLI, posedge RESET) begin
    if((RESET == 1'b0)) begin
      r_clk <= 0;
      r_bclk <= 1'b0;
    end else begin
      if((r_clk == 0)) begin
        r_bclk <=  ~r_bclk;
        case(R_SBR)
        4'b0000 : begin
          r_clk <= 0;
        end
        4'b0001 : begin
          r_clk <= (36864 - 1) / 32;
        end
        4'b0010 : begin
          r_clk <= (24576 - 1) / 32;
        end
        4'b0011 : begin
          r_clk <= (16769 - 1) / 32;
        end
        4'b0100 : begin
          r_clk <= (13704 - 1) / 32;
        end
        4'b0101 : begin
          r_clk <= (12288 - 1) / 32;
        end
        4'b0110 : begin
          r_clk <= (6144 - 1) / 32;
        end
        4'b0111 : begin
          r_clk <= (3072 - 1) / 32;
        end
        4'b1000 : begin
          r_clk <= (1536 - 1) / 32;
        end
        4'b1001 : begin
          r_clk <= (1024 - 1) / 32;
        end
        4'b1010 : begin
          r_clk <= (768 - 1) / 32;
        end
        4'b1011 : begin
          r_clk <= (512 - 1) / 32;
        end
        4'b1100 : begin
          r_clk <= (384 - 1) / 32;
        end
        4'b1101 : begin
          r_clk <= (256 - 1) / 32;
        end
        4'b1110 : begin
          r_clk <= (192 - 1) / 32;
        end
        4'b1111 : begin
          r_clk <= (96 - 1) / 32;
        end
        default : begin
          r_clk <= 0;
        end
        endcase
      end
      else begin
        r_clk <= r_clk - 1;
      end
    end
  end


endmodule
