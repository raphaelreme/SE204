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
  pixel_cpt <= 0;
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
  wshb_ifm.cyc <= 1;
else
  wshb_ifm.cyc <= ~(pixel_cpt % 64 == 0);

// En reset on ne demande pas d'ecriture en memoire, stb = 0 => Ack = 0.
assign wshb_ifm.stb = wshb_ifm.cyc && ~wshb_ifm.rst;

assign wshb_ifm.adr = (line_cpt * HDISP + pixel_cpt) * 4;
assign wshb_ifm.dat_ms = (pixel_cpt%16 == 0 || line_cpt%16 == 0) ? 32'hffffff : 32'h0;


assign wshb_ifm.we = 1'b1;
assign wshb_ifm.sel = 4'b1111;
assign wshb_ifm.cti = 3'b0;
assign wshb_ifm.bte = 2'b0;


endmodule
