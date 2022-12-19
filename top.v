`timescale 1ns / 1ps

`define ALU_ADD   5'b00000
`define ALU_SUB   5'b01000

`define ALU_XOR   5'b00100
`define ALU_OR    5'b00110
`define ALU_AND   5'b00111

// shifts
`define ALU_SRA   5'b01101
`define ALU_SRL   5'b00101
`define ALU_SLL   5'b00001

// comparisons
`define ALU_LTS   5'b11100
`define ALU_LTU   5'b11110
`define ALU_GES   5'b11101
`define ALU_GEU   5'b11111
`define ALU_EQ    5'b11000
`define ALU_NE    5'b11001

// set lower than operations
`define ALU_SLTS  5'b00010
`define ALU_SLTU  5'b00011


module ALU_RISCV(
input [4:0] ALUOp,
input [31:0] A,
input [31:0] B,
output reg [31:0] Result,
output reg Flag
    );
    
    //block for result 
  always @(*) begin
     case(ALUOp)
     
     `ALU_ADD: Result = A + B;
     `ALU_SUB: Result = A - B;
     
     `ALU_XOR: Result = A ^ B ; 
     `ALU_OR: Result = A | B;
     `ALU_AND: Result = A & B ;
     
     `ALU_SRA: Result = $signed(A) >>> $signed(B);
     `ALU_SRL: Result = A >> B; 
     `ALU_SLL: Result = A << B;
     
     `ALU_LTS: Result = 0;
     `ALU_LTU: Result = 0;
     `ALU_GES: Result = 0;
     `ALU_GEU: Result = 0;
     `ALU_EQ: Result = 0;
     `ALU_NE: Result = 0;

     `ALU_SLTS: Result = ($signed(A) < $signed(B))? 1 : 0;
     `ALU_SLTU: Result = (A < B) ? 1 : 0;
     endcase  
  
  end
  
  //block for flags
    always @(*) begin
     case(ALUOp)
     
     `ALU_ADD: Flag = 0;
     `ALU_SUB: Flag = 0;
     
     `ALU_XOR: Flag = 0; 
     `ALU_OR: Flag = 0;
     `ALU_AND: Flag = 0;
     
     `ALU_SRA: Flag = 0;
     `ALU_SRL: Flag = 0; 
     `ALU_SLL: Flag = 0;
     
     `ALU_LTS: Flag = ($signed(A) < $signed(B));
     `ALU_LTU: Flag = A < B;
     `ALU_GES: Flag = ($signed(A) >= $signed(B));
     `ALU_GEU: Flag = A >= B;
     `ALU_EQ: Flag = (A == B);
     `ALU_NE: Flag = (A != B);

     `ALU_SLTS: Flag = 0;
     `ALU_SLTU: Flag = 0;
     
     endcase  
  
  end
  
  
  
  
endmodule
