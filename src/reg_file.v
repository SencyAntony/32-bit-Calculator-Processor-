`timescale 1ns / 1ps

// reg_file.v
// 8 x 32-bit register file, 2 async read ports, 1 sync write port
//------------------------------------------------------------------
module reg_file (
    input  wire        clk,
    input  wire        rst,

    input  wire [2:0]  ra_addr,   // read port A address
    input  wire [2:0]  rb_addr,   // read port B address
    output wire [31:0] ra_data,
    output wire [31:0] rb_data,

    input  wire         we,         // write enable
    input  wire [2:0]   wr_addr,
    input  wire [31:0]  wr_data
);

    reg [31:0] regs [0:7];
    integer i;

    // synchronous write, with write-through so a read right after a
    // write in the same cycle still sees the new value combinationally
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1)
                regs[i] <= 32'd0;
        end else if (we) begin
            regs[wr_addr] <= wr_data;
        end
    end

    // async read with write-through bypass
    assign ra_data = (we && (wr_addr == ra_addr)) ? wr_data : regs[ra_addr];
    assign rb_data = (we && (wr_addr == rb_addr)) ? wr_data : regs[rb_addr];

endmodule

