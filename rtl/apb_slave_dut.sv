`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/08/2026 11:19:35 AM
// Design Name: 
// Module Name: apb_dut
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module apb_slave_dut 
#(parameter AW=32, parameter DW=32, parameter SW=4, parameter DEPTH=256) (
    input PCLK,
    input PRESETn,
    input [AW-1:0] PADDR,
    input [2:0] PPROT,
    input PNSE,
    input PSEL,
    input PENABLE,
    input PWRITE,
    input [DW-1:0] PWDATA,
    input [SW-1:0] PSTRB,
    output logic PSLVERR,
    output logic [DW-1:0] PRDATA,
    output logic PREADY
    );

    localparam ADDR_MAX = 32'h0001_0000; // Max size 64KB large
    localparam INDEX_BITS = $clog2(DEPTH);

    typedef enum logic [2:0] {
        IDLE   = 3'b001,
        SETUP  = 3'b010,
        ACCESS = 3'b100
    } apb_state_t;

    apb_state_t present_state, next_state;
    logic [DW-1:0] mem [0:DEPTH-1];
    logic [INDEX_BITS-1:0] addr_index;
    logic [DW-1:0] prdata_reg;

    assign addr_index = PADDR[INDEX_BITS+1:2]; // align address to a word-boundary
    assign PRDATA = prdata_reg;

    initial begin
        foreach (mem[i]) begin
            mem[i] = '0;
        end
    end

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            present_state <= IDLE;
        end else begin
            present_state <= next_state;
        end
    end

    always_comb begin
        next_state = present_state;
        case (present_state)
            IDLE: begin
                if (PSEL)
                    next_state = SETUP;
            end
            SETUP: begin
                if (PSEL && PENABLE) begin
                    next_state = ACCESS;
                end else if (!PSEL) begin
                    next_state = IDLE;
                end
            end
            ACCESS: begin
                if (!PSEL || (PENABLE && PREADY)) 
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            prdata_reg <= '0;
        end else begin
            if ((present_state == ACCESS) && PSEL && PENABLE ) begin
                if (PWRITE) begin
                    for (int i = 0; i < (DW/8); i++) begin
                        if (PSTRB[i]) begin
                            mem[addr_index][(i*8) +: 8] <= PWDATA[(i*8) +: 8];
                        end
                    end
                end else begin
                    prdata_reg <= mem[addr_index];
                end
            end
        end
    end

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PREADY <= 1'b0;
            PSLVERR <= 1'b0;
        end else begin
            if ((present_state == ACCESS)) begin
                PREADY <= 1'b1;
                if (addr_index > ADDR_MAX) begin
                    PSLVERR <= 1'b1;
                end else if (PWRITE && (PADDR == 32'h0000_4000)) begin //Error if write to Read-only address (32'h0000_4000)
                    PSLVERR <= 1'b1;
                end else begin
                    PSLVERR <= 1'b0;
                end
            end else begin
                PREADY <= 1'b0;
                PSLVERR <= 1'b0;
            end
        end
    end
endmodule
