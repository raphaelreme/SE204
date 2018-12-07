module MEDIAN #(parameter WIDTH = 8, N = 9)
           (input [WIDTH-1:0]  DI,
            input              DSI,
            input              nRST
            input              CLK,
            output [WIDTH-1:0] DO
            output             DSO);

logic BYP;

MED #(.WIDTH(WIDTH), .N(N)) med (.DI(DI), .DSI(DSI), .BYP(BYP)
                                 .CLK(CLK), .DO(DO));

always_ff@(posedge CLK)
begin




end


endmodule
