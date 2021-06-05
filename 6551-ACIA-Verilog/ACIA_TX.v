// File ACIA_TX.vhd translated with vhd2vl v3.0 VHDL to Verilog RTL translator
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

module ACIA_TX(
input wire RESET,
input wire PHI2,
input wire BCLK,
input wire CTSB,
output reg TX,
input wire [7:0] TXDATA,
input wire R_PME,
input wire [1:0] R_PMC,
input wire R_SBN,
input wire TXLATCH,
output reg TXFULL
);




parameter [2:0]
  state_Idle = 0,
  state_Start = 1,
  state_Data = 2,
  state_Parity = 3,
  state_Stop = 4,
  state_Stop2 = 5;

reg [2:0] r_tx_fsm = state_Idle;
reg [31:0] r_clk = 0;
reg [31:0] r_bitcnt = 0;
reg [7:0] r_tx_shiftreg = 8'b00000000;
reg r_tx_parity;
reg [7:0] r_txdata = 8'b00000000;
reg r_txready = 1'b0;
reg r_txtaken = 1'b0;

  always @(posedge PHI2, posedge RESET) begin
    if(RESET == 1'b0) begin
      r_txdata <= {8{1'b0}};
      TXFULL <= 1'b0;
    end else begin
      if(TXLATCH == 1'b1) begin
        r_txdata <= TXDATA;
        r_txready <= 1'b1;
        TXFULL <= 1'b1;
      end
      else begin
        if((r_txready == 1'b1 && r_txtaken == 1'b1)) begin
          r_txready <= 1'b0;
          TXFULL <= 1'b0;
        end
      end
    end
  end

  always @(posedge BCLK, posedge RESET) begin
    if(RESET == 1'b0) begin
      r_clk <= 0;
      r_bitcnt <= 0;
      r_tx_fsm <= state_Idle;
      r_txtaken <= 1'b0;
      r_tx_parity <= 1'b0;
    end else begin
      case(r_tx_fsm)
      state_Idle : begin
        TX <= 1'b1;
        r_clk <= 0;
        r_tx_parity <= 1'b0;
        if(r_txready == 1'b1 && CTSB == 1'b0) begin
          r_tx_shiftreg <= r_txdata;
          r_tx_fsm <= state_Start;
          r_txtaken <= 1'b1;
        end
      end
      state_Start : begin
        TX <= 1'b0;
        r_txtaken <= 1'b0;
        if(r_clk == 15) begin
          r_tx_fsm <= state_Data;
          r_clk <= 0;
        end
        else begin
          r_clk <= r_clk + 1;
        end
      end
      state_Data : begin
        TX <= r_tx_shiftreg[0];
        if(r_clk < 15) begin
          r_clk <= r_clk + 1;
          r_tx_fsm <= state_Data;
        end
        else begin
          r_tx_parity <= r_tx_parity ^ r_tx_shiftreg[0];
          r_clk <= 0;
          if(r_bitcnt < 7) begin
            r_tx_shiftreg[6:0] <= r_tx_shiftreg[7:1];
            r_tx_shiftreg[7] <= 1'b0;
            r_bitcnt <= r_bitcnt + 1;
            r_tx_fsm <= state_Data;
          end
          else begin
            r_bitcnt <= 0;
            if(R_PME == 1'b1) begin
              r_tx_fsm <= state_Parity;
            end
            else begin
              r_tx_fsm <= state_Stop;
            end
          end
        end
      end
      state_Parity : begin
        case(R_PMC)
        2'b00 : begin
          // Odd Parity
          TX <=  ~r_tx_parity;
        end
        2'b01 : begin
          // Even Parity
          TX <= r_tx_parity;
        end
        2'b10 : begin
          // Mark Parity
          TX <= 1'b1;
        end
        2'b11 : begin
          // Space Parity
          TX <= 1'b0;
        end
        default : begin
          TX <= r_tx_parity;
        end
        endcase
        if(r_clk < 15) begin
          r_tx_fsm <= state_Parity;
          r_clk <= r_clk + 1;
        end
        else begin
          r_clk <= 0;
          r_tx_fsm <= state_Stop;
        end
      end
      state_Stop : begin
        TX <= 1'b1;
        if(r_clk == 15) begin
          r_clk <= 0;
          if((R_SBN == 1'b1) && (R_PME == 1'b0)) begin
            r_tx_fsm <= state_Stop2;
          end
          else begin
            r_tx_fsm <= state_Idle;
          end
        end
        else begin
          r_clk <= r_clk + 1;
        end
      end
      state_Stop2 : begin
        if(r_clk == 15) begin
          r_clk <= 0;
          r_tx_fsm <= state_Idle;
        end
        else begin
          r_clk <= r_clk + 1;
          r_tx_fsm <= state_Stop2;
        end
      end
      default : begin
        r_tx_fsm <= state_Idle;
      end
      endcase
    end
  end


endmodule
