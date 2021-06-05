`timescale 1ns/1ns

// 10MHz 6502 Clock
`define T_clock 100

// 1.8432MHz ACIA Clock
`define T_acia_clock 542

module top_tb;

   reg clk;
   reg reset;
   reg acia_clk;
   reg rxd;
   reg cts;
   
   wire txd;
   wire rts;

   wire [7:0] data_io;

   wire [15:0] address;
   wire        rwb;
   wire        phi2;
   wire        led_a;
   wire        resb;

   reg [7:0]   write_data = 8'hZZ;

   wire        acia_select;

initial  begin
   $dumpvars();
   clk   = 1'b0;
   acia_clk   = 1'b0;
   rxd   = 1'b1;
   cts   = 1'b0;   
   reset = 1'b0;
   repeat(10) begin
      @(posedge clk);
   end
   reset = 1'b1;
   repeat(10) begin
      @(posedge clk);
   end
   reset = 1'b0;
   #(`T_clock * 200000)
   $finish;
end

always #(`T_clock / 2) begin
   clk = ~clk;
end

always #(`T_acia_clock / 2) begin
   acia_clk = ~acia_clk;
end

// assign  acia_select = ({address[15:2], 2'b0} == 16'h8000);

// always @(posedge clk) begin
//   if (!rwb && acia_select && address[1:0] == 2'b00) begin
//      $display("%x %c", data_io, data_io);
//   end
// end


// Unit under test
top top
  (
   .clk(clk),
   .acia_clk(acia_clk),
   .rxd(rxd),
   .cts(cts),
   .txd(txd),
   .rts(rts),
   .reset(reset),
   .data_io(data_io),
   .address(address),
    .rwb(rwb),
   .phi2(phi2),
   .led_a(led_a),
   .resb(resb)
   );


endmodule
