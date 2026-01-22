# Makefile for PA01
# Compiles Program A (processes) and Program B (threads)
#automates the exectution of part C and part D along with plot generation
# generates plots for part D

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c11
LDFLAGS = -pthread -lm

# Source files
WORKERS_SRC = MT25190_Part_B_workers.c
PROGRAM_A_SRC = MT25190_Part_A_Program_A.c
PROGRAM_B_SRC = MT25190_Part_A_Program_B.c

# Object files
WORKERS_OBJ = $(WORKERS_SRC:.c=.o)
PROGRAM_A_OBJ = $(PROGRAM_A_SRC:.c=.o)
PROGRAM_B_OBJ = $(PROGRAM_B_SRC:.c=.o)

# Executables
PROGRAM_A = program_a
PROGRAM_B = program_b

.PHONY: all clean run test help

all: $(PROGRAM_A) $(PROGRAM_B)

# Run all experiments automatically: Part C, Part D, and generate plots
run: all
	@echo "========================================"
	@echo "Running Full Automated Test Suite"
	@echo "========================================"
	@echo ""
	@echo "Step 1: Running Part C automation..."
	@chmod +x MT25190_Part_C_automation.sh
	@./MT25190_Part_C_automation.sh
	@echo ""
	@echo "Step 2: Running Part D automation..."
	@chmod +x MT25190_Part_D_automation.sh
	@./MT25190_Part_D_automation.sh
	@echo ""
	@echo "Step 3: Generating plots..."
	@python3 MT25190_Part_D_plot.py
	@echo ""
	@echo "========================================"
	@echo "All tests completed successfully!"
	@echo "========================================"
	@echo "Results saved in:"
	@echo "  - data/MT25190_Part_C_CSV.csv"
	@echo "  - data/MT25190_Part_D_CSV.csv"
	@echo "  - plots_part_d/*.png"

# Alias for run
test: run

# Build Program A (fork-based)
$(PROGRAM_A): $(WORKERS_OBJ) $(PROGRAM_A_OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# Build Program B (pthread-based)
$(PROGRAM_B): $(WORKERS_OBJ) $(PROGRAM_B_OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# Compile object files
%.o: %.c MT25190_Part_B_workers.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(PROGRAM_A) $(PROGRAM_B) *.o
	rm -f /tmp/worker_io_*.tmp
	rm -rf data/*.csv plots_part_d/*.png

help:
	@echo "MT25190 PA01 - Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make          : Build all programs"
	@echo "  make run      : Build and run all experiments (Part C, Part D, plots)"
	@echo "  make test     : Same as 'make run'"
	@echo "  make clean    : Remove all compiled binaries and temporary files"
	@echo "  make help     : Display this help message"
	@echo ""
	@echo "Executables:"
	@echo "  program_a     : Multi-process version using fork()"
	@echo "  program_b     : Multi-threaded version using pthread"
	@echo ""
	@echo "Example:"
	@echo "  ./program_a cpu 2    # Run Program A with CPU worker and 2 processes"
	@echo "  ./program_b mem 4    # Run Program B with MEM worker and 4 threads"
