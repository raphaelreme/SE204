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


//Gestion de l'acquittement. ack_read est synchrone.
logic ack_read;
wire ack_write;

assign ack_write = wb_s.stb & wb_s.we;
assign wb_s.ack = ack_read | ack_write;


//Bloc memoire.
//Adresses sur des mots de 4*8bits (decalage de 2 par rapport wb_s.adr)
wire [mem_adr_width-1:0] Addr;
assign Addr = wb_s.adr[mem_adr_width+1:2];

logic [3:0][7:0] mem [0: 1 << mem_adr_width];



always_ff @(posedge wb_s.clk)
begin
  //bte != 0 is not supported -> behave as if cti == 0
  ack_read <= ~wb_s.rst & wb_s.stb & ~wb_s.we & (wb_s.cti == 1 || (wb_s.cti == 2 && (wb_s.bte == 0 || ~ack_read)) || (wb_s.cti == 0 && ~ack_read));

  if (wb_s.stb)
  begin
    if (wb_s.we)
      for (int i=0; i<4; i++)
        if(wb_s.sel[i])
          mem[Addr][i] <= wb_s.dat_ms[8*(i+1)-1 -: 8];


    if (~ack_read || wb_s.cti == 0 || wb_s.cti == 1)
      wb_s.dat_sm <= mem[Addr];
    else
      wb_s.dat_sm <= mem[Addr + 1];


  end
end
endmodule
