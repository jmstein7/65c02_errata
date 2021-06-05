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
    input acia_clk,
    input reset,
    input cts,
    input rxd, //in to UART
    inout logic [7:0] data_io,
    output reg [15:0] address,
    output rwb,
    output phi2,
    output led_a,
    output wire resb,
    output txd, //out to UART
    output rts
    );

    wire rdy = 1'b1;
    wire WE, RE, cs, rom_e, ram_e, bus_e, acia_e; 

    wire [7:0] read;
    wire [7:0] write; 
    wire [7:0] write_bus; 
    wire [7:0] read_bus; 
    wire [7:0] rom_read; 
    wire [7:0] ram_read; 
    wire [7:0] ram_write; 
    wire [7:0] acia_in; 
    wire [7:0] acia_out; 
    wire [15:0] AD; 
    wire [15:0] address_bus; 
    wire [1:0] rs;
    wire [7:0] DO; 
    wire [7:0] DI; 
    
    //select registers
    reg bus_select;
    reg ram_select;
    reg rom_select;
    reg acia_select; 
    
    assign phi2 = clk; 
    
    //tristate the FPGA in/out signals
    assign DO = write_bus; 
    assign data_io = (WE || (RE && rom_e) || (RE && ram_e) || (RE && acia_e)) ? DO : 'bZ;
    assign DI = data_io;
    
    assign resb = ~reset; 
    assign address_bus = AD; 
    assign rs[1:0] = address_bus[1:0]; //acia register select
    
    //read/write enables and reset indicator
    assign RE = ~WE;
    assign rwb = RE; 
    assign led_a = resb; 
    
    //chip selet signal group
    assign rom_e = (address_bus >= 16'hc000) ? 1'b1 : 1'b0; 
    assign ram_e = (address_bus < 16'h8000) ? 1'b1 : 1'b0; 
    assign acia_e = (address_bus >= 16'h8000 && address_bus <= 16'h800F) ? 1'b1 : 1'b0;
    assign cs = ~acia_e; //ACIA active low-chip select signal
    assign bus_e = (~rom_e && ~ram_e && ~acia_e); 
    
    
    //processor writes to ram and the acia
    assign ram_write = (WE && ram_e) ? write : 'bZ; 
    assign acia_in = (WE && acia_e) ? write : 'bZ; //processor write to ACIA
    
    assign read_bus = DI; 
    
// Return NOP if no select matches (h/t Dave Banks)
// (a place holder for further expansion attempts)
    assign read = bus_select ? read_bus : (ram_select ? ram_read : (rom_select ? rom_read : (acia_select ? acia_out : 8'hea)));
    
    assign write_bus = (WE) ? write : ((rom_select) ? rom_read : ((ram_select) ? ram_read : acia_out)); 

// Delay mux select signals to line up with RAM/ROM outputs (h/t Dave Banks)
    always @(posedge clk) begin
        bus_select <= RE && bus_e;
        ram_select <=  RE && ram_e;
        rom_select <=  RE && rom_e;
        acia_select <= RE && acia_e; 
    end

    //external address pads (h/t Dave Banks)
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
    
ACIA ACIA_a(
    .RESET(resb),   //: in     std_logic;
    .PHI2(clk),    //: in     std_logic;
    .CS(cs),      //: in     std_logic;
    .RWN(RE),     //: in     std_logic;
    .RS(rs),      //: in     std_logic_vector(1 downto 0);
    .DATAIN(acia_in),  //: in     std_logic_vector(7 downto 0);
    .DATAOUT(acia_out), //: out    std_logic_vector(7 downto 0);
    .XTLI(acia_clk),    //: in     std_logic;
    .RTSB(rts),    //: out    std_logic;
    .CTSB(cts),    //: in     std_logic;
    .DTRB(),    //: out    std_logic;
    .RXD(rxd),     //: in     std_logic;
    .TXD(txd),     //: buffer std_logic;
    .IRQn()    //: buffer std_logic
   );
    
endmodule
