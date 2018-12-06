module MED #(parameter WIDTH = 8, N = 9)
           (input [WIDTH-1:0]  DI,
            input              DSI,
            input              BYP,
            input              CLK,
            output [WIDTH-1:0] DO);

logic [WIDTH-1:0] R [N-1:0];
wire [WIDTH-1:0] min;
wire [WIDTH-1:0] max;


assign DO = R[N-1];
MCE #(.SIZE(WIDTH)) mce (.a(R[N-2]), .b(R[N-1]),
                     .max(max), .min(min));



always_ff@(posedge CLK)
begin
  R[N-2:0] <= (DSI)? {R[N-3:0], DI}: {R[N-3:0], min};
  R[N-1] <= (BYP)? R[N-2]: max;
end

endmodule
