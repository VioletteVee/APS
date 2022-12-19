`timescale 1ns / 1ps

`include "./defines_riscv.vh"

`define RESET_ADDR 32'h00000000

`define ALU_OP_WIDTH  5

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

// opcodes
`define LOAD_OPCODE      5'b00_000
`define MISC_MEM_OPCODE  5'b00_011
`define OP_IMM_OPCODE    5'b00_100
`define AUIPC_OPCODE     5'b00_101
`define STORE_OPCODE     5'b01_000
`define OP_OPCODE        5'b01_100
`define LUI_OPCODE       5'b01_101
`define BRANCH_OPCODE    5'b11_000
`define JALR_OPCODE      5'b11_001
`define JAL_OPCODE       5'b11_011
`define SYSTEM_OPCODE    5'b11_100

// dmem type load store
`define LDST_B           3'b000
`define LDST_H           3'b001
`define LDST_W           3'b010
`define LDST_BU          3'b100
`define LDST_HU          3'b101

// operand a selection
`define OP_A_RS1         2'b00
`define OP_A_CURR_PC     2'b01
`define OP_A_ZERO        2'b10

// operand b selection
`define OP_B_RS2         3'b000
`define OP_B_IMM_I       3'b001
`define OP_B_IMM_U       3'b010
`define OP_B_IMM_S       3'b011
`define OP_B_INCR        3'b100

// writeback source selection
`define WB_EX_RESULT     1'b0
`define WB_LSU_DATA      1'b1


module decoder_riscv (
  input       [31:0]  fetched_instr_i,
  output  reg [1:0]   ex_op_a_sel_o,      // выходы сделаны регистрами,
  output  reg [2:0]   ex_op_b_sel_o,      // потому что всё устройство 
  output  reg [4:0]   alu_op_o,           // будет комбинационной схемой
  output  reg         mem_req_o,          // описанной внутри блока 
  output  reg         mem_we_o,           // always, а слева от знака равно
  output  reg [2:0]   mem_size_o,         // внутри always должны стоять
  output  reg         gpr_we_a_o,         // всегда только регистры,
  output  reg         wb_src_sel_o,       // даже если в итоге схема
  output  reg         illegal_instr_o,    // превратится в
  output  reg         branch_o,           // комбинационно устройство
  output  reg         jal_o,              // без памяти
  output  reg         jalr_o              // 
);

wire [7:0] func_7;
assign func_7 = fetched_instr_i [31:25];

wire [3:0] func_3;
assign func_3 = fetched_instr_i [14:12];

wire [4:0] opcode;
assign opcode = fetched_instr_i [6:2];  



always @(*) begin
  if (fetched_instr_i[1:0] != 2'b11) begin
                illegal_instr_o <= 1;
                wb_src_sel_o <= 0;
                ex_op_a_sel_o <= 2'b0;
                ex_op_b_sel_o <= 3'b0;
                alu_op_o <= 0;
                mem_req_o <= 0;
                mem_we_o <= 0;
                mem_size_o <= 0;
                gpr_we_a_o <= 0;
                branch_o <= 0;
                jal_o <= 0;
                jalr_o <= 0;
      end else begin
      case(opcode)
        `LOAD_OPCODE: begin 
          ex_op_a_sel_o <= 2'b0; 
          ex_op_b_sel_o <= 3'b1;
          mem_req_o <= 1'b1;
          mem_we_o <= 1'b0;
          gpr_we_a_o <= 1'b1;
          wb_src_sel_o <= 1'b1;
          branch_o <= 1'b0;
          jal_o <= 1'b0;
          jalr_o <= 1'b0;
          alu_op_o <= `ALU_ADD;
            case(func_3)
            3'h0: begin 
            mem_size_o <= `LDST_B;
            illegal_instr_o <= 1'b0;
            end
            3'h1: begin
            mem_size_o <= `LDST_H;
            illegal_instr_o <= 1'b0;
            end
            3'h2: begin
            mem_size_o <= `LDST_W;
            illegal_instr_o <= 1'b0;
            end
            3'h4: begin
            mem_size_o <= `LDST_BU;
            illegal_instr_o <= 1'b0;
            end
            3'h5: begin 
            mem_size_o <= `LDST_HU;
            illegal_instr_o <= 1'b0;
            end
            default: begin 
            illegal_instr_o <= 1'b1;
            ex_op_b_sel_o <= 3'b0;
            mem_req_o <= 1'b0;
            gpr_we_a_o <= 1'b0;
            wb_src_sel_o <= 1'b0;
            alu_op_o = 5'b0;
            end
            endcase
                      end
                      
        `MISC_MEM_OPCODE: begin
          ex_op_a_sel_o <= 2'b0; 
          ex_op_b_sel_o <= 3'b0;
          mem_req_o <= 1'b0;
          mem_we_o <= 1'b0;
          gpr_we_a_o <= 1'b0;
          wb_src_sel_o <= 1'b0;
          illegal_instr_o <= 1'b0;
          branch_o <= 1'b0;
          jal_o <= 1'b0;
          jalr_o <= 1'b0;
          alu_op_o <= 5'b0;
          mem_size_o <= 3'd0;
                          end
                          
        `OP_IMM_OPCODE: begin
          ex_op_a_sel_o <= 2'b0; 
          ex_op_b_sel_o <= 3'b1;
          mem_req_o <= 1'b0;
          mem_we_o <= 1'b0;
          gpr_we_a_o <= 1'b1;
          wb_src_sel_o <= 1'b0;
          branch_o <= 1'b0;
          jal_o <= 1'b0;
          jalr_o <= 1'b0;
          mem_size_o <= 3'b0;
          mem_size_o <= `LDST_B;
            case(func_3)
            3'h0: begin
            alu_op_o <= `ALU_ADD;
            illegal_instr_o <= 1'b0;
            end
            3'h4: begin
            alu_op_o <= `ALU_XOR;
            illegal_instr_o <= 1'b0;
            end
            3'h6: begin
            alu_op_o <= `ALU_OR;
            illegal_instr_o <= 1'b0;
            end
            3'h7: begin
            alu_op_o <= `ALU_AND;
            illegal_instr_o <= 1'b0;
            end
            3'h1: if (func_7 == 7'h00) begin
                  alu_op_o <= `ALU_SLL;
                  illegal_instr_o <= 1'b0;
                  end else begin
                  illegal_instr_o <= 1'b1;
                  ex_op_b_sel_o <= 3'b0;
                  gpr_we_a_o <= 1'b0;
                  mem_size_o <= 3'd0;
                  alu_op_o <= 5'b0;
                  end
            3'h5: case(func_7)
                  7'h00: begin
                  alu_op_o <= `ALU_SRL;
                  illegal_instr_o <= 1'b0;
                  end
                  7'h20: begin
                  alu_op_o <= `ALU_SRA;
                  illegal_instr_o <= 1'b0;
                  end
                  default: begin
                  illegal_instr_o <= 1'b1;
                  gpr_we_a_o <= 1'b0;
                  ex_op_b_sel_o <= 3'b0;
                  alu_op_o <= 5'b0;
                  end
                  endcase
            3'h2: begin
            alu_op_o <= `ALU_SLTS;
            illegal_instr_o <= 1'b0;
            end
            3'h3: begin 
            alu_op_o <= `ALU_SLTU;
            illegal_instr_o <= 1'b0;
            end
            default: begin
                  illegal_instr_o <= 1'b1;
                  gpr_we_a_o <= 1'b0;
                  ex_op_b_sel_o <= 3'b0;
                  alu_op_o <= 5'b0;
                  end
            endcase
                        end
                        
        `AUIPC_OPCODE: begin
          ex_op_a_sel_o <= 2'b01; 
          ex_op_b_sel_o <= 3'b010;
          mem_req_o <= 1'b0;
          mem_we_o <= 1'b0;
          gpr_we_a_o <= 1'b1;
          wb_src_sel_o <= 1'b0;
          illegal_instr_o <= 1'b0;
          branch_o <= 1'b0;
          jal_o <= 1'b0;
          jalr_o <= 1'b0;
          alu_op_o <= `ALU_ADD;
          mem_size_o <= 3'd0;              
                       end
                       
        `STORE_OPCODE: begin
          ex_op_a_sel_o <= 2'b0; 
          ex_op_b_sel_o <= 3'b011;
          mem_req_o <= 1'b1;
          mem_we_o <= 1'b1;
          gpr_we_a_o <= 1'b0;
          wb_src_sel_o <= 1'b1;
          branch_o <= 1'b0;
          jal_o <= 1'b0;
          jalr_o <= 1'b0;
          alu_op_o <= `ALU_ADD;
            case(func_3)
            3'h0: begin
            mem_size_o <= `LDST_B; 
            illegal_instr_o <= 1'b0;
            end
            3'h1: begin
            mem_size_o <= `LDST_H; 
            illegal_instr_o <= 1'b0;
            end
            3'h2: begin 
            mem_size_o <= `LDST_W; 
            illegal_instr_o <= 1'b0;
            end
            default: begin
            illegal_instr_o <= 1'b1;
            ex_op_b_sel_o <= 3'b0;
            mem_req_o <= 1'b0;
            mem_we_o <= 1'b0;
            wb_src_sel_o <= 1'b0;
            alu_op_o <= 5'b0;
            end
            endcase
                       end
        
        `OP_OPCODE: begin
          ex_op_a_sel_o <= 2'b0; 
          ex_op_b_sel_o <= 3'b0;
          mem_req_o <= 1'b0;
          mem_we_o <= 1'b0;
          gpr_we_a_o <= 1'b1;
          wb_src_sel_o <= 1'b0;
          branch_o <= 1'b0;
          jal_o <= 1'b0;
          jalr_o <= 1'b0;
          mem_size_o <= 3'd0; 
          case(func_3)
          3'h0: case(func_7)
                7'h00: begin
                alu_op_o <= `ALU_ADD;
                illegal_instr_o <= 1'b0;
                end
                7'h20: begin 
                alu_op_o <= `ALU_SUB;
                illegal_instr_o <= 1'b0;
                end
                default: begin
                illegal_instr_o <= 1'b1;
                alu_op_o <= 5'b0;
                gpr_we_a_o <= 1'b1;
                         end
                endcase
          3'h4: if (func_7 == 7'h00) begin
                alu_op_o <= `ALU_XOR;
                illegal_instr_o <= 1'b0;
                end else begin
                  illegal_instr_o <= 1'b1;
                  gpr_we_a_o <= 1'b0;
                  alu_op_o <= 5'b0;
                  end
          3'h6: if (func_7 == 7'h00) begin
                alu_op_o <= `ALU_OR;
                illegal_instr_o <= 1'b0;
                end else begin
                  illegal_instr_o <= 1'b1;
                  gpr_we_a_o <= 1'b0;
                  alu_op_o <= 5'b0;
                  end
          3'h7: if (func_7 == 7'h00) begin
                alu_op_o <= `ALU_AND;
                illegal_instr_o <= 1'b0;
                end else begin
                  illegal_instr_o <= 1'b1;
                  gpr_we_a_o <= 1'b0;
                  alu_op_o <= 5'b0;
                  end
          3'h1: if (func_7 == 7'h00) begin
                  alu_op_o <= `ALU_SLL;
                  illegal_instr_o <= 1'b0;
                  end else begin
                  illegal_instr_o <= 1'b1;
                  gpr_we_a_o <= 1'b0;
                  alu_op_o <= 5'b0;
                  end
          3'h5:case(func_7)
                  7'h00: begin
                  alu_op_o <= `ALU_SRL;
                  illegal_instr_o <= 1'b0;
                  end
                  7'h20: begin 
                  alu_op_o <= `ALU_SRA;
                  illegal_instr_o <= 1'b0;
                  end
                  default: begin
                  illegal_instr_o <= 1'b1;
                  alu_op_o <= 5'b0;
                  gpr_we_a_o <= 1'b1;
                         end
               endcase
          3'h2: if (func_7 == 7'h00) begin
                alu_op_o <= `ALU_SLTS;
                illegal_instr_o <= 1'b0;
                end else begin
                  illegal_instr_o <= 1'b1;
                  gpr_we_a_o <= 1'b0;
                  alu_op_o <= 5'b0;
                  end
          3'h3: if (func_7 == 7'h00) begin
                alu_op_o <= `ALU_SLTU;
                illegal_instr_o <= 1'b0;
                end else begin
                  illegal_instr_o <= 1'b1;
                  gpr_we_a_o <= 1'b0;
                  alu_op_o <= 5'b0;
                  end
          default: begin
                  illegal_instr_o <= 1'b1;
                  alu_op_o <= 5'b0;
                  gpr_we_a_o <= 1'b1;
                         end
          endcase
                    end
        `LUI_OPCODE: begin
          ex_op_a_sel_o <= 2'b10; 
          ex_op_b_sel_o <= 3'b010;
          mem_req_o <= 1'b0;
          mem_we_o <= 1'b0;
          gpr_we_a_o <= 1'b1;
          wb_src_sel_o <= 1'b0;
          illegal_instr_o <= 1'b0;
          branch_o <= 1'b0;
          jal_o <= 1'b0;
          jalr_o <= 1'b0;
          alu_op_o <= `ALU_ADD;
          mem_size_o <= 3'd0; 
                     end
        `BRANCH_OPCODE: begin
          ex_op_a_sel_o <= 2'b0; 
          ex_op_b_sel_o <= 3'b0;
          mem_req_o <= 1'b0;
          mem_we_o <= 1'b0;
          gpr_we_a_o <= 1'b0;
          wb_src_sel_o <= 1'b0;
          branch_o <= 1'b1;
          jal_o <= 1'b0;
          jalr_o <= 1'b0;
          alu_op_o <= `ALU_ADD;
          mem_size_o <= 3'd0; 
            case(func_3)
            3'h0: begin
            alu_op_o <= `ALU_EQ;
            illegal_instr_o <= 1'b0;
            end
            3'h1: begin
            alu_op_o <= `ALU_NE;
            illegal_instr_o <= 1'b0;
            end
            3'h4: begin
            alu_op_o <= `ALU_LTS;
            illegal_instr_o <= 1'b0;
            end
            3'h5: begin
            alu_op_o <= `ALU_GES;
            illegal_instr_o <= 1'b0;
            end
            3'h6: begin
            alu_op_o <= `ALU_LTU;
            illegal_instr_o <= 1'b0;
            end
            3'h7: begin
            alu_op_o <= `ALU_GEU;
            illegal_instr_o <= 1'b0;
            end
            default: begin
            illegal_instr_o <= 1'b1;
            alu_op_o <= 5'b0;
            branch_o <= 1'b0;
                     end
            endcase
                        end
        `JALR_OPCODE: if(func_3 == 3'h0) begin
          ex_op_a_sel_o <= 2'b01; 
          ex_op_b_sel_o <= 3'b100;
          mem_req_o <= 1'b0;
          mem_we_o <= 1'b0;
          gpr_we_a_o <= 1'b1;
          wb_src_sel_o <= 1'b0;
          illegal_instr_o <= 1'b0;
          branch_o <= 1'b0;
          jal_o <= 1'b0;
          jalr_o <= 1'b1;
          alu_op_o <= `ALU_ADD;
          mem_size_o <= 3'd0; 
                     end else begin
                     illegal_instr_o <= 1'b1;
                     ex_op_a_sel_o <= 2'b0; 
                     ex_op_b_sel_o <= 3'b0;
                     gpr_we_a_o <= 1'b1;
                     jalr_o <= 1'b0;
                     alu_op_o <= 5'b0;
                     end
            
        `JAL_OPCODE: begin
          ex_op_a_sel_o <= 2'b01; 
          ex_op_b_sel_o <= 3'b100;
          mem_req_o <= 1'b0;
          mem_we_o <= 1'b0;
          gpr_we_a_o <= 1'b1;
          wb_src_sel_o <= 1'b0;
          illegal_instr_o <= 1'b0;
          branch_o <= 1'b0;
          jal_o <= 1'b1;
          jalr_o <= 1'b0;
          alu_op_o <= `ALU_ADD;
          mem_size_o <= 3'd0; 
                     end
                     
        `SYSTEM_OPCODE: begin
          ex_op_a_sel_o <= 2'b0; 
          ex_op_b_sel_o <= 3'b0;
          mem_req_o <= 1'b0;
          mem_we_o <= 1'b0;
          gpr_we_a_o <= 1'b0;
          wb_src_sel_o <= 1'b0;
          illegal_instr_o <= 1'b0;
          branch_o <= 1'b0;
          jal_o <= 1'b0;
          jalr_o <= 1'b0;
          alu_op_o <= 5'b0;
          mem_size_o <= 3'd0; 
                     end
          default: begin
          ex_op_a_sel_o <= 2'b0; 
          ex_op_b_sel_o <= 3'b0;
          mem_req_o <= 1'b0;
          mem_we_o <= 1'b0;
          gpr_we_a_o <= 1'b0;
          wb_src_sel_o <= 1'b0;
          illegal_instr_o <= 1'b1;
          branch_o <= 1'b0;
          jal_o <= 1'b0;
          jalr_o <= 1'b0;
          alu_op_o <= 5'b0;
          mem_size_o <= 3'd0; 
                   end
         
      endcase
      end

end

endmodule