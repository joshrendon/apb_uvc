# apb_uvc
UVM APB UVC with Coverage and Formal Verification

## Overview

Complete UVM-based APB Verification IP (VIP) with:
- **UVM Testbench**: Master/slave agents, scoreboard, RAL model
- **Functional Coverage**: Transaction patterns, B2B sequences, wait states
- **Code Coverage**: Line, branch, and condition coverage
- **Formal Verification**: SymbiYosys properties for protocol compliance

![apb_wave](documentation/apb_wr_then_rd_waves.png)

## Directory Structure

```
├── formal/                   # Formal verification (SymbiYosys)
│   ├── apb_formal.sv         # SVA properties
│   ├── Makefile              # Build and verify commands
│   └── README.md             # Formal verification guide
│
├── sv/                       # UVM SystemVerilog files
│   ├── apb_interface.sv      # APB interface with SVA includes
│   ├── apb_coverage.sv       # Functional coverage groups
│   ├── apb_bus_monitor.sv    # B2B detection & coverage collector
│   ├── apb_item.sv           # Transaction model (with is_b2b flag)
│   ├── tb_top.sv             # Original testbench
│   └── eda_playground.sv     # Coverage testbench for EDA Playground
│
├── rtl/                      # DUT and top-level RTL
│   ├── top.sv                # Testbench top with FPGA I/O
│   └── apb_slave_dut.sv      # APB slave DUT with registers
│
├── doc/                      # Waveforms and documentation
│
├── run.sh                    # Quick simulation script
└── README.md                 # This file
```

## Tests

| Test | Purpose | Coverage Focus |
|------|---------|----------------|
| `apb_wr_test` | Write then read | Basic transactions |
| `random_apb_test` | Random transactions | Coverage diversity |
| `apb_interleaved_test_seq` | Interleaved accesses | B2B patterns |
| `apb_reg_test_seq` | Register accesses | CSR space |
| `apb_ral_test_seq` | RAL model test | Full verification |

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
┌──────────────────────┐
│  Code Coverage       │
│  (Vivado/EDA)        │
│  - VIP implementation│
│  - Test coverage     │
└──────────────────────┘
```

## References

- [SymbiYosys Documentation](https://yosyshq.net/symbiyosys/)
- [APB Protocol Specification](https://developer.arm.com/documentation/ihi0022/latest/)
- [EDA Playground](https://www.edaplayground.com/)
