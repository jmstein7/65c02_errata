`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/03/2021 07:56:28 PM
// Design Name: 
// Module Name: top
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

module top(
    input clk,
    input reset,
    inout logic [7:0] data_io,
    output reg [15:0] address,
    output rwb,
    output phi2,
    output led_a,
    output wire resb
    );

    wire rdy = 1'b1;
    wire WE, RE, rom_e, ram_e; 
    logic [7:0] read;
    logic [7:0] write; 
    logic [7:0] write_bus; 
    logic [7:0] read_bus; 
    reg [7:0] rom_read; 
    reg [7:0] ram_read; 
    reg [7:0] ram_write; 
    logic [15:0] AD; 
    logic [15:0] address_bus; 
    logic [7:0] DO; 
    logic [7:0] DI; 
    
    assign phi2 = clk; 
    assign DO = write_bus; 
    assign data_io = (WE || (RE && rom_e) || (RE && ram_e)) ? DO : 'bZ;
    assign DI = data_io;
    
    assign resb = ~reset; 
    assign address_bus = AD; 
    //assign address = address_bus; 
    assign RE = ~WE;
    assign rwb = RE; 
    assign led_a = resb; 
    
    assign rom_e = (address_bus >= 16'hc000) ? 1'b1 : 1'b0; 
    assign ram_e = (address_bus < 16'h8000) ? 1'b1 : 1'b0; 
    
    assign ram_write = (WE && ram_e) ? write : 'bZ; 
    assign read_bus = DI; 
    
    assign read = (RE && ram_e) ? ram_read : ((RE && rom_e) ? rom_read : read_bus); 
    assign write_bus = (WE) ? write : ((RE && rom_e) ? rom_read : ram_read); 
    
    //external address pads
    always @(posedge clk)
    if( rdy )
        address <= address_bus;
    
//debouncer debouncer_a(
    //.clk(clk),
    //.switch_input(reset),
    //.state(reset_state),
    //.trans_up(),
    //.trans_dn()
    //);

cpu_65c02 cpu_alpha( 
     .clk(clk),                          // CPU clock
     .reset(reset),                          // RST signal
     .AB(AD),                   // address bus 
     .DI(read),                     // data bus input
     .DO(write),                // data bus output 
     .WE(WE),                          // write enable
     .IRQ(),                          // interrupt request
     .NMI(),                          // non-maskable interrupt request
     .RDY(rdy)                         // Ready signal. Pauses CPU when RDY=0
     );                      // debug for simulation

SFOT_ram RAM_alpha(
        .addra(address_bus),  // Address bus, width determined from RAM_DEPTH
        .dina(ram_write),           // RAM input data
        .clk(clk),                           // Clock
        .wea(WE),                            // Write enable
        .ena(ram_e),                            // RAM Enable, for additional power savings, disable port when not in use
        .douta(ram_read)                   // RAM output data

    );

SFOT_ROM_16k ROM_alpha(
		.clk(clk),
        .rom_enable(rom_e),
        .read(RE),
        .addra(address_bus),
        .douta(rom_read)
    );
endmodule
