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

assign video_ifm.CLK = pixel_clk;

logic [$clog2(VDISP + VFP + VPULSE + VBP)-1:0] line_cpt;
logic [$clog2(HDISP + HFP + HPULSE + HBP)-1:0] pixel_cpt;
logic inc_line;

//=================
//Generation des compteurs
//=================
always_ff @(posedge pixel_clk or posedge pixel_rst)
if (pixel_rst)
begin
  line_cpt <= 0;
  pixel_cpt <= 0;
end
else
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
/*
//================
//Envoie une mire comme image
//================
always_ff @(posedge pixel_clk or posedge pixel_rst)
if (pixel_rst)
begin
  video_ifm.BLANK <= 0;
  video_ifm.VS <= 1;
  video_ifm.HS <= 1;
  video_ifm.RGB = {24{1'b0}};
end
else
begin
  //needed to correctly synchronized the first line of each image. Otherwise it's shifted from 1 pixel.
  inc_line = (pixel_cpt == HSUM + HDISP - 1);

  video_ifm.RGB <= {24{line_cpt%16 == 0 || pixel_cpt%16 == 0}};
  video_ifm.HS <= pixel_cpt < HFP || pixel_cpt >= HFP + HPULSE;
  video_ifm.VS <= line_cpt + inc_line < VFP + 1 || line_cpt + inc_line >= VFP + VPULSE + 1;
  video_ifm.BLANK <= line_cpt + inc_line >= VSUM + 1 && pixel_cpt >= HSUM;
end*/

//====================
//Etape 3
//====================
logic [$clog2(HDISP * VDISP)-1:0] pixel_id;
logic read, write;
logic [31:0] data;


async_fifo #(.DATA_WIDTH(32)) async_fifo_inst( .rst(wshb_ifm.rst), .rclk(pixel_clk),
                                                  .read(read), .wclk(wshb_ifm.clk),
                                                  .wdata(data), .write(write));

// Demande du bus
assign wshb_ifm.cyc = ~wshb_ifm.rst;
assign wshb_ifm.stb = ~wshb_ifm.rst;

//on ne fait que lire en mode classique
assign wshb_ifm.we = 1'b0;
assign wshb_ifm.cti = 3'b000;
assign wshb_ifm.bte = 2'b00;

assign wshb_ifm.adr = pixel_id<<2;

assign write = wshb_ifm.ack && ~async_fifo_inst.wfull;
assign data = wshb_ifm.dat_sm;


always_ff @(posedge wshb_ifm.clk or posedge wshb_ifm.rst)
if (wshb_ifm.rst)
begin
  pixel_id <= 0;
end
else
begin
  //Lecture sur des mots de 32 bits
  //wshb_ifm.adr <= 4 * pixel_id;

  //Lecture en rafales si possible
  //if (pixel_id == HDISP*VDISP - 1)
  //  wshb_ifm.cti = 3'b111;
  //else
  //  wshb_ifm.cti = 3'b010;
  //wshb_ifm.bte = 2'b00;

  //ecriture dans la file si non pleine.
  if (wshb_ifm.ack && ~async_fifo_inst.wfull)
  begin
    if (pixel_id == HDISP*VDISP - 1)
    begin
      pixel_id <= 0;
      //wshb_ifm.stb <= 1'b0;
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
  _wfull <= async_fifo_inst.wfull;
  wfull_sync <= _wfull;
end

//Garde en memoire si le file a ete full une fois
logic was_full;
always_ff @(posedge pixel_clk or posedge pixel_clk)
if (pixel_rst)
  was_full <= 0;
else
  if (wfull_sync)
    was_full <= 1;


//================
//Envoie l'image
//================

assign video_ifm.RGB = async_fifo_inst.rdata[23:0];
assign read = video_ifm.BLANK & ~pixel_rst;
always_ff @(posedge pixel_clk or posedge pixel_rst)
if (pixel_rst)
begin
  video_ifm.BLANK <= 0;
  video_ifm.VS <= 1;
  video_ifm.HS <= 1;
  //read <= 0;
end
else
begin
  if (was_full)
  begin
    //needed to correctly synchronized the first line of each image. Otherwise it's shifted from 1 pixel.
    inc_line = (pixel_cpt == HSUM + HDISP - 1);

    //read <= video_ifm.BLANK;

    video_ifm.HS <= pixel_cpt < HFP || pixel_cpt >= HFP + HPULSE;
    video_ifm.VS <= line_cpt + inc_line < VFP + 1 || line_cpt + inc_line >= VFP + VPULSE + 1;
    video_ifm.BLANK <= line_cpt + inc_line >= VSUM + 1 && pixel_cpt >= HSUM;
  end
end



endmodule
