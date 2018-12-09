//Parameter N is currently unused
module MEDIAN #(parameter WIDTH = 8, N = 9)
           (input [WIDTH-1:0]  DI,
            input              DSI,
            input              nRST,
            input              CLK,
            output [WIDTH-1:0] DO,
            output logic       DSO);

logic BYP;

//synchronized with BYP signal
logic DSI_SYNC;
logic [WIDTH-1:0]  DI_SYNC;

MED #(.WIDTH(WIDTH), .N(N)) med (.DI(DI_SYNC), .DSI(DSI_SYNC), .BYP(BYP),
                                 .CLK(CLK), .DO(DO));


enum logic [3:0] {IDLE, LOAD, STEP1, STEP2, STEP3, STEP4, STEP5} state;
logic [4:0] C;

always_ff@(posedge CLK or negedge nRST)
if (!nRST)
begin
  C <= 0;
  state <= IDLE;
end
else
begin
  DSI_SYNC <= DSI;
  DI_SYNC <= DI;

  case (state)
    IDLE: if (DSI)
             state <= LOAD;

    // Load the 9 last data.
    LOAD: if (~DSI) begin
             state <= STEP1;
             C <= 0;
          end

    //Compute the max of the 9 data and delete it.
    STEP1: if (C == 8) begin
             state <= STEP2;
             C <= 0;
           end else C <= C + 1;

    //Compute the max of the 8 left data and delete it.
    STEP2: if (C == 8) begin
             state <= STEP3;
             C <= 0;
             end else C <= C + 1;

    //Compute the max of the 7 left data and delete it.
    STEP3: if (C == 8) begin
             state <= STEP4;
             C <= 0;
             end else C <= C + 1;

    //Compute the max of the 6 left data and delete it.
    STEP4: if (C == 8) begin
             state <= STEP5;
             C <= 0;
             end else C <= C + 1;

    //Compute the max of the 5 left data, this is the median.
    STEP5: if (C == 4) begin
             state <= IDLE;
             end else C <= C + 1;
  endcase

end

always_comb
begin
  DSO = 0;
  if (state == IDLE)
    BYP = 0;

  if (state == LOAD)
    BYP = 1;

  if (state == STEP1)
    if (C < 8)
      BYP = 0;
    else
      BYP = 1;

  if (state == STEP2)
    if (C < 7)
      BYP = 0;
    else
      BYP = 1;

  if (state == STEP3)
    if (C < 6)
      BYP = 0;
    else
      BYP = 1;

  if (state == STEP4)
    if (C < 5)
      BYP = 0;
    else
      BYP = 1;

  if (state == STEP5) begin
    BYP = 0;
    if (C == 4)
      DSO = 1;
  end
end

endmodule
