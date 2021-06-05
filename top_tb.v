`timescale 1ns/1ns

`define T_clock 100

module top_tb;

   reg clk;
   reg reset;

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
   reset = 1'b0;
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   reset = 1'b1;
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   reset = 1'b0;
   #(`T_clock * 200000)
   $finish;
end

always #(`T_clock / 2) begin
   clk = ~clk;
end

assign  acia_select = ({address[15:2], 2'b0} == 16'h8000);

always begin
   @(negedge clk) write_data <= (rwb && acia_select && address[1:0] == 2'b01) ? 8'h10 : 8'hZZ;
   @(posedge clk) write_data <= 8'hZZ;
end

always @(posedge clk) begin
   if (!rwb && acia_select && address[1:0] == 2'b00) begin
      $display("%x %c", data_io, data_io);
   end
end

assign data_io = write_data;


// Unit under test
top top
  (
   .clk(clk),
   .reset(reset),
   .data_io(data_io),
   .address(address),
    .rwb(rwb),
   .phi2(phi2),
   .led_a(led_a),
   .resb(resb)
   );


endmodule
