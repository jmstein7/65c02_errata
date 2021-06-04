
`timescale 1 ns / 1 ps

    (* rom_style="{block}" *)

	module SFOT_ROM_16k #
	(
		parameter ROM_WIDTH = 8,
        parameter ROM_ADDR_BITS = 14
	)
		
	(
		input clk,
        input rom_enable,
        input read,
        input [15:0] addra,
        output [7:0] douta
	);

    reg [ROM_WIDTH-1:0] rom_name [(2**ROM_ADDR_BITS)-1:0];
    reg [ROM_WIDTH-1:0] output_data;
    
    initial
      $readmemh("rtest_hex.txt", rom_name, 0, (2**ROM_ADDR_BITS)-1);

    always @(posedge clk)
      if (rom_enable && read) begin
         output_data <= rom_name[addra];
      end 
      
    assign douta = output_data; 

	endmodule
