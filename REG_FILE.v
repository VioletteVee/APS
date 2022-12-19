`timescale 1ns / 1ps

module REG_FILE(
    input      [4:0]   A1,
    input      [4:0]   A2,
    input      [4:0]   A3,
    input              WE3,
    input      [31:0]  WD3,
    input              clk,
    output  [31:0]  RD1,
    output  [31:0]  RD2

    );
    
    reg [31:0] RF [0:31];
      
    
   assign  RD1 = (A1 == 5'b0) ? 32'b0 : RF[A1];
   assign  RD2 = (A2 == 5'b0) ? 32'b0 : RF[A2];
   
   always @ (posedge clk) 
    if(WE3) begin
    #1;
     RF[A3] <= WD3;
     end
    
endmodule
