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


//A state is a couple (state, C)
//enum logic [3:0] {IDLE, LOAD, STEP1, STEP2, STEP3, STEP4, STEP5} state;
logic [3:0] state;
logic [4:0] C;

always_ff@(posedge CLK or negedge nRST)
if (!nRST)
begin
  C <= 0;
  state <= 0;//IDLE;
end
else
begin
  DSI_SYNC <= DSI;
  DI_SYNC <= DI;
  /*
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
  */
  //IDLE state
  if (state == 0) begin
    if (DSI)
      state <= state +1;
  end
  //LOAD state
  else if (state == 1) begin
    if (~DSI) begin
      state <= state + 1;
      C <= 0;
    end else C <= C + 1;
  end
  //STEP 5 state
  else if (state == 6) begin
    if (C == 4) begin
      state <= 0;
    end else C <= C + 1;
  end
  //STEP 1,2,3,4
  else begin
    if (C == 8) begin
      state <= state + 1;
      C <= 0;
    end else C <= C + 1;
  end
end

always_comb
begin
  //case IDLE
  DSO = 0;
  BYP = 0;

  if (state == 1)//LOAD)
    BYP = 1;

  for (int i=2; i<6; i++)
    if (state == i)
      if (C < 10 -i)
        BYP = 0;
      else
        BYP = 1;

  /*
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
      BYP = 1;*/

  if (state == 6) begin //STEP5) begin
    BYP = 0;
    if (C == 4)
      DSO = 1;
  end
end

endmodule
