`timescale 1ns / 1ps

module DATA_MEMORY( 
     input            clk,
     input             WE,
     input [31:0]      WD,
     input [31:0]       A,
     output [31:0]     RD  
    );
    
reg [31:0] DM [0:255];
wire flag_adr;
assign flag_adr = (A >= 32'h80000000) && (A <= 32'h800003FC);

assign RD[7:0] = flag_adr * DM[A[9:2]];
assign RD[15:8] = flag_adr * DM[A[9:2] + 8'b1];
assign RD[23:16] = flag_adr * DM[A[9:2] + 8'b10];
assign RD[31:24] = flag_adr * DM[A[9:2] + 8'b11];

always @(posedge clk)
begin
if(flag_adr)
  begin
    if(WE)
      DM[A[9:2]] = WD[7:0];
      DM[A[9:2] + 8'b1] = WD[15:8];
      DM[A[9:2] + 8'b10] = WD[23:16];
      DM[A[9:2] + 8'b11] = WD[31:24];
      
    end
end
 
endmodule