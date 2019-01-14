 module vga (
  input logic pixel_clk,
  input logic pixel_rst,
  video_if.master video_ifm
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
  //needed to correctly synchronized the first line of each image.
  inc_line = (pixel_cpt == HSUM + HDISP - 1);

  video_ifm.RGB <= {24{line_cpt%16 == 0 || pixel_cpt%16 == 0}};
  video_ifm.HS <= pixel_cpt < HFP || pixel_cpt >= HFP + HPULSE;
  video_ifm.VS <= line_cpt + inc_line < VFP + 1 || line_cpt + inc_line >= VFP + VPULSE + 1;
  video_ifm.BLANK <= line_cpt + inc_line >= VSUM + 1 && pixel_cpt >= HSUM;
end
endmodule
