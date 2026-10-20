`timescale 1ns / 1ps
module control_fsm (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [3:0]  opcode,     
    input  wire         is_loadi,

    output reg          latch_instr,  
    output reg          reg_write_en,
    output reg          busy,
    output reg          done
);

    localparam S_IDLE      = 3'd0;
    localparam S_FETCH     = 3'd1;
    localparam S_DECODE    = 3'd2;
    localparam S_EXEC      = 3'd3;
    localparam S_EXEC_WAIT = 3'd4;
    localparam S_WB        = 3'd5;
    localparam S_DONE      = 3'd6;

    localparam OP_MUL = 4'b0011;
    localparam OP_DIV = 4'b1010;

    reg [2:0] state, next_state;
    reg [2:0] wait_cnt;
    reg [2:0] wait_target;
    always @(*) begin
        case (opcode)
            OP_MUL:  wait_target = 3'd1; 
            OP_DIV:  wait_target = 3'd3; 
            default: wait_target = 3'd0;
        endcase
    end

    //state register 
    always @(posedge clk or posedge rst) begin
        if (rst) state <= S_IDLE;
        else     state <= next_state;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wait_cnt <= 3'd0;
        end else if (state == S_EXEC) begin
            wait_cnt <= 3'd0;
        end else if (state == S_EXEC_WAIT) begin
            wait_cnt <= wait_cnt + 3'd1;
        end
    end

    //next-state logic
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:      next_state = start ? S_FETCH : S_IDLE;
            S_FETCH:     next_state = S_DECODE;
            S_DECODE:    next_state = S_EXEC;
            S_EXEC:      next_state = (wait_target == 0) ? S_WB : S_EXEC_WAIT;
            S_EXEC_WAIT: next_state = (wait_cnt >= wait_target - 1) ? S_WB : S_EXEC_WAIT;
            S_WB:        next_state = S_DONE;
            S_DONE:      next_state = S_IDLE;
            default:     next_state = S_IDLE;
        endcase
    end

    // output logic (Moore)
    always @(*) begin
        latch_instr  = (state == S_FETCH);
        reg_write_en = (state == S_WB);
        busy         = (state != S_IDLE) && (state != S_DONE);
        done         = (state == S_DONE);
    end

endmodule
