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


module apb_slave_dut #(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 8) (
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

    typedef enum logic [2:0] {
        IDLE   = 3'b001,
        SETUP  = 3'b010,
        ACCESS = 3'b100
    } apb_state_t;

    apb_state_t present_state, next_state;
    logic [DATA_WIDTH-1:0] mem [0:ADDR_WIDTH-1];
    logic [4:0] addr_index;

    assign addr_index = PADDR[6:2]; // align address to a word-boundary

    initial begin
        foreach (mem[i]) begin
            mem[i] = i;
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
                //if (!PSEL || !PENABLE) 
                if (!PSEL || (PENABLE && PREADY)) 
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    always_ff @(posedge PCLK) begin
        if ((present_state == ACCESS) && PSEL && PENABLE ) begin
            if (PWRITE) begin
                mem[addr_index] <= PWDATA;
            end else begin
                PRDATA <= mem[addr_index];
            end
        end
    end

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PREADY <= 1'b0;
            PSLVERR <= 1'b0;
            //PRDATA <= 0;
        end else begin
            //PREADY  <= 1'b0; // default
            if ((present_state == ACCESS)) begin
                PREADY <= 1'b1;
                if (addr_index > 31) begin
                    PSLVERR <= 1'b1;
                end else begin
                    PSLVERR <= 1'b0;
                end
            end else begin
                PREADY <= 1'b0;
                PSLVERR <= 1'b0;
            end
            //PSLVERR <= 1'b0;
        end
    end
endmodule
