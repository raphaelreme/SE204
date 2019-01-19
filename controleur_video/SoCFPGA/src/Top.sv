`default_nettype none

module Top (
    // Les signaux externes de la partie FPGA
	input  wire         FPGA_CLK1_50,
	input  wire  [1:0]	KEY,
	output logic [7:0]	LED,
	input  wire	 [3:0]	SW,
    // Les signaux du support matériel sont regroupés dans une interface
    hws_if.master       hws_ifm,
		video_if.master 		video_ifm
);

parameter HDISP = 800;
parameter VDISP = 480;

//====================================
//  Déclarations des signaux internes
//====================================
  wire        sys_rst;   // Le signal de reset du système
  wire        sys_clk;   // L'horloge système a 100Mhz
  wire        pixel_clk; // L'horloge de la video 32 Mhz

//=======================================================
//  La PLL pour la génération des horloges
//=======================================================

sys_pll  sys_pll_inst(
		   .refclk(FPGA_CLK1_50),   // refclk.clk
		   .rst(1'b0),              // pas de reset
		   .outclk_0(pixel_clk),    // horloge pixels a 32 Mhz
		   .outclk_1(sys_clk)       // horloge systeme a 100MHz
);

//=============================
//  Les bus Wishbone internes
//=============================
wshb_if #( .DATA_BYTES(4)) wshb_if_sdram  (sys_clk, sys_rst);
wshb_if #( .DATA_BYTES(4)) wshb_if_stream (sys_clk, sys_rst);

//=============================
//  Le support matériel
//=============================
hw_support hw_support_inst (
    .wshb_ifs (wshb_if_sdram),
    .wshb_ifm (wshb_if_stream),
    .hws_ifm  (hws_ifm),
	.sys_rst  (sys_rst), // output
    .SW_0     ( SW[0] ),
    .KEY      ( KEY )
 );

//=============================
// On neutralise l'interface
// du flux video pour l'instant
// A SUPPRIMER PLUS TARD
//=============================
assign wshb_if_stream.ack = 1'b1;
assign wshb_if_stream.dat_sm = '0 ;
assign wshb_if_stream.err =  1'b0 ;
assign wshb_if_stream.rty =  1'b0 ;

//--------------------------
//------- Code Eleves ------
//--------------------------
`ifdef SIMULATION
  localparam hcmpt = 5;
	localparam  hcmpt2 = 3;
`else
  localparam hcmpt=25;
	localparam  hcmpt2 = 23;
`endif


assign LED[0] = KEY[0];

always_comb begin
	LED[7:4] = 0;
end

//=============
//Led 1 a 1 Hz avec sys_clk
//=============
logic [hcmpt:0] compteur;

always_ff @(posedge sys_clk or posedge sys_rst)
if (sys_rst)
begin
	LED[1] <= 0;
	compteur <= 0;
end
else
begin
	compteur <= compteur + 1;
	if (compteur == 0)
		LED[1] <= ~LED[1];
end

//===============
//pixel reset
//===============
logic pixel_rst, _pixel_rst;
always_ff @(posedge pixel_clk or posedge sys_rst)
if (sys_rst)
begin
	_pixel_rst <= 1;
	pixel_rst <= 1;
end
else
begin
	_pixel_rst <= 0;
	pixel_rst <= _pixel_rst;
end

//=============
//Led 2 a 1 Hz avec pixel_clk
//=============
logic [hcmpt2:0] compteur2;

always_ff @(posedge pixel_clk or posedge pixel_rst)
if (pixel_rst)
begin
	LED[2] <= 0;
	compteur2 <= 0;
end
else
begin
	compteur2 <= compteur2 + 1;
	if (compteur2 == 0)
		LED[2] <= ~LED[2];
end

//===============
//Interface video
//===============
video_if video_if_inst();

vga #(.HDISP(HDISP), .VDISP(VDISP)) vga_inst(.pixel_clk(pixel_clk), .pixel_rst(pixel_rst), .video_ifm(video_ifm), .wshb_ifm(wshb_if_sdram.master));



endmodule
