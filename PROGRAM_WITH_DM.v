module PROGRAM_WITH_DM(
  input             clk,
  input             reset,
  
  input [31:0]  instr_rdata_i,
  output [31:0]  instr_addr_o,
  input [31:0]  data_rdata_i,
  output        data_req_o,
  output        data_we_o,
  output [3:0]  data_be_o,
  output [31:0] data_addr_o,
  output [31:0]  data_wdata_o
  
);
wire enpc;
wire [31:0]  fetched_instr_i;
wire [1:0]   ex_op_a_sel_o;      
wire [2:0]   ex_op_b_sel_o;      
wire [4:0]   alu_op_o;           
wire         mem_req_o;        
wire         mem_we_o;           
wire [2:0]   mem_size_o;         
wire         gpr_we_a_o;        
wire         wb_src_sel_o;       
wire         illegal_instr_o;    
wire         branch_o;         
wire         jal_o;             
wire         jalr_o;
wire         comp; 
wire [31:0]  instr;
wire data_req_o_;
wire data_we_o_;  
wire [3:0] data_be_o_reg;
wire [31:0] data_addr_o_reg;
wire [31:0] data_wdata_o_reg;
wire [31:0] lsu_rd;                 
assign lsu_data_o = lsu_rd;

wire [31:0] mult_PC_1;
wire [31:0] mult_PC_2;
wire [31:0] mult_PC_3;


wire [31:0] imm_I;
assign imm_I = {{20{instr[31]}} ,instr[31:20]};
wire [31:0] imm_S;
assign imm_S = {{20{instr[31]}},
                instr[31:25],
                instr[11:7]};
wire [31:0] imm_B;
assign imm_B = {{20{instr[31]}},
                        instr[31],
                        instr[7],
                        instr[30:25],
                        instr[11:8]};
wire [31:0] imm_J;
assign imm_J = {{10{instr[31]}},
                        instr[31],
                        instr[19:12],
                        instr[20],
                        instr[30:21]};
                        
reg [31:0] PC;


wire [31:0] rd1_out;
reg [31:0] rd2_out;

wire [31:0] mult_LSU;
wire [31:0] aluOut;
wire [31:0] RD1;
wire [31:0] RD2;

// Подключение файлов

decoder_riscv DC( 
     .fetched_instr_i(fetched_instr_i),
     .ex_op_a_sel_o(ex_op_a_sel_o),
     .ex_op_b_sel_o(ex_op_b_sel_o),
     .alu_op_o(alu_op_o),
     .mem_req_o(mem_req_o),
     .mem_we_o(mem_we_o),
     .mem_size_o(mem_size_o),
     .gpr_we_a_o(gpr_we_a_o),
     .wb_src_sel_o(wb_src_sel_o),
     .illegal_instr_o(illegal_instr_o),
     .branch_o(branch_o),
     .jal_o(jal_o),
     .jalr_o(jalr_o)
);

REG_FILE RF(
     .A1(instr[19:15]),
     .A2(instr[24:20]),
     .A3(instr[11:7]),
     .WE3(gpr_we_a_o),                     
     .WD3(mult_LSU),                       
     .clk(clk),
     .RD1(RD1),                            
     .RD2(RD2)                             
);

ALU_RISCV ALU(
     .ALUOp(alu_op_o),
     .A(rd1_out),       
     .B(rd2_out),                            
     .Result(aluOut),                     
     .Flag(comp)
);

/*RAM RM (
    .clk(clk),
    .adr(PC),                              
    .rd(fetched_instr_i)
     );
     
DATA_MEMORY DM(
    .clk(clk),
    .WE(mem_we_o),
    .WD(RD2),
    .A(aluOut),
    .RD(DM_out)
);
*/
    
miriscv_lsu LSU (
    .clk_i(clk),
    .arstn_i(reset),
    .lsu_addr_i(aluOut),
    .lsu_we_i(mem_we_o),
    .lsu_size_i(mem_size_o),
    .lsu_data_i(RD2),
    .lsu_req_i(mem_req_o),
    .lsu_stall_req_o(enpc),
    .lsu_data_o(lsu_rd),
    .data_rdata_i(data_rdata_i),
    .data_req_o(data_req_o_reg),
    .data_we_o(data_we_o_reg),
    .data_be_o(data_be_o_reg),
    .data_addr_o(data_addr_o_reg),
    .data_wdata_o(data_wdata_o_reg)  
);

assign instr = instr_rdata_i;
assign fetched_instr_i = instr;

assign data_req_o = data_req_o_reg;
assign data_we_o = data_we_o_reg;
assign data_be_o = data_be_o_reg;
assign data_addr_o = data_addr_o_reg;
assign data_wdata_o = data_wdata_o_reg; 
       
//Описание мультиплексора к PC_1
assign mult_PC_1 = branch_o ? imm_B : imm_J;
//Описание мультиплексора к PC_2
assign mult_PC_2 = ((comp && branch_o) || jal_o)? mult_PC_1 : 32'd4;
//Описание мультиплексор к PC_3
assign mult_PC_3 = PC + mult_PC_2;
//Описание блока PC

always @(posedge clk or negedge reset)
begin
  if(!reset)
   PC <= 32'b0;
  else begin
    if(enpc)
     PC <= PC + 0;
     else
    PC <= jalr_o? RD1 + imm_I: mult_PC_3 ;
     end
end
assign instr_addr_o = PC;

//мультиплексор на RD1
assign rd1_out = (ex_op_a_sel_o == 2'b00) ? RD1: ((ex_op_a_sel_o == 2'b01) ? PC : 32'b0);
//мультиплексор на RD2
always @(*)
begin
case(ex_op_b_sel_o)
 3'b0: rd2_out <= RD2;
 3'b001: rd2_out <= imm_I;
 3'b010: rd2_out <= {fetched_instr_i[31:12],22'b0};
 3'b011: rd2_out <= imm_S;
 3'b100: rd2_out <= 32'd4;
 default: rd2_out <= 32'd0;
endcase
end

//мультиплексор на LSU
assign mult_LSU = wb_src_sel_o? lsu_rd : aluOut;

endmodule

