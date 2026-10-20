 `timescale 1ns / 1ps
module calc_tb;

    reg         clk;
    reg         rst;
    reg         start;
    reg  [15:0] instr;
    wire        busy;
    wire        done;
    wire [31:0] result;

    localparam OP_ADD   = 4'b0001;
    localparam OP_SUB   = 4'b0010;
    localparam OP_MUL   = 4'b0011;
    localparam OP_AND   = 4'b0100;
    localparam OP_OR    = 4'b0101;
    localparam OP_XOR   = 4'b0110;
    localparam OP_SHL   = 4'b0111;
    localparam OP_SHR   = 4'b1000;
    localparam OP_DIV   = 4'b1010;
    localparam OP_LOADI = 4'b1001;

    calc_top dut (
        .clk(clk), .rst(rst), .start(start), .instr(instr),
        .busy(busy), .done(done), .result(result)
    );
 
    initial clk = 0;
    always #5 clk = ~clk;
 
    function [15:0] mk_instr;
        input [3:0] op;
        input [2:0] rd, rs1, rs2;
        begin
            mk_instr = {op, rd, rs1, rs2, 3'b000};
        end
    endfunction

    function [15:0] mk_loadi;
        input [2:0] rd;
        input [8:0] imm;
        begin
            mk_loadi = {OP_LOADI, rd, imm};
        end
    endfunction
 
    task run_instr;
        input [15:0] i;
        begin
            @(posedge clk);
            instr = i;
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;
            wait (done == 1'b1);
            @(posedge clk); 
            $display("t=%0t  instr=%h  result=%0d (0x%h)  [rs1_data=%0d rs2_data=%0d alu=%0d]",
                      $time, i, $signed(result), result,
                      dut.rs1_data, dut.rs2_data, dut.alu_result);
        end
    endtask

    initial begin
        rst   = 1'b1;
        start = 1'b0;
        instr = 16'd0;
        repeat (3) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        // R1 = 10, R2 = 5
        run_instr(mk_loadi(3'd1, 9'd10));
        run_instr(mk_loadi(3'd2, 9'd5));

        // R3 = R1 + R2 = 15
        run_instr(mk_instr(OP_ADD, 3'd3, 3'd1, 3'd2));
        // R4 = R1 - R2 = 5
        run_instr(mk_instr(OP_SUB, 3'd4, 3'd1, 3'd2));
        // R5 = R1 * R2 = 50
        run_instr(mk_instr(OP_MUL, 3'd5, 3'd1, 3'd2));
        // R6 = R1 / R2 = 2
        run_instr(mk_instr(OP_DIV, 3'd6, 3'd1, 3'd2));
        // R7 = R1 & R2
        run_instr(mk_instr(OP_AND, 3'd7, 3'd1, 3'd2));
        // R0 = R1 | R2  
        run_instr(mk_instr(OP_OR,  3'd0, 3'd1, 3'd2));
        // R1 = R1 ^ R2
        run_instr(mk_instr(OP_XOR, 3'd1, 3'd1, 3'd2));
        // R2 = R1 << R2  (shift-by-register)
        run_instr(mk_instr(OP_SHL, 3'd2, 3'd1, 3'd2));

        $display("Simulation finished.");
        $finish;
    end

endmodule
