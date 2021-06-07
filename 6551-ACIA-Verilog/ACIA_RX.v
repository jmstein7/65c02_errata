// File ACIA_RX.vhd translated with vhd2vl v3.0 VHDL to Verilog RTL translator
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

module ACIA_RX(
input wire RESET,
input wire PHI2,
input wire BCLK,
input wire RX,
output reg [7:0] RXDATA,
output reg RXFULL,
input wire RXTAKEN,
output reg FRAME,
output reg OVERFLOW,
output reg PARITY,
input wire [1:0] R_PMC,
input wire R_PME,
input wire R_SBN
);




parameter [2:0]
  state_Idle = 0,
  state_Start = 1,
  state_Data = 2,
  state_Parity = 3,
  state_Stop = 4,
  state_Stop2 = 5;

reg [2:0] r_rx_fsm = state_Idle;
reg [3:0] r_clkdiv = 0;
reg [2:0] r_bitcnt = 0;
reg [7:0] r_rx_shiftreg = 8'b00000000;
reg r_rx_parity = 1'b0;
reg r_rxreq = 1'b0;
reg r_rxreceive = 1'b0;

  always @(posedge BCLK, negedge RESET) begin
    if(RESET == 1'b0) begin
      r_clkdiv <= 0;
      r_bitcnt <= 0;
      RXDATA <= {8{1'b0}};
      r_rx_shiftreg <= {8{1'b0}};
      r_rx_fsm <= state_Idle;
      FRAME <= 1'b0;
      OVERFLOW <= 1'b0;
      PARITY <= 1'b0;
      r_rxreceive <= 1'b0;
    end else begin
      case(r_rx_fsm)
      state_Idle : begin
        r_rx_parity <= 1'b0;
        r_rxreceive <= 1'b0;
        r_clkdiv <= 0;
        if(RX == 1'b0) begin
          r_rx_fsm <= state_Start;
        end
      end
      state_Start : begin
        if(r_clkdiv == 7) begin
          if(RX == 1'b0) begin
            r_rx_fsm <= state_Data;
            r_clkdiv <= 0;
          end
          else begin
            r_rx_fsm <= state_Idle;
          end
        end
        else begin
          r_clkdiv <= r_clkdiv + 1'b1;
        end
      end
      state_Data : begin
        r_rxreceive <= 1'b1;
        if(r_clkdiv < 15) begin
          r_clkdiv <= r_clkdiv + 1'b1;
          r_rx_fsm <= state_Data;
        end
        else begin
          r_clkdiv <= 0;
          r_rx_shiftreg[6:0] <= r_rx_shiftreg[7:1];
          r_rx_shiftreg[7] <= RX;
          r_rx_parity <= r_rx_parity ^ RX;
          if(r_bitcnt < 7) begin
            r_bitcnt <= r_bitcnt + 1'b1;
            r_rx_fsm <= state_Data;
          end
          else begin
            r_bitcnt <= 0;
            if(R_PME == 1'b0) begin
              r_rx_fsm <= state_Stop;
            end
            else begin
              r_rx_fsm <= state_Parity;
            end
          end
        end
      end
      state_Parity : begin
        if(r_clkdiv == 15) begin
          if(R_PMC[1] == 1'b1) begin
            // RX Parity ignored
            PARITY <= 1'b0;
          end
          else if(R_PMC[0] == 1'b0) begin
            //- Odd Parity
            if(r_rx_parity == ( ~RX)) begin
              PARITY <= 1'b0;
            end
            else begin
              PARITY <= 1'b1;
            end
          end
          else begin
            // Even Parity
            if(r_rx_parity == RX) begin
              PARITY <= 1'b0;
            end
            else begin
              PARITY <= 1'b1;
            end
          end
          r_clkdiv <= 0;
          r_rx_fsm <= state_Stop;
        end
        else begin
          r_clkdiv <= r_clkdiv + 1'b1;
        end
      end
      state_Stop : begin
        if(r_clkdiv == 15) begin
          if(RX == 1'b0) begin
            FRAME <= 1'b1;
          end
          else begin
            FRAME <= 1'b0;
          end
          if(RXFULL == 1'b1) begin
            OVERFLOW <= 1'b1;
          end
          else begin
            RXDATA <= r_rx_shiftreg;
            OVERFLOW <= 1'b0;
          end
          r_clkdiv <= 0;
          if((R_SBN == 1'b1) && (R_PME == 1'b0)) begin
            r_rx_fsm <= state_Stop2;
          end
          else begin
            r_rx_fsm <= state_Idle;
          end
          r_clkdiv <= 0;
        end
        else begin
          r_clkdiv <= r_clkdiv + 1'b1;
        end
      end
      state_Stop2 : begin
        if(r_clkdiv == 15) begin
          r_clkdiv <= 0;
          r_rx_fsm <= state_Idle;
        end
        else begin
          r_clkdiv <= r_clkdiv + 1'b1;
          r_rx_fsm <= state_Stop2;
        end
      end
      default : begin
        r_rxreceive <= 1'b0;
        r_rx_fsm <= state_Idle;
      end
      endcase
    end
  end

  always @(posedge PHI2, negedge RESET) begin
    if(RESET == 1'b0) begin
      RXFULL <= 1'b0;
      r_rxreq <= 1'b0;
    end else begin
      if(RXTAKEN == 1'b1) begin
        RXFULL <= 1'b0;
        r_rxreq <= 1'b1;
      end
      else if(r_rxreq == 1'b1 && r_rxreceive == 1'b1) begin
        r_rxreq <= 1'b0;
      end
      else if(r_rxreq == 1'b0 && r_rxreceive == 1'b0) begin
        RXFULL <= 1'b1;
      end
    end
  end


endmodule
