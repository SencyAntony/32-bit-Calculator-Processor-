`timescale 1ns / 1ps
module alu (
    input  wire [3:0]  op,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] result,
    output reg          div_by_zero
);

    // opcodes
    localparam OP_NOP   = 4'b0000;
    localparam OP_ADD   = 4'b0001;
    localparam OP_SUB   = 4'b0010;
    localparam OP_MUL   = 4'b0011;
    localparam OP_AND   = 4'b0100;
    localparam OP_OR    = 4'b0101;
    localparam OP_XOR   = 4'b0110;
    localparam OP_SHL   = 4'b0111;
    localparam OP_SHR   = 4'b1000;
    localparam OP_DIV   = 4'b1010;

    always @(*) begin
        div_by_zero = 1'b0;                       
        case (op)
            OP_ADD: result = a + b;
            OP_SUB: result = a - b;
            OP_MUL: result = a * b;              
            OP_AND: result = a & b;
            OP_OR:  result = a | b;
            OP_XOR: result = a ^ b;
            OP_SHL: result = a << b[4:0];
            OP_SHR: result = a >> b[4:0];
            OP_DIV: begin
                if (b == 32'd0) begin
                    result = 32'd0;
                    div_by_zero = 1'b1;
                end else begin
                    result = a / b;
                end
            end
            default: result = 32'd0;             
        endcase
    end

endmodule
