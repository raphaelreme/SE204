module MCE #(parameter SIZE = 8)
           (input [SIZE-1:0]  a,
            input [SIZE-1:0]  b,
            output [SIZE-1:0] max,
            output [SIZE-1:0] min);

assign max = (a>=b)? a: b;
assign min = (a>=b)? b: a;

endmodule
