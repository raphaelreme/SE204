// Les interfaces wishbones sont synchrones, de même horlage que celle reliee a SDRAM.

module wshb_intercon (
 wshb_if.slave wshb_ifs_vga,
 wshb_if.slave wshb_ifs_mire,
 wshb_if.master wshb_ifm_sdram
 );

// Vaut 1 si vga a la main, 0 si c'est la mire.
logic jeton;

// Transmission des requetes des maitres.
assign wshb_ifm_sdram.cyc = jeton ? wshb_ifs_vga.cyc : wshb_ifs_mire.cyc;
assign wshb_ifm_sdram.stb = jeton ? wshb_ifs_vga.stb : wshb_ifs_mire.stb;
assign wshb_ifm_sdram.adr = jeton ? wshb_ifs_vga.adr : wshb_ifs_mire.adr;
assign wshb_ifm_sdram.we = jeton ? wshb_ifs_vga.we : wshb_ifs_mire.we;
assign wshb_ifm_sdram.dat_ms = jeton ? wshb_ifs_vga.dat_ms : wshb_ifs_mire.dat_ms;
assign wshb_ifm_sdram.sel = jeton ? wshb_ifs_vga.sel : wshb_ifs_mire.sel;
assign wshb_ifm_sdram.cti = jeton ? wshb_ifs_vga.cti : wshb_ifs_mire.cti;
assign wshb_ifm_sdram.bte = jeton ? wshb_ifs_vga.bte : wshb_ifs_mire.bte;

// Transmission des reponses de l'esclave.
assign wshb_ifs_vga.ack = jeton ? wshb_ifm_sdram.ack : 0;
assign wshb_ifs_vga.dat_sm = jeton ? wshb_ifm_sdram.dat_sm : 0;
assign wshb_ifs_vga.rty = jeton ? wshb_ifm_sdram.rty : 0;
assign wshb_ifs_vga.err = jeton ? wshb_ifm_sdram.err : 0;

assign wshb_ifs_mire.ack = ~jeton ? wshb_ifm_sdram.ack : 0;
assign wshb_ifs_mire.dat_sm = ~jeton ? wshb_ifm_sdram.dat_sm : 0;
assign wshb_ifs_mire.rty = ~jeton ? wshb_ifm_sdram.rty : 0;
assign wshb_ifs_mire.err = ~jeton ? wshb_ifm_sdram.err : 0;



// Gestion du jeton. Initialement, la mire a le jeton.
always @(posedge wshb_ifm_sdram.clk or posedge wshb_ifm_sdram.rst)
if (wshb_ifm_sdram.rst)
begin
  jeton <= 0;
end
else
begin
  // On ne change le jeton que si celui qui l'a n'en veut plus et l'autre le veut.
  if (jeton)
    jeton <= wshb_ifs_vga.cyc || ~wshb_ifs_mire.cyc;
  else
    jeton <= wshb_ifs_vga.cyc & ~wshb_ifs_mire.cyc;
end









endmodule
