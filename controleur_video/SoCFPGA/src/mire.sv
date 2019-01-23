 module mire (
  wshb_if.master wshb_ifm
  );

parameter HDISP = 800;
parameter VDISP = 480;

logic [$clog2(HDISP)-1:0] pixel_cpt;
logic [$clog2(VDISP)-1:0] line_cpt;

/*
 * Generation des compteurs
 */
always_ff @(posedge wshb_ifm.clk or posedge wshb_ifm.rst)
if (wshb_ifm.rst)
begin
  pixel_cpt <= 1;
  line_cpt <= 0;
end
else
begin
  if (wshb_ifm.ack)
  begin
    if (pixel_cpt == HDISP - 1)
    begin
      pixel_cpt <= 0;

      if (line_cpt == VDISP - 1)
        line_cpt <= 0;
      else
        line_cpt <= line_cpt + 1;
    end
    else
      pixel_cpt <= pixel_cpt + 1;
  end
end

// Generations des signaux du wishbone.

always_ff @(posedge wshb_ifm.clk or posedge wshb_ifm.rst)
if (wshb_ifm.rst)
begin
  wshb_ifm.cyc <= 1;
  wshb_ifm.stb <= 0;
  wshb_ifm.adr <= 0;
  wshb_ifm.dat_ms <= 0;
end
else
begin
  wshb_ifm.cyc <= ~(pixel_cpt % 64 == 0);
  wshb_ifm.stb <= ~(pixel_cpt % 64 == 0);

  //On utilise l'ack pour savoir si l'adresse doit etre incrementer.
  wshb_ifm.adr = (line_cpt * HDISP + pixel_cpt + wshb_ifm.ack) * 4;

  // On utilise le fait que HDISP est multiple de 16, pour passer la premiere colonne de la bonne couleur.
  wshb_ifm.dat_ms = ((pixel_cpt + wshb_ifm.ack)%16 == 0 || line_cpt%16 == 0) ? 32'hffffffff : 32'h0;
end

assign wshb_ifm.we = 1'b1;
assign wshb_ifm.sel = 4'b1111;
assign wshb_ifm.cti = 3'b0;
assign wshb_ifm.bte = 2'b0;


endmodule
