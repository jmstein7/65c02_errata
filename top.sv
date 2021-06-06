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
    input via_ca1,
    inout logic [7:0] data_io,
    inout logic [7:0] via_port_a,
    inout logic [7:0] via_port_b,
    inout via_ca2,
    inout via_cb1,
    inout via_cb2,
    output rwb,
    output phi2,
    output led_a,
    output wire resb,
    output txd, //out to UART
    output rts
    );

    wire rdy = 1'b1;
    wire ena_4 = 1'b1;
    wire I_CS1 = 1'b1; 
    
    wire WE, RE, cs, rom_e, ram_e, bus_e, acia_e, I_CS2_L, via_e; 
    wire I_P2_H; //6522 internal clock enable signal

    reg [15:0] address;
    wire [7:0] read;
    wire [7:0] write; 
    wire [7:0] write_bus; 
    wire [7:0] read_bus; 
    wire [7:0] rom_read; 
    wire [7:0] ram_read; 
    wire [7:0] ram_write; 
    wire [7:0] acia_in; 
    wire [7:0] acia_out; 
    wire [7:0] via_in; 
    wire [15:0] AD; 
    wire [15:0] address_bus; 
    wire [1:0] rs;
    wire [3:0] i_rs;
    wire [7:0] DO; 
    wire [7:0] DI; 
    
//VIA signals
    wire    [7:0] via_dout;
    reg    [7:0] via_dout_r;
    wire    via_dout_oe_n;
    wire    via_ca2_in;
    wire    via_ca2_out;
    wire    via_ca2_oe_n;
    wire    [7:0] via_pa_in;
    wire    [7:0] via_pa_out;
    wire    [7:0] via_pa_oe_n;
    wire    via_cb1_in;
    wire    via_cb1_out;
    wire    via_cb1_oe_n;
    wire    via_cb2_in;
    wire    via_cb2_out;
    wire    via_cb2_oe_n;
    wire    [7:0] via_pb_in;
    wire    [7:0] via_pb_out;
    wire    [7:0] via_pb_oe_n;
    
    //select registers as well as the clk enable for 6522
    reg bus_select;
    reg ram_select;
    reg rom_select;
    reg acia_select; 
    reg via_select; 
    reg [1:0] clken;  //VIA phi2 enable high
    assign phi2 = clk; 

    //tristate the FPGA in/out signals
    assign DO = write_bus; 
    assign data_io = (WE || (RE && rom_e) || (RE && ram_e) || (RE && acia_e) || (RE && via_e)) ? DO : 'bZ;
    assign DI = data_io;
    
    assign resb = ~reset; 
    assign address_bus = AD; 
    assign rs[1:0] = address_bus[1:0]; //acia register select
    assign i_rs[3:0] = address_bus[3:0]; 
    
    //read/write enables and reset indicator
    assign RE = ~WE;
    assign rwb = RE; 
    assign led_a = resb; 
    
    //chip select signal group
    assign rom_e = (address_bus >= 16'hc000) ? 1'b1 : 1'b0; 
    assign ram_e = (address_bus < 16'h8000) ? 1'b1 : 1'b0; 
    assign acia_e = (address_bus >= 16'h8000 && address_bus <= 16'h800F) ? 1'b1 : 1'b0;
    assign cs = ~acia_e; //ACIA active low-chip select signal
    assign via_e = (address_bus >= 16'h8800 && address_bus <= 16'h880F) ? 1'b1 : 1'b0;
    assign I_CS2_L = ~via_e; 
    assign bus_e = (~rom_e && ~ram_e && ~acia_e && via_e); 
    
    
    //processor writes to ram, acia, and VIA
    assign ram_write = (WE && ram_e) ? write : 'bZ; 
    assign acia_in = (WE && acia_e) ? write : 'bZ; //processor write to ACIA
    assign via_in = (WE && via_in) ? write : 'bZ; 
    
    assign read_bus = DI; 
    
// Delay mux select signals to line up with RAM/ROM outputs (h/t Dave Banks)
    always @(posedge clk) begin
        bus_select <= RE && bus_e;
        ram_select <=  RE && ram_e;
        rom_select <=  RE && rom_e;
        acia_select <= RE && acia_e; 
        via_select <= RE && via_e; 
    end

// Return NOP if no select matches (h/t Dave Banks)
// (a place holder for further expansion attempts)
    assign read = bus_select ? read_bus : (ram_select ? ram_read : (rom_select ? rom_read : 
    (acia_select ? acia_out : (via_select ? via_dout : 8'hea))));
    
    assign write_bus = (WE) ? write : ((rom_select) ? rom_read : 
    ((ram_select) ? ram_read : ((acia_select) ? acia_out : via_dout))); 

    //external address pads (h/t Dave Banks)
    always @(posedge clk)
    if( rdy )
        address <= address_bus;
        
    //enable counter for VIAs
    always @(posedge clk)
        begin
          if (resb == 1'b0) begin
             clken <= 0;
          end 
          else begin
            clken <= clken + 1;
          end
      end
      
     //clk enable active one in four cycles
     assign I_P2_H = (clken == 0) ? 1'b1 : 1'b0; 
     
   always @(posedge clk)
     begin
        if (clken)
          begin
             via_dout_r <= via_dout;
          end
     end

      //tristate the VIA ports
     assign via_port_a = (via_pa_oe_n == 0) ? via_pa_out : 'bZ;
     assign via_pa_in = via_port_a;     
     
     assign via_port_b = (via_pb_oe_n == 0) ? via_pb_out : 'bZ;
     assign via_pb_in = via_port_b; 
     
     assign via_ca2 = (via_ca2_oe_n == 0) ? via_ca2_out : 'bZ;
     assign via_ca2_in = via_ca2; 
     
     assign via_cb2 = (via_cb2_oe_n == 0) ? via_cb2_out : 'bZ;
     assign via_cb2_in = via_cb2; 

     assign via_cb1 = (via_cb1_oe_n == 0) ? via_cb1_out : 'bZ;
     assign via_cb1_in = via_cb1;      
      
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

m6522 via_alpha(
      .I_RS(i_rs),
      .I_DATA(via_in),
      .O_DATA(via_dout),
      .O_DATA_OE_L(via_dout_oe_n), 
      .I_RW_L(RE),
      .I_CS1(I_CS1),
      .I_CS2_L(I_CS2_L),
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
      .O_PB_OE_L(via_pb_oe_n),
      .I_P2_H(I_P2_H), // high for phase 2 clock  ____////__
      .RESET_L(resb),
      .ENA_4(ena_4), // clk enable
      .CLK(clk)
    );
    
endmodule
