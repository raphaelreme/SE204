module MCE_TESTBENCH();

logic [7:0] a;
logic [7:0] b;
wire [7:0] max;
wire [7:0] min;

MCE #(.SIZE(8)) mce (.a(a), .b(b),
                     .max(max), .min(min));

initial
begin
  for (int i=0; i<10; i++)
  begin
    a = $random();
    b = $random();
    #20;
    if (max<a || max<b)
    $display("########\na : %d\nb : %d\nmax : %d\nmin : %d", a, b, max, min);
  end
end


endmodule
