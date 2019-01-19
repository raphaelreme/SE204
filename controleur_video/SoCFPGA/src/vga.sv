 module vga (
  input logic pixel_clk,
  input logic pixel_rst,
  video_if.master video_ifm,
  wshb_if.master wshb_ifm
  );

parameter HDISP = 800; //width
parameter VDISP = 480; //high
localparam HFP = 40;
localparam HPULSE = 48;
localparam HBP = 40;
localparam VFP = 13;
localparam VPULSE = 3;
localparam VBP = 29;

localparam VSUM = VFP + VPULSE + VBP;
localparam HSUM = HFP + HPULSE + HBP;


//========================================
//Lecture de la ram et envoie sur la fifo
//========================================
logic [$clog2(HDISP * VDISP)-1:0] pixel_id;
logic [31:0] rdata;
logic read, write, wfull;

async_fifo #(.DATA_WIDTH(32)) async_fifo_inst( .rst(wshb_ifm.rst), .rclk(pixel_clk),
                                                  .read(read), .wclk(wshb_ifm.clk),
                                                  .wdata(wshb_ifm.dat_sm), .write(write),
                                                  .wfull(wfull), .rdata(rdata));



// Demande du bus toujours active
assign wshb_ifm.cyc = ~wshb_ifm.rst;
assign wshb_ifm.stb = ~wshb_ifm.rst;

// Lire en mode classique (En fait il s'avere que dans le code du slave, il fait du burst quand meme en simu)
// En verite cela fera au maximum 8 cycle de lectures d'affiles tant que la fifo n'est pas pleine.
assign wshb_ifm.we = 1'b0;
assign wshb_ifm.cti = 3'b000;
assign wshb_ifm.bte = 2'b00;

// Lecture sur des mots de 32 bits donc decalage de 2.
// Mais en plus, pour arreter le burst du slave en simu,
// il faut imperativement changer l'adresse... C'est fonctionnel en utilisant cette astuce.
assign wshb_ifm.adr = wfull? 1<<31 : pixel_id<<2;

assign write = wshb_ifm.ack && ~wfull;

// Generation de pixel_id pour l'adresse
always_ff @(posedge wshb_ifm.clk or posedge wshb_ifm.rst)
if (wshb_ifm.rst)
begin
  pixel_id <= 0;
end
else
begin
  //ecriture dans la file si non pleine.
  if (wshb_ifm.ack && ~wfull)
  begin
    if (pixel_id == HDISP*VDISP - 1)
    begin
      pixel_id <= 0;
    end
    else
      pixel_id <= pixel_id + 1;
  end
end

//Synchronisation de wfull et pixel_clk
logic _wfull, wfull_sync;
always_ff @(posedge pixel_clk or posedge pixel_rst)
if (pixel_rst)
begin
  _wfull <= 0;
  wfull_sync <= 0;
end
else
begin
  _wfull <= wfull;
  wfull_sync <= _wfull;
end

//Garde en memoire si le file a ete pleine une fois
logic was_full;
always_ff @(posedge pixel_clk or posedge pixel_rst)
if (pixel_rst)
  was_full <= 0;
else
begin
  if (wfull_sync)
    was_full <= 1;
  else
    was_full <= was_full;
end



//================================================
//Lecture de la fifo et envoie vers le flux video
//================================================

assign video_ifm.CLK = pixel_clk;

logic [$clog2(VDISP + VSUM)-1:0] line_cpt;
logic [$clog2(HDISP + HSUM)-1:0] pixel_cpt;

/*
 * Generation des compteurs
 */
always_ff @(posedge pixel_clk or posedge pixel_rst)
if (pixel_rst)
begin
  line_cpt <= 0;
  pixel_cpt <= 0;
end
else
begin
  // On ne commence qu'une fois la fifo remplie une 1ere fois
  if (was_full)
  begin
    if (pixel_cpt == HSUM + HDISP - 1)
    begin
      pixel_cpt <= 0;

      if (line_cpt == VSUM + VDISP - 1)
        line_cpt <= 0;
      else
        line_cpt <= line_cpt + 1;
    end
    else
      pixel_cpt <= pixel_cpt + 1;
  end
end



/*
 * Envoie de l'image
 */
logic inc_line;

assign video_ifm.RGB = rdata[23:0];
assign read = video_ifm.BLANK;


always_ff @(posedge pixel_clk or posedge pixel_rst)
if (pixel_rst)
begin
  video_ifm.BLANK <= 0;
  video_ifm.VS <= 1;
  video_ifm.HS <= 1;
end
else
begin
  //Permet de synchroniser correctement les signaux sur le 0 des compteurs.
  inc_line = (pixel_cpt == HSUM + HDISP - 1);

  video_ifm.HS <= pixel_cpt < HFP - 1 || pixel_cpt >= HFP + HPULSE - 1;
  video_ifm.VS <= line_cpt + inc_line < VFP || line_cpt + inc_line >= VFP + VPULSE;
  video_ifm.BLANK <= ~(inc_line || line_cpt < VSUM || pixel_cpt < HSUM - 1|| line_cpt + inc_line == VSUM + VDISP);

end



endmodule
