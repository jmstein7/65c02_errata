
`timescale 1 ns / 1 ps

	module SFOT_ram #
	(
        parameter RAM_WIDTH = 8,                 // Specify RAM data width
        parameter RAM_DEPTH = 32768,                  // Specify RAM depth (number of entries)
        parameter INIT_FILE = ""                       // Specify name/location of RAM initialization file if using one (leave blank if not)

	)
	(
		// Users to add ports here
        input wire [15:0] addra,  // Address bus, width determined from RAM_DEPTH
        input wire [7:0] dina,           // RAM input data
        input clk,                           // Clock
        input wea,                            // Write enable
        input ena,                            // RAM Enable, for additional power savings, disable port when not in use
        output wire [7:0] douta                   // RAM output data

	);


  reg [RAM_WIDTH-1:0] ram_name [RAM_DEPTH-1:0];
  reg [RAM_WIDTH-1:0] ram_data = {RAM_WIDTH{1'b0}};

  generate
    if (INIT_FILE != "") begin: use_init_file
      initial
        $readmemh(INIT_FILE, ram_name, 0, RAM_DEPTH-1);
    end else begin: init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
          ram_name[ram_index] = {RAM_WIDTH{1'b0}};
    end
  endgenerate

  always @(posedge clk)
    if (ena) begin
      if (wea && clk ==1)
        ram_name[addra] <= dina;
      else if (~wea)
        ram_data <= ram_name[addra];
    end
      
    assign douta = ram_data;

	endmodule
