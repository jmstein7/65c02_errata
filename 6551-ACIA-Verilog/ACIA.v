// File vhdl/ACIA.vhd translated with vhd2vl v3.0 VHDL to Verilog RTL translator
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

//--------------------------------------------------------------------------------
// Engineer: Matt Harlum <Matt@cactuar.net>
//
// Create Date:    13:10:55 07/10/2018
// Design Name: 6551 ACIA
// Module Name:    ACIA - rtl
// Description: Sythensizable 6551 ACIA
//
//
// Revision 0.01 - File Created
//
//--------------------------------------------------------------------------------
// no timescale needed

module ACIA(
input wire RESET,
input wire PHI2,
input wire CS,
input wire RWN,
input wire [1:0] RS,
input wire [7:0] DATAIN,
output reg [7:0] DATAOUT,
input wire XTLI,
output reg RTSB,
input wire CTSB,
output wire DTRB,
input wire RXD,
output wire TXD,
output wire IRQn
);




wire [7:0] RXDATA;
reg [7:0] TXDATA = 8'b00000000;
reg [3:0] R_SBR = 4'b0000;
reg [1:0] R_WDL = 2'b00;
reg [1:0] R_PMC = 2'b00;
reg [1:0] R_TIC = 2'b00;
wire BCLK;
wire RXFULL;
wire FRAME;
wire OVERFLOW;
wire PARITY;
reg RXTAKEN = 1'b0;
reg TXLATCH = 1'b0;
wire TXFULL;
reg R_SBN = 1'b0;
reg R_PME = 1'b0;
reg R_REM = 1'b0;
reg R_IRD = 1'b0;
reg R_DTR = 1'b0;
reg R_RCS = 1'b0;

  ACIA_RX C_RX(
      .RESET(RESET),
    .BCLK(BCLK),
    .PHI2(PHI2),
    .RX(RXD),
    .RXDATA(RXDATA),
    .RXFULL(RXFULL),
    .FRAME(FRAME),
    .OVERFLOW(OVERFLOW),
    .RXTAKEN(RXTAKEN),
    .PARITY(PARITY),
    .R_PMC(R_PMC),
    .R_PME(R_PME),
    .R_SBN(R_SBN));

  ACIA_TX C_TX(
      .RESET(RESET),
    .BCLK(BCLK),
    .PHI2(PHI2),
    .CTSB(CTSB),
    .TX(TXD),
    .TXDATA(TXDATA),
    .R_PME(R_PME),
    .R_PMC(R_PMC),
    .TXLATCH(TXLATCH),
    .TXFULL(TXFULL),
    .R_SBN(R_SBN));

  ACIA_BRGEN C_BRGEN(
      .RESET(RESET),
    .XTLI(XTLI),
    .BCLK(BCLK),
    .R_SBR(R_SBR));

  assign DTRB =  ~R_DTR;
  always @(negedge RESET, negedge PHI2) begin
    if((RESET == 1'b0)) begin
      TXLATCH <= 1'b0;
      R_REM <= 1'b0;
      R_TIC <= {2{1'b0}};
      R_IRD <= 1'b0;
      R_DTR <= 1'b0;
      R_SBN <= 1'b0;
      R_WDL <= {2{1'b0}};
      R_RCS <= 1'b0;
      R_SBR <= {4{1'b0}};
      RTSB <= 1'b1;
    end else begin
      if((CS == 1'b0 && RWN == 1'b0)) begin
        if((RS == 2'b00)) begin
          TXDATA <= DATAIN;
          TXLATCH <= 1'b1;
        end
        else if((RS == 2'b01)) begin
          //- RESET ---
        end
        else if((RS == 2'b10)) begin
          R_PMC <= DATAIN[7:6];
          R_PME <= DATAIN[5];
          R_REM <= DATAIN[4];
          R_TIC <= DATAIN[3:2];
          R_IRD <= DATAIN[1];
          R_DTR <= DATAIN[0];
          if(DATAIN[3:2] == 2'b00) begin
            RTSB <= 1'b1;
          end
          else begin
            RTSB <= 1'b0;
          end
        end
        else if((RS == 2'b11)) begin
          R_SBN <= DATAIN[7];
          R_WDL <= DATAIN[6:5];
          R_RCS <= DATAIN[4];
          R_SBR <= DATAIN[3:0];
        end
      end
      else begin
        TXLATCH <= 1'b0;
      end
    end
  end

  always @(negedge RESET, negedge PHI2) begin
    if(RESET == 1'b0) begin
      RXTAKEN <= 1'b0;
    end else begin
      if((CS == 1'b0 && RWN == 1'b1)) begin
        if((RS == 2'b00)) begin
          DATAOUT <= RXDATA;
          RXTAKEN <= 1'b1;
        end
        else if((RS == 2'b01)) begin
          DATAOUT[7] <=  ~IRQn;
          DATAOUT[6] <= 1'b0;
          DATAOUT[5] <= 1'b0;
          DATAOUT[4] <=  ~TXFULL;
          DATAOUT[3] <= RXFULL;
          DATAOUT[2] <= OVERFLOW;
          DATAOUT[1] <= FRAME;
          DATAOUT[0] <= PARITY;
        end
        else if((RS == 2'b10)) begin
          DATAOUT[7:6] <= R_PMC;
          DATAOUT[5] <= R_PME;
          DATAOUT[4] <= R_REM;
          DATAOUT[3:2] <= R_TIC;
          DATAOUT[1] <= R_IRD;
          DATAOUT[0] <= R_DTR;
        end
        else if((RS == 2'b11)) begin
          DATAOUT[7] <= R_SBN;
          DATAOUT[6:5] <= R_WDL;
          DATAOUT[4] <= R_RCS;
          DATAOUT[3:0] <= R_SBR;
        end
      end
      else begin
        RXTAKEN <= 1'b0;
      end
    end
  end

  assign IRQn = (((TXFULL == 1'b0 && R_TIC == 2'b01) || (RXFULL == 1'b1 && R_IRD == 1'b0)) && R_DTR == 1'b1) ? 1'b0 : 1'b1;

endmodule
