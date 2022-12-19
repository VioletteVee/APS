`timescale 1ns / 1ps

module PROGRAM(
  input             clk,
  input             reset,
  input  [31:0]     IN, 
  output [31:0]     OUT
);

reg [7:0] PC; // счётчик команд
reg [31:0] wd3_mult; // мультиплексор на wd3
reg [7:0] PC_out_mult; // мультиплексор на PC
reg PC_in_mult;

wire [31:0] INSTRUCTION;
wire [4:0]  aluOp;
wire [31:0] RD1, RD2;
wire we3_or;
wire [31:0] aluOut;
wire aluFlag;


assign OUT = RD1;
assign we3_or = INSTRUCTION [29] | INSTRUCTION [28];

assign aluOp = INSTRUCTION [27:23];


//Подключение файлов
REG_FILE RF(
     .A1(INSTRUCTION [22:18]),
     .A2(INSTRUCTION [17:13]),
     .A3(INSTRUCTION [4:0]),
     .WE3(we3_or),
     .WD3(wd3_mult),
     .clk(clk),
     .RD1(RD1),
     .RD2(RD2)
);

ALU_RISCV ALU(
     .ALUOp(aluOp),
     .A(RD1),
     .B(RD2),
     .Result(aluOut),
     .Flag(aluFlag)
);

RAM RM (
    .clk(clk),
    .adr(PC),
    .rd(INSTRUCTION)
     );

// описание PC
always @(posedge clk or posedge reset)
  begin
  if (reset) begin
  PC <= 8'b0;
  end
  else begin
  #1;
  PC <= PC + 4 * PC_out_mult;
  end
  end
  
//описание мульиплексора на PC
always @(posedge clk)
   begin
   PC_in_mult = INSTRUCTION [31] | (INSTRUCTION [30] & aluFlag);
   case (PC_in_mult)
   1'b0: PC_out_mult <= 8'b00000001;
   1'b1: PC_out_mult <= INSTRUCTION [12:5];
   endcase
   end
  
//описание мультиплексора на WD3
always @(posedge clk)
   begin
   case (INSTRUCTION[29:28])
   2'b01: wd3_mult <= IN;
   2'b10: wd3_mult <= { {9{INSTRUCTION[27]}}, INSTRUCTION[27:5]};
   2'b11: wd3_mult <= aluOut;
   endcase
   end

endmodule