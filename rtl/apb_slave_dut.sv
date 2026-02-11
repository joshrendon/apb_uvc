`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Josh Rendon
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
    output logic PREADY,

    // Physical Arty A7 Pins
    output logic [3:0]            leds,
    output logic [5:0]            rgb_leds,
    input  logic [3:0]            switches,
    input  logic [3:0]            buttons
    );

    localparam REG_BASE_ADDR = 32'h4000_1000;
    localparam ADDR_BASE_REGION_MAX = 32'h4000_0000;
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

    // Internal Registers
    logic [3:0]  r_leds;
    logic [5:0]  r_rgb;
    logic [31:0] r_scratch;
    
    // Connect internal registers to output pins
    assign leds     = switches;
    assign rgb_leds = r_rgb;

    // Address Decoding Logic
    // We check if the incoming address is within our 0x1000 - 0x101F range
    wire is_reg_space = (PADDR >= REG_BASE_ADDR) && (PADDR <= (REG_BASE_ADDR + 32'h1F));
    wire bus_setup    = PSEL && !PENABLE;
    wire bus_access   = PSEL && PENABLE;

    //wire reg_space_sel = (PADDR >= 32'h1000 && PADDR <= 32'h101F);

    assign addr_index = PADDR[INDEX_BITS+1:2]; // align address to a word-boundary
    //assign PRDATA = prdata_reg;

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
            r_leds    <= 4'h0;
            r_rgb     <= 6'h0;
            r_scratch <= 32'h0;
        end else begin
            if (bus_access && PWRITE && is_reg_space) begin
                case (PADDR)
                  (REG_BASE_ADDR + 32'h00): r_leds    <= PWDATA[3:0];
                  (REG_BASE_ADDR + 32'h04): r_rgb     <= PWDATA[5:0];
                  (REG_BASE_ADDR + 32'h10): r_scratch <= PWDATA;
                  default: ; // Ignore writes to RO registers or undefined space
                endcase
            end else if ((present_state == ACCESS) && PSEL && PENABLE ) begin
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

  // Read Logic
  always_comb begin
      PRDATA = 32'h0;
      if ((present_state == ACCESS) && !PWRITE) begin
          if (is_reg_space) begin
            case (PADDR)
              (REG_BASE_ADDR + 32'h00): PRDATA = {28'h0, r_leds};
              (REG_BASE_ADDR + 32'h04): PRDATA = {26'h0, r_rgb};
              (REG_BASE_ADDR + 32'h08): PRDATA = {24'h0, switches, buttons}; // Combined inputs
              (REG_BASE_ADDR + 32'h0C): PRDATA = 32'hA735_0001;              // Hardcoded ID
              (REG_BASE_ADDR + 32'h10): PRDATA = r_scratch;
              default:                  PRDATA = 32'h0;
            endcase
          end else begin
            // Fallback: This is where your legacy address (0x00 - 0x0F) logic lives
            PRDATA = prdata_reg;
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
                if ((PADDR - ADDR_BASE_REGION_MAX)> ADDR_MAX) begin
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
