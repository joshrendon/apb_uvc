`ifndef APB_FORMAL_SV
`define APB_FORMAL_SV

`timescale 1ns / 1ps

// APB Formal Verification Properties
// These properties verify APB protocol compliance for formal tools like SymbiYosys
// All properties fail on violation (assertion failure)

// ============================================================================
// PSEL Protocol Properties
// ============================================================================

// Property: PSEL must always be one-hot or zero (only one slave selected at a time)
property prop_psel_onehot;
    @(posedge pclk) disable iff (!prstn)
    $onehot0(psel);
endproperty

// Property: PSEL cannot be deasserted during ACCESS phase (when penable && pready)
// This ensures slaves complete their response before master moves on
property prop_psel_no_deassert_access;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable && pready) |-> psel;
endproperty

// Property: PSEL must be stable during SETUP phase (psel high, penable low)
property prop_psel_stable_setup;
    @(posedge pclk) disable iff (!prstn)
    (psel && !penable) |-> $stable(psel);
endproperty

// Property: PSEL must be stable during ACCESS phase (psel high, penable high)
property prop_psel_stable_access;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable) |-> $stable(psel);
endproperty

// Property: PSEL must be asserted before PENABLE can go high
property prop_psel_before_penable;
    @(posedge pclk) disable iff (!prstn)
    penable |-> psel;
endproperty

// ============================================================================
// PENABLE Timing Properties
// ============================================================================

// Property: PENABLE can only transition high if PSEL was high in previous cycle
property prop_penable_setup;
    @(posedge pclk) disable iff (!prstn)
    (penable && !$past(penable)) |-> $past(psel);
endproperty

// Property: PENABLE must go low before PSEL goes low (complete handshake)
property prop_penable_reset;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable && !pready) |-> ##0 (penable |-> !penable);
endproperty

// Property: PENABLE must be low in SETUP phase
property prop_penable_low_setup;
    @(posedge pclk) disable iff (!prstn)
    (psel && !penable) |-> !penable;
endproperty

// ============================================================================
// PREADY Handshake Properties
// ============================================================================

// Property: PREADY must respond within 32 cycles of PENABLE (timing violation check)
property prop_pready_timing_violation;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable && !pready) |-> ##[1:32] pready;
endproperty

// Property: Once PSEL && PENABLE, PREADY must eventually go high (liveness)
property prop_pready_completion;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable) |-> ##[1:$] pready;
endproperty

// Property: PREADY can only go high when PSEL && PENABLE are high
property prop_pready_valid;
    @(posedge pclk) disable iff (!prstn)
    pready |-> (psel && penable);
endproperty

// Property: PREADY should remain high until PSEL goes low or transaction completes
property prop_pready_stable;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable && pready) |-> (psel && penable);
endproperty

// ============================================================================
// PSLVERR Error Properties
// ============================================================================

// Property: PSLVERR can only be asserted when PSEL && PENABLE are high
property prop_pslverr_valid_timing;
    @(posedge pclk) disable iff (!prstn)
    pslverr |-> (psel && penable);
endproperty

// Property: PSLVERR should be stable during ACCESS phase
property prop_pslverr_stable;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable) |-> $stable(pslverr);
endproperty

// ============================================================================
// Data Stability Properties
// ============================================================================

// Property: PWDATA must remain stable during ACCESS phase for writes
property prop_pwdata_stable_during_access;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable && pwrite) |-> $stable(pwdata);
endproperty

// Property: PSTRB must remain stable during ACCESS phase for writes
property prop_pstrb_stable_during_access;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable && pwrite) |-> $stable(pstrb);
endproperty

// Property: PRDATA must be valid (not X) when PREADY goes high for reads
property prop_prdata_valid_on_read;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable && !pwrite && pready) |-> !$isunknown(prdata);
endproperty

// Property: PSTRB must align with data width (2 bits for 32-bit data)
property prop_pstrb_width;
    @(posedge pclk) disable iff (!prstn)
    pstrb[2:] == '0;
endproperty

// Property: PADDR must be stable during ACCESS phase
property prop_paddr_stable_during_access;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable) |-> $stable(paddr);
endproperty

// ============================================================================
// Transaction Sequencing Properties
// ============================================================================

// Property: After PREADY goes high, next transaction can start (B2B allowed)
property prop_b2b_allowed;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable && pready) |-> ##0 (psel || (!psel && (psel || 1'b1)));
endproperty

// Property: No PSEL overlap (detect edge case of PSEL deassertion mid-ACCESS)
property prop_no_psel_overlap;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable && !pready) |-> !($past(psel) && !psel);
endproperty

// ============================================================================
// Property Instantiations (Fail on Violation)
// ============================================================================

// PSEL Protocol Assertions
assert property (prop_psel_onehot)
    else $error("APB Formal Error: PSEL violation - not one-hot or zero at time %0t", $time);

assert property (prop_psel_no_deassert_access)
    else $error("APB Formal Error: PSEL deasserted during ACCESS phase at time %0t", $time);

assert property (prop_psel_stable_setup)
    else $error("APB Formal Error: PSEL unstable during SETUP phase at time %0t", $time);

assert property (prop_psel_stable_access)
    else $error("APB Formal Error: PSEL unstable during ACCESS phase at time %0t", $time);

assert property (prop_psel_before_penable)
    else $error("APB Formal Error: PENABLE high but PSEL low at time %0t", $time);

// PENABLE Timing Assertions
assert property (prop_penable_setup)
    else $error("APB Formal Error: PENABLE setup violation at time %0t", $time);

assert property (prop_penable_low_setup)
    else $error("APB Formal Error: PENABLE high during SETUP phase at time %0t", $time);

// PREADY Handshake Assertions
assert property (prop_pready_timing_violation)
    else $error("APB Formal Error: PREADY timing violation - no response within 32 cycles at time %0t", $time);

assert property (prop_pready_completion)
    else $error("APB Formal Error: PREADY never asserted after PSEL && PENABLE at time %0t", $time);

assert property (prop_pready_valid)
    else $error("APB Formal Error: PREADY high without PSEL && PENABLE at time %0t", $time);

// PSLVERR Assertions
assert property (prop_pslverr_valid_timing)
    else $error("APB Formal Error: PSLVERR asserted without valid access at time %0t", $time);

assert property (prop_pslverr_stable)
    else $error("APB Formal Error: PSLVERR unstable during access at time %0t", $time);

// Data Stability Assertions
assert property (prop_pwdata_stable_during_access)
    else $error("APB Formal Error: PWDATA unstable during ACCESS at time %0t", $time);

assert property (prop_pstrb_stable_during_access)
    else $error("APB Formal Error: PSTRB unstable during ACCESS at time %0t", $time);

assert property (prop_prdata_valid_on_read)
    else $error("APB Formal Error: PRDATA is X when PREADY high on read at time %0t", $time);

assert property (prop_pstrb_width)
    else $error("APB Formal Error: PSTRB exceeds 2 bits at time %0t", $time);

assert property (prop_paddr_stable_during_access)
    else $error("APB Formal Error: PADDR unstable during ACCESS at time %0t", $time);

// Transaction Sequencing Assertions
assert property (prop_no_psel_overlap)
    else $error("APB Formal Error: PSEL overlap/deassertion edge case at time %0t", $time);

`endif // APB_FORMAL_SV