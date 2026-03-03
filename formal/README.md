# Formal Verification Guide for APB UVC
# Using SymbiYosys (Yosys + ABC + Z3)

## Overview

This directory contains formal verification properties for the APB protocol
interface. These properties verify critical protocol constraints using
SymbiYosys formal verification toolchain.

## Prerequisites

Install required tools:
```bash
# Yosys with SAT support
sudo apt-get install yosys yosys-smtbmc

# ABC (included with Yosys)
# Already installed with Yosys

# Z3 SMT solver
sudo apt-get install z3
```

## Running Formal Verification

### Quick Check (All Properties)
```bash
cd formal
make verify
```

### Property-by-Property Check
```bash
cd formal
make prop-check
```

### Check Specific Property
```bash
cd formal
fmutil check --formal --abc --z3 --property prop_psel_onehot -t apb_interface apb_formal.sv
```

## Properties Verified

### 1. PSEL Protocol Properties

| Property | Description | Priority |
|----------|-------------|----------|
| `prop_psel_onehot` | Only one bit of PSEL can be high | **High** |
| `prop_psel_no_deassert_access` | PSEL cannot go low during ACCESS phase | **High** |
| `prop_psel_stable_setup` | PSEL stable during SETUP phase | High |
| `prop_psel_stable_access` | PSEL stable during ACCESS phase | High |
| `prop_psel_before_penable` | PSEL must be high before PENABLE | High |

### 2. PENABLE Timing Properties

| Property | Description | Priority |
|----------|-------------|----------|
| `prop_penable_setup` | PENABLE setup constraint | High |
| `prop_penable_low_setup` | PENABLE must be low in SETUP | Medium |

### 3. PREADY Handshake Properties

| Property | Description | Priority |
|----------|-------------|----------|
| `prop_pready_timing_violation` | PREADY within 32 cycles | **High** |
| `prop_pready_completion` | PREADY eventually asserted | **High** |
| `prop_pready_valid` | PREADY only when valid | High |

### 4. PSLVERR Error Properties

| Property | Description | Priority |
|----------|-------------|----------|
| `prop_pslverr_valid_timing` | PSLVERR timing constraint | High |
| `prop_pslverr_stable` | PSLVERR stability | Medium |

### 5. Data Stability Properties

| Property | Description | Priority |
|----------|-------------|----------|
| `prop_pwdata_stable_during_access` | PWDATA stable during ACCESS | High |
| `prop_pstrb_stable_during_access` | PSTRB stable during ACCESS | High |
| `prop_prdata_valid_on_read` | PRDATA valid on read | **High** |
| `prop_paddr_stable_during_access` | PADDR stable during ACCESS | Medium |

### 6. Transaction Sequencing Properties

| Property | Description | Priority |
|----------|-------------|----------|
| `prop_no_psel_overlap` | No PSEL deassertion mid-ACCESS | **High** |

## Understanding Results

### PASS
Property is satisfied for all possible input sequences.

### FAIL
Property violation found. SymbiYosys will provide a counter-example trace
showing how the violation can occur.

### UNKNOWN
Tool could not prove or disprove the property within resource limits.
Try increasing time/memory limits or simplifying the property.

## Resource Limits

If properties return UNKNOWN, try:
```bash
fmutil check --formal --abc --z3 --time 3600 --memory 8192 -t apb_interface apb_formal.sv
```

## Integration with EDA Playground

For coverage testing with Cadence Xcellium on EDA Playground:

1. Add `COVERAGE` define in EDA Playground settings
2. Include `apb_formal.sv` in your testbench
3. Properties will be checked at runtime with `$error` on violation

Example EDA Playground configuration:
```yaml
language: systemverilog
tool: xcellium
defines:
  - "COVERAGE"
```

## Troubleshooting

### Yosys not found
```bash
which yosys || echo "Yosys not in PATH"
export PATH=$PATH:/path/to/yosys/bin
```

### Z3 not found
```bash
which z3 || echo "Z3 not in PATH"
export PATH=$PATH:/path/to/z3/bin
```

### Property check timeout
Increase timeout:
```bash
fmutil check --formal --abc --z3 --time 7200 -t apb_interface apb_formal.sv
```

## References

- [SymbiYosys Documentation](https://yosyshq.net/symbiyosys/)
- [APB Protocol Specification](https://developer.arm.com/documentation/ihi0022/latest/)
- [SystemVerilog Assertions](https://en.wikipedia.org/wiki/SystemVerilog#Assertions)

## Appendix: Property Details

### prop_psel_onehot
**Invariant**: At any clock cycle, at most one bit of PSEL can be high.
```systemverilog
property prop_psel_onehot;
    @(posedge pclk) disable iff (!prstn)
    $onehot0(psel);
endproperty
```

### prop_psel_no_deassert_access
**Critical**: PSEL cannot be deasserted during ACCESS phase.
This ensures slaves can complete their response before master moves on.
```systemverilog
property prop_psel_no_deassert_access;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable && pready) |-> psel;
endproperty
```

### prop_pready_timing_violation
**Timing**: PREADY must respond within 32 cycles.
This is a bounded liveness property.
```systemverilog
property prop_pready_timing_violation;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable && !pready) |-> ##[1:32] pready;
endproperty
```

### prop_no_psel_overlap
**Edge Case**: Detects PSEL deassertion during ACCESS.
```systemverilog
property prop_no_psel_overlap;
    @(posedge pclk) disable iff (!prstn)
    (psel && penable && !pready) |-> !($past(psel) && !psel);
endproperty
```