# APB UVC Formal Verification and Coverage Implementation Summary

## Implementation Date: February 25, 2026

## Overview

This implementation adds formal verification and comprehensive coverage to the APB UVC, enabling:
- Protocol compliance checking with SymbiYosys
- Functional coverage collection with EDA Playground/Xcellium
- B2B transaction detection and analysis
- Wait state and error condition coverage

## Files Created/Modified

### New Files

1. **formal/apb_formal.sv** (5.8 KB)
   - 19 SVA properties for APB protocol verification
   - All properties fail on violation with descriptive error messages
   - Covers PSEL, PENABLE, PREADY, PSLVERR, and data stability
   - Includes property instantiations with `$error` on failure

2. **formal/Makefile** (2.2 KB)
   - Build and verification targets for SymbiYosys
   - Property-by-property checking
   - Yosys + ABC + Z3 backend

3. **formal/README.md** (4.8 KB)
   - Comprehensive formal verification guide
   - Property documentation with priority levels
   - Troubleshooting and integration instructions

4. **sv/eda_playground.sv** (2.9 KB)
   - Coverage testbench for EDA Playground
   - Coverage report generation (HTML + text)
   - Coverage goal checking

5. **COVERAGE_GUIDE.md** (10.2 KB)
   - Complete coverage testing guide
   - Coverage group documentation
   - Best practices and gap analysis

6. **formal/IMPLEMENTATION_SUMMARY.md** (this file)

### Modified Files

1. **sv/apb_interface.sv**
   - Added `include "apb_formal.sv"` for SVA properties

2. **sv/apb_item.sv**
   - Added `is_b2b` field (back-to-back transaction flag)
   - Added `active_psel` field (PSEL index tracking)
   - Updated `uvm_object_utils` macros

3. **sv/apb_coverage.sv**
   - Enhanced `apb_master_coverage_subscriber` with comprehensive coverage groups
   - Added `apb_slave_coverage_subscriber` for slave response coverage
   - Added `apb_transaction_coverage_subscriber` for B2B analysis
   - Multiple cross-coverage bins for transaction patterns

4. **sv/apb_bus_monitor.sv**
   - Added B2B detection state tracking (`last_transaction_completed`, `prev_psel_active`)
   - Added `prev_psel_value` for same vs different slave detection
   - Implemented B2B flag setting logic
   - Added logging for B2B transactions

5. **sv/tb_top.sv**
   - No changes (kept as original)

6. **run.sh**
   - Converted to executable bash script
   - Added test name parameter support
   - Added coverage enable option
   - Complete compilation flow for all VIP components

7. **README.md**
   - Updated with formal verification and coverage documentation
   - Directory structure overview
   - Quick start guides
   - Coverage goals table
   - Verification flow diagram

## Formal Properties Implemented

### Critical Properties (High Priority)

| Property | Check | Description |
|----------|-------|-------------|
| `prop_psel_onehot` | Invariant | Only one PSEL bit can be high |
| `prop_psel_no_deassert_access` | LTL | PSEL cannot go low during ACCESS |
| `prop_pready_timing_violation` | Bounded | PREADY within 32 cycles |
| `prop_prdata_valid_on_read` | LTL | PRDATA not X when PREADY high on read |
| `prop_no_psel_overlap` | LTL | No mid-ACCESS PSEL deassertion |

### Additional Properties

| Property | Check | Description |
|----------|-------|-------------|
| `prop_psel_stable_setup` | LTL | PSEL stable during SETUP phase |
| `prop_psel_stable_access` | LTL | PSEL stable during ACCESS phase |
| `prop_psel_before_penable` | LTL | PSEL must be high before PENABLE |
| `prop_penable_setup` | LTL | PENABLE setup constraint |
| `prop_penable_low_setup` | LTL | PENABLE low during SETUP |
| `prop_pready_completion` | LTL | PREADY eventually asserted |
| `prop_pready_valid` | Invariant | PREADY only when valid access |
| `prop_pslverr_valid_timing` | Invariant | PSLVERR only during valid access |
| `prop_pslverr_stable` | LTL | PSLVERR stability during access |
| `prop_pwdata_stable_during_access` | LTL | PWDATA stable during ACCESS |
| `prop_pstrb_stable_during_access` | LTL | PSTRB stable during ACCESS |
| `prop_pstrb_width` | Invariant | PSTRB within 2 bits |
| `prop_paddr_stable_during_access` | LTL | PADDR stable during ACCESS |

## Coverage Groups Implemented

### Master Coverage (`master_cg`)

**Coverpoints:**
- `cp_wait_states`: normal, wait_1, wait_2, wait_3_plus
- `cp_direction`: write, read
- `cp_is_b2b`: yes, no
- `cp_psel_index`: s0, s1
- `cp_addr`: low_range, medium_range, high_range
- `cp_data`: zeroes, ones, others
- `cp_strbs`: one, two, three

**Cross Coverage:**
- `waitXdir`: wait_states × direction
- `waitXB2B`: wait_states × is_b2b
- `waitXpsel`: wait_states × psel_index
- `b2bXpsel`: is_b2b × psel_index
- `addrXdir`: addr × direction
- `waitXdata`: wait_states × data
- `full_txn`: Complete transaction pattern

### Slave Coverage (`slave_cg`)

**Coverpoints:**
- `cp_response_time`: same_cycle, delayed_1, delayed_2, delayed_plus
- `cp_error`: no_error, error
- `cp_psel_index`: s0, s1
- `cp_txn_type`: write, read

**Cross Coverage:**
- `responseXerror`: response_time × error
- `responseXpsel`: response_time × psel_index
- `errorXpsel`: error × psel_index
- `responseXtxn`: response_time × txn_type
- `full_response`: Complete response pattern

### Transaction Coverage (`txn_cg`)

**Coverpoints:**
- `cp_b2b_same_slave`: yes_same, no
- `cp_prev_psel`: s0, s1

**Cross Coverage:**
- `b2bXpsel_analysis`: B2B × PSEL for same/different slave detection

## B2B Detection Implementation

### Monitor State Tracking

```systemverilog
// In apb_bus_monitor.sv
bit last_transaction_completed;
bit prev_psel_active;
bit [1:0] prev_psel_value;
```

### Detection Logic

```systemverilog
if (last_transaction_completed && prev_psel_active) begin
    trans.is_b2b = 1;
    
    if (prev_psel_value == trans.psel) begin
        // Same slave B2B
    end else begin
        // Different slave B2B
    end
end
```

### Coverage Tracking

- `is_b2b` flag on `apb_item`
- `active_psel` field for PSEL index
- Cross-coverage for same vs different slave B2B

## Coverage Goals

| Coverage Type | Target | Priority |
|---------------|--------|----------|
| Master functional | 80% | High |
| Slave functional | 80% | High |
| Transaction functional | 70% | Medium |
| Line coverage (VIP) | 70% | Medium |
| Branch coverage (VIP) | 60% | Low |

## Usage

### Formal Verification

```bash
cd formal
make verify          # Run all properties
make prop-check      # Property-by-property
fmutil check --property prop_name -t apb_interface apb_formal.sv
```

### Simulation

```bash
./run.sh apb_wr_test        # Run write test
./run.sh random_apb_test    # Run random test
./run.sh apb_ral_test on    # Run with coverage
```

### EDA Playground

1. Open `sv/eda_playground.sv`
2. Add `COVERAGE` define
3. Run with Xcellium

## Key Features

1. **Protocol Compliance**: 19 formal properties verify APB protocol
2. **B2B Detection**: Automatic detection and classification
3. **Wait State Coverage**: 0-5 wait states covered
4. **Error Coverage**: PSLVERR conditions tracked
5. **PSEL Index Coverage**: All slaves tracked separately
6. **Comprehensive Crosses**: Full transaction pattern coverage

## Verification Flow

```
┌─────────────────────┐
│  Formal Properties  │
│  (SymbiYosys)       │
│  - PSEL protocol    │
│  - PREADY timing    │
│  - Data stability   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Functional         │
│  Coverage           │
│  (Xcellium/EDA)     │
│  - Transaction      │
│  - B2B patterns     │
│  - Wait states      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Code Coverage      │
│  (Xcellium/EDA)     │
│  - VIP implementation│
│  - Test coverage    │
└─────────────────────┘
```

## Testing Recommendations

1. **Run All Formal Properties**: Verify protocol compliance
2. **Execute Multiple Tests**: Different coverage areas
3. **Check Coverage Reports**: Identify gaps
4. **Analyze Missed Bins**: Add targeted tests
5. **Verify B2B Detection**: Confirm monitor accuracy

## Next Steps

1. Run formal verification with SymbiYosys
2. Execute coverage tests on EDA Playground
3. Analyze coverage reports
4. Address any coverage gaps
5. Document any property violations (if found)

## References

- **formal/README.md** - Formal verification guide
- **COVERAGE_GUIDE.md** - Coverage testing guide
- **sv/apb_bus_monitor.sv:52-90** - B2B detection implementation
- **sv/apb_coverage.sv** - Coverage group definitions
- **formal/apb_formal.sv** - Formal properties

## Author

Josh Rendon - APB UVC Formal Verification and Coverage Implementation