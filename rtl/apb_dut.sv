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


module apb_dut #(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 8) (
    input PCLK,
    input PRESETn,
    input [ADDR_WIDTH-1:0] PADDR,
    input [2:0] PPROT,
    input PNSE,
    input PSEL,
    input PENABLE,
    input PWRITE,
    input [DATA_WIDTH-1:0] PWDATA,
    output logic PSLVERR,
    output logic [DATA_WIDTH-1:0] PRDATA,
    output reg PREADY
    );

    typedef enum logic [1:0] {
        IDLE   = 2'b00,
        SETUP  = 2'b01,
        ACCESS = 2'b10
    } apb_state_t;

    apb_state_t present_state, next_state;
    logic [DATA_WIDTH-1:0] mem [0:ADDR_WIDTH-1];
    logic [4:0] addr_index;

    assign addr_index = PADDR[6:2]; // align address to a word-boundary

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            present_state <= IDLE;
        else
            present_state <= next_state;
    end

    always_comb begin
        next_state = present_state;
        case (present_state)
            IDLE:   if (PSEL && !PENABLE)  next_state = SETUP;
            SETUP:  if (PSEL && PENABLE)   next_state = ACCESS;
                    else if (!PSEL)        next_state = IDLE;
            ACCESS: if (!PSEL || !PENABLE) next_state = IDLE;
                    else                   next_state = ACCESS;
        endcase
    end

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PREADY <= 1'b0;
            PSLVERR <= 1'b0;
            PRDATA <= '0;
        end else begin
            PREADY <= 1'b0; // default
            PSLVERR <= 1'b0;
            if (present_state == ACCESS && PSEL && PENABLE ) begin
                if (PWRITE) begin
                    mem[addr_index] <= PWDATA;
                end else begin
                    PRDATA <= mem[addr_index];
                end
                PREADY <= 1'b1;
            end
        end
    end
endmodule
