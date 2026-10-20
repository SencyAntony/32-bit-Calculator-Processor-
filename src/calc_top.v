`timescale 1ns / 1ps
//------------------------------------------------------------------
// calc_top.v
// 32-bit calculator processor: reg file + ALU + FSM control unit
//
// Instruction format (16 bits):
//   [15:12] opcode
//   [11:9]  rd            (destination register, always here)
//   [8:6]   rs1
//   [5:3]   rs2
//   [2:0]   unused (ALU ops)
//
// LOADI reuses bits [8:0] as a 9-bit signed immediate:
//   [15:12]=1001, [11:9]=rd, [8:0]=imm9
//------------------------------------------------------------------
module calc_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [15:0] instr,       // instruction presented by testbench/host
    output wire         busy,
    output wire         done,
    output wire [31:0]  result       // value written back this op
);

    localparam OP_LOADI = 4'b1001;

    // ---------------- instruction register ----------------
    reg [15:0] instr_reg;
    wire       latch_instr;

    always @(posedge clk or posedge rst) begin
        if (rst)               instr_reg <= 16'd0;
        else if (latch_instr)  instr_reg <= instr;
    end

    wire [3:0] opcode = instr_reg[15:12];
    wire [2:0] rd_addr  = instr_reg[11:9];
    wire [2:0] rs1_addr = instr_reg[8:6];
    wire [2:0] rs2_addr = instr_reg[5:3];
    wire [8:0] imm9     = instr_reg[8:0];
    wire [31:0] imm32   = {{23{imm9[8]}}, imm9}; // sign-extend

    wire is_loadi = (opcode == OP_LOADI);

    // ---------------- register file ----------------
    wire [31:0] rs1_data, rs2_data;
    wire         reg_write_en;

    // Raw (unregistered) candidate write-back value. NOTE: this must
    // NOT be wired directly into the regfile's write port, because if
    // rd == rs1/rs2 the regfile's write-through read bypass would feed
    // this value straight back into the ALU inputs that produced it,
    // forming a combinational loop. Instead it is captured into
    // wb_data_reg every cycle and that registered copy is what
    // actually drives the write port (see below).
    wire [31:0] raw_wr_data = is_loadi ? imm32 : alu_result;

    reg [31:0] wb_data_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wb_data_reg <= 32'd0;
        end else if (!reg_write_en) begin
            // Freeze once write-back begins: during the WB cycle the
            // regfile's own read-bypass could otherwise feed the
            // about-to-be-written value back into rs1_data/rs2_data
            // (when rd == rs1 or rd == rs2) and corrupt this capture
            // register on the following edge, even though the actual
            // register-file write itself (using this same signal as
            // wr_data) is unaffected and correct.
            wb_data_reg <= raw_wr_data;
        end
    end

    reg_file u_regfile (
        .clk(clk), .rst(rst),
        .ra_addr(rs1_addr), .rb_addr(rs2_addr),
        .ra_data(rs1_data), .rb_data(rs2_data),
        .we(reg_write_en), .wr_addr(rd_addr), .wr_data(wb_data_reg)
    );

    // ---------------- ALU ----------------
    wire [31:0] alu_result;
    wire         div_by_zero;

    alu u_alu (
        .op(opcode), .a(rs1_data), .b(rs2_data),
        .result(alu_result), .div_by_zero(div_by_zero)
    );

    // ---------------- control FSM ----------------
    control_fsm u_fsm (.clk(clk),.rst(rst),.start(start),.opcode(opcode),.is_loadi(is_loadi),.latch_instr(latch_instr),.reg_write_en(reg_write_en),.busy(busy),.done(done));

    assign result = wb_data_reg;

endmodule


//for hardware------------------------------------------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------------------------------------
`timescale 1ns / 1ps
module seg7_bank (
    input  wire        clk,
    input  wire [15:0] value,
    output reg  [7:0]  seg,
    output reg  [3:0]  an
);
    reg [19:0] refresh_cnt = 20'd0;
    wire [1:0] digit_sel;

    always @(posedge clk) refresh_cnt <= refresh_cnt + 1'b1;
    assign digit_sel = refresh_cnt[19:18];

    reg [3:0] nibble;
    always @(*) begin
        case (digit_sel)
            2'd0: begin nibble = value[3:0];   an = 4'b1110; end
            2'd1: begin nibble = value[7:4];   an = 4'b1101; end
            2'd2: begin nibble = value[11:8];  an = 4'b1011; end
            2'd3: begin nibble = value[15:12]; an = 4'b0111; end
        endcase
    end

    always @(*) begin
        case (nibble)
            4'h0: seg = 8'b11000000;
            4'h1: seg = 8'b11111001;
            4'h2: seg = 8'b10100100;
            4'h3: seg = 8'b10110000;
            4'h4: seg = 8'b10011001;
            4'h5: seg = 8'b10010010;
            4'h6: seg = 8'b10000010;
            4'h7: seg = 8'b11111000;
            4'h8: seg = 8'b10000000;
            4'h9: seg = 8'b10010000;
            4'ha: seg = 8'b10001000;
            4'hb: seg = 8'b10000011;
            4'hc: seg = 8'b11000110;
            4'hd: seg = 8'b10100001;
            4'he: seg = 8'b10000110;
            4'hf: seg = 8'b10001110;
            default: seg = 8'b11111111;
        endcase
    end
endmodule



`timescale 1ns / 1ps
module boolean_top (
    input  wire        mclk,
    input  wire [15:0] sw,
    input  wire [3:0]  btn,
    output wire [15:0] led,
    output wire [7:0]  D0_seg,
    output wire [3:0]  D0_a,
    output wire [7:0]  D1_seg,
    output wire [3:0]  D1_a
);
    wire [31:0] result;
    wire        busy, done;

    calc_top dut (
        .clk(mclk), .rst(btn[1]), .start(btn[0]),
        .instr(sw), .busy(busy), .done(done), .result(result)
    );

    seg7_bank bank_lo (.clk(mclk), .value(result[15:0]),  .seg(D0_seg), .an(D0_a));
    seg7_bank bank_hi (.clk(mclk), .value(result[31:16]), .seg(D1_seg), .an(D1_a));

    assign led[0] = busy;
    assign led[1] = done;
    assign led[15:2] = 14'd0;
endmodule