# SymbiYosys Formal Verification Makefile
# For APB Protocol Verification using Yosys + ABC + Z3
#
# Usage:
#   make verify     - Run all formal property checks
#   make clean      - Remove generated files
#   make prop-n     - Check specific property (n = 1, 2, 3...)

TOPLEVEL = apb_interface
MODULE = apb_formal

# Formal verification flags
SYNTH_FLAGS = -s yosys
FORMAL_BACKEND = --abc --z3

# Property check targets
PROP_TARGETS = \
    prop_psel_onehot \
    prop_psel_no_deassert_access \
    prop_psel_stable_setup \
    prop_psel_stable_access \
    prop_psel_before_penable \
    prop_penable_setup \
    prop_pready_timing_violation \
    prop_pready_completion \
    prop_pready_valid \
    prop_pslverr_valid_timing \
    prop_pwdata_stable_during_access \
    prop_prdata_valid_on_read \
    prop_no_psel_overlap

.PHONY: all clean verify prop-check

all: verify

verify: $(TOPLEVEL)_check
	@echo "=========================================="
	@echo "Formal Verification Complete"
	@echo "=========================================="

$(TOPLEVEL)_check:
	@echo "=========================================="
	@echo "Step 1: Synthesizing $(TOPLEVEL)"
	@echo "=========================================="
	yosys -p "synth -flatten -top $(TOPLEVEL); write_ilang synth.il" sv/apb_interface.sv sv/apb_defines.sv formal/apb_formal.sv
	@echo ""
	@echo "=========================================="
	@echo "Step 2: Running Formal Verification with ABC + Z3"
	@echo "=========================================="
	fmutil check --formal $(FORMAL_BACKEND) -t $(TOPLEVEL) formal/apb_formal.sv
	@echo ""
	@echo "=========================================="
	@echo "Step 3: Property-by-Property Analysis"
	@echo "=========================================="
	@for prop in $(PROP_TARGETS); do \
		echo "Checking $$prop..."; \
		fmutil check --formal --property $$prop $(FORMAL_BACKEND) -t $(TOPLEVEL) formal/apb_formal.sv || echo "FAILED: $$prop"; \
	done

prop-check:
	@echo "=========================================="
	@echo "Property-by-Property Verification"
	@echo "=========================================="
	@for prop in $(PROP_TARGETS); do \
		echo ""; \
		echo "==========================================" ;\
		echo "Checking: $$prop" ;\
		echo "==========================================" ;\
		fmutil check --formal --property $$prop $(FORMAL_BACKEND) -t $(TOPLEVEL) formal/apb_formal.sv && \
		echo "PASS: $$prop" || echo "FAIL: $$prop"; \
	done

clean:
	rm -f synth.il test.v
	rm -rf work
	rm -f coverage.*
	@echo "Cleaned formal verification artifacts"