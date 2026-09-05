# all module files
DESIGN = mod_counter.sv time_keeper.sv
TB = tb_time_keeper.sv # TUNE ME

VVP_FILE = sim.vvp
VCD_FILE = tb_time_keeper.vcd

# Default 
all: compile run wave

compile:
	iverilog -g2012 -o $(VVP_FILE) $(DESIGN) $(TB)

run:
	vvp $(VVP_FILE)

wave:
	surfer $(VCD_FILE)

clean:
	rm -f $(VVP_FILE) *.vcd