`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/15/2021 10:30:18 AM
// Design Name: 
// Module Name: top_peri
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_peri(
    input clk,
    input wire rwb,
    input wire resb,
    input wire ext_bus, 
    input wire via_ca1,
    input wire [12:0] addr,
    inout logic [7:0] dio,
    //6522 ports
    inout logic [7:0] via_port_a,
    inout logic [7:0] via_port_b,
    inout wire via_ca2,
    inout wire via_cb1,
    inout wire via_cb2,
    //clock out
    output wire phi2
    );

   // Clock-enable counter size - the CPU runs at:
   // system clock rate / (2 ** CLKEN_BITS)
   parameter CLKEN_BITS = 2;
    
   // VIA signals
   wire via_e;
   logic [7:0] via_dout;
   reg [7:0] via_dout_r;

   wire via_ca2_in;
   wire via_ca2_out;
   wire via_ca2_oe_n;
   logic [7:0] via_pa_in;
   logic [7:0] via_pa_out;
   logic [7:0] via_pa_oe_n;
   wire via_cb1_in;
   wire via_cb1_out;
   wire via_cb1_oe_n;
   wire via_cb2_in;
   wire via_cb2_out;
   wire via_cb2_oe_n;
   logic [7:0] via_pb_in;
   logic [7:0] via_pb_out;
   logic [7:0] via_pb_oe_n;    

   // Clock Enable signals
   reg [CLKEN_BITS-1:0] clken_ctr = 0;
   reg cpu_clken;
   reg via_clken;

   // ========================================================
   // Clock Enable Generation
   // (currently active one in four cycles)
   // ========================================================

   // Note: this block does not use a reset to ensure everything
   // keeps being clocked when reset is asserted.
   always @(posedge clk) begin
      clken_ctr <= clken_ctr + 1'b1;
      cpu_clken <= &clken_ctr; // active when all 1's
      via_clken <= cpu_clken;
   end

   // ========================================================
   // VIA
   // ========================================================

   assign via_e = ((ext_bus == 0) && (addr >= 16'h0800 && addr <= 16'h080F));

   m6522 via_alpha
     (
      .CLK(clk),
      .RESET_L(resb),
      .I_P2_H(via_clken),        // clock enable for CPU interface
      .ENA_4(1'b1),              // clock enable for counters/timers
      .I_RS(addr[3:0]),
      .I_DATA(cpu_dout),
      .O_DATA(via_dout),
      .O_DATA_OE_L(),
      .I_RW_L(!cpu_we),
      .I_CS1(via_e),
      .I_CS2_L(1'b0),
      .O_IRQ_L(), // not open drain
      // port a
      .I_CA1(via_ca1),
      .I_CA2(via_ca2_in),
      .O_CA2(via_ca2_out),
      .O_CA2_OE_L(via_ca2_oe_n),
      .I_PA(via_pa_in),
      .O_PA(via_pa_out),
      .O_PA_OE_L(via_pa_oe_n),
      // port b
      .I_CB1(via_cb1_in),
      .O_CB1(via_cb1_out),
      .O_CB1_OE_L(via_cb1_oe_n),
      .I_CB2(via_cb2_in),
      .O_CB2(via_cb2_out),
      .O_CB2_OE_L(via_cb2_oe_n),
      .I_PB(via_pb_in),
      .O_PB(via_pb_out),
      .O_PB_OE_L(via_pb_oe_n)
      );

   always @(posedge clk) begin
      if (via_clken) begin
         via_dout_r <= via_dout;
      end
   end

   assign via_port_a = (!via_pa_oe_n) ? via_pa_out : 8'hZZ;
   assign via_pa_in = via_port_a;

   assign via_port_b = (!via_pb_oe_n) ? via_pb_out : 8'hZZ;
   assign via_pb_in = via_port_b;

   assign via_ca2 = (!via_ca2_oe_n) ? via_ca2_out : 1'bZ;
   assign via_ca2_in = via_ca2;

   assign via_cb2 = (!via_cb2_oe_n) ? via_cb2_out : 1'bZ;
   assign via_cb2_in = via_cb2;

   assign via_cb1 = (!via_cb1_oe_n) ? via_cb1_out : 1'bZ;
   assign via_cb1_in = via_cb1;
    
endmodule
