`timescale 1ns / 1ps

module RAM( 
     input            clk,
     input  [7:0]     adr,
     output [31:0]    rd
     
    );
    
reg [7:0] RAM [0:255];

initial $readmemh("memory.txt", RAM);

 assign rd = { RAM[adr], 
                 RAM[adr + 8'b1],
                 RAM[adr + 8'b10],
                 RAM[adr + 8'b11]};
                 

endmodule
