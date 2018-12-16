//-----------------------------------------------------------------
// Wishbone BlockRAM
//-----------------------------------------------------------------
//
// Le paramètre mem_adr_width doit permettre de déterminer le nombre
// de mots de la mémoire : (2048 pour mem_adr_width=11)

module wb_bram #(parameter mem_adr_width = 11) (
      // Wishbone interface
      wshb_if.slave wb_s
      );

//Ack signal.
logic ack_read;
wire ack_write;

assign ack_write = wb_s.stb & wb_s.we;
assign wb_s.ack = ack_read | ack_write;
//bte != 0 is yet not supported -> should behave as if cti == 0
always_ff @(posedge wb_s.clk)
//  ack_read <= ~wb_s.rst & wb_s.stb & ~wb_s.we & (wb_s.cti == 1 || wb_s.cti == 2 || ((wb_s.cti == 0 || wb_s.cti == 7) && ~ack_read));
ack_read <=  wb_s.stb & ~wb_s.we & (wb_s.cti == 1 || (wb_s.cti == 2 && (wb_s.bte == 0 || ~ack_read)) || ((wb_s.cti == 0 || wb_s.cti == 7) && ~ack_read));


//Adress on words of 32 bits. (2 times shift)
logic [mem_adr_width-1:0] addr, addr_read;
assign addr = wb_s.adr[mem_adr_width+1:2];

//addr_read = addr except when burst. (Must be valid only when ack = 1 -> used to simplify the expression.) Here only bte = 0 is supported.
assign addr_read = addr + (ack_read & wb_s.cti[1]);


//Memory bloc
logic [3:0][7:0] mem [0: (1 << mem_adr_width) - 1];

//Write in the memory
always_ff @(posedge wb_s.clk)
if (wb_s.stb)
  if (wb_s.we)
    for (int i=0; i<4; i++)
      if(wb_s.sel[i])
        mem[addr][i] <= wb_s.dat_ms[8*(i+1)-1 -: 8];

//Read in the memory.
always_ff @(posedge wb_s.clk)
  wb_s.dat_sm <= mem[addr_read];

endmodule
