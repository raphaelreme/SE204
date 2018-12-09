//Parameter N should currently not be unused
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


//A state of the automate is a couple (state, C)
enum logic [3:0] {IDLE, LOAD, STEP1, STEP2, STEP3, STEP4, STEP5} state;
logic [4:0] C;


//Compute the next (state, C) and synchronize DSI and DI with it.
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
    STEP5: if (C == 4)
             state <= IDLE;
           else C <= C + 1;
  endcase
end

//Compute the output BYP and DSO of the automate.
always_comb
begin
  //for IDLE state and the default case for other states
  DSO = 0;
  BYP = 0;

  if (state == LOAD)
    BYP = 1;

  //from STEP1 to STEP4
  for (int i=2; i<6; i++)
    if (state == i)
      //8 step with BYP=0 for STEP1, 7 for STEP2 ....
      if (C >= 10 - i)
        BYP = 1;

  if (state == STEP5)
    if (C == 4)
      DSO = 1;
end
endmodule
