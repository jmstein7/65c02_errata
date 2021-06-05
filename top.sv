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
    inout wire [7:0] data_io,
    output reg [15:0] address,
    output reg rwb,
    output phi2,
    output led_a,
    output wire resb
    );

    wire rdy = 1'b1;
    wire WE, RE, rom_e, ram_e;
    wire [7:0] read;
    wire [7:0] write;
    wire [7:0] read_bus;
    wire [7:0] rom_read;
    wire [7:0] ram_read;
    wire [7:0] ram_write;
    wire [15:0] AD;
    wire [15:0] address_bus;


    assign phi2 = clk;
    assign resb = ~reset;
    assign address_bus = AD;
    //assign address = address_bus;
    assign RE = ~WE;
    assign led_a = resb;

    assign rom_e = (address_bus >= 16'hc000) ? 1'b1 : 1'b0;
    assign ram_e = (address_bus < 16'h8000) ? 1'b1 : 1'b0;
    assign ram_write = (WE && ram_e) ? write : 'bZ;

// Delay mux select signals to line up with RAM/ROM outputs
    reg ram_select;
    reg rom_select;
    always @(posedge clk) begin
        ram_select <= RE && ram_e;
        rom_select <= RE && rom_e;
    end
    assign read = ram_select ? ram_read : (rom_select ? rom_read : read_bus);

// Properly pipeline external data bus
    reg [7:0] write_bus;
    always @(posedge clk) begin
        if (rdy) begin
           address   <= address_bus;
           rwb       <= RE;
           write_bus <= write;
        end
    end
    assign data_io = (!rwb) ? write_bus : ram_select ? ram_read : rom_select ? rom_read : 8'hZZ;
    assign read_bus = data_io;

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
     .IRQ(1'b0),                          // interrupt request
     .NMI(1'b0),                          // non-maskable interrupt request
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
