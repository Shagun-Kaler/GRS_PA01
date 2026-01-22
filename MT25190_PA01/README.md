# MT25190 Programming Assignment 01
## Process vs Thread Performance Comparison

**Roll No:** MT25190  
**Course:** Graduate OS  
**Assignment:** PA01 - Comparing Processes and Threads

---

## Table of Contents
1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [Implementation](#implementation-details)
4. [Building the Code](#build-instructions)
5. [Usage](#usage)
6. [Running Tests](#running-experiments)
7. [What You Need](#dependencies)
8. [Important Notes](#notes)

---

## Overview

This assignment basically compares how processes (using fork) and threads (using pthread) perform differently in C. The project has:

- **Program A**: Uses multiple processes with `fork()`
- **Program B**: Uses multiple threads with `pthread`
- **Three Different Workers**:
  - `cpu`: Does heavy math calculations (prime numbers)
  - `mem`: Does alot of memory operations (allocating and copying big chunks)
  - `io`: Does file operations (reading/writing to disk)

We measure things like CPU usage, memory used, I/O speed, and how long each one takes to finish.

---

## Project Structure

```
MT25190_PA01/
├── MT25190_Part_A_Program_A.c        # Multi-process program (fork)
├── MT25190_Part_A_Program_B.c        # Multi-threaded program (pthread)
├── MT25190_Part_B_workers.c          # Worker function implementations
├── MT25190_Part_B_workers.h          # Worker function headers
├── MT25190_Part_C_automation.sh      # Part C automation script
├── MT25190_Part_D_automation.sh      # Part D automation script
├── MT25190_Part_D_plot.py            # Python plotting script
├── Makefile                          # Build automation
├── README.md                         # This file
├── program_a                         # Compiled Program A executable
├── program_b                         # Compiled Program B executable
├── data/                             # CSV output directory
│   ├── MT25190_Part_C_CSV.csv       # Part C results
│   └── MT25190_PART_D_CSV.csv       # Part D results
└── plots_part_d/                     # Generated plots directory
    ├── CPU%_vs_NumWorkers.png
    ├── Mem(KB)_vs_NumWorkers.png
    ├── Time(s)_vs_NumWorkers.png
    ├── context_switches_per_sec_vs_NumWorkers.png
    └── page_faults_total_vs_NumWorkers.png
```

---

## Implementation

### Worker Functions

All workers run for **9000 iterations** (since last digit of my roll no. is 0, so 9 × 1000).

#### 1. CPU Worker (`worker_cpu`)
- Checks if numbers are prime using trial division method
- Starts from 1,000,000 and checks 5000 numbers each iteration
- Pure CPU work - just doing calculations, no file or memory stuff
- This one really pushes the CPU hard

#### 2. Memory Worker (`worker_mem`)
- Creates 20 buffers, each is 10MB in size
- Keeps allocating and freeing memory in a rotating way
- Does multiple passes (5 times) through each buffer to stress memory
- Tests how fast the system can handle memory operations

#### 3. I/O Worker (`worker_io`)
- Makes temporary files in `/tmp/` folder (each process gets unique filename)
- Writes 1MB of data 10 times, then reads it back 5 times per iteration
- Uses `fsync()` every 100 iterations to make sure data actually goes to disk
- Mostly waiting for disk to finish, not much CPU usage
- Deletes temp files when done

### Program A (Processes)

- Creates N child processes using `fork()`
- Each process runs independently and does its own work
- Parent process waits for everyone to finish with `wait()`
- Each process has its own separate memory (can't see other process memory)

### Program B (Threads)

- Creates N threads using `pthread_create()`
- All threads share the same memory space
- Main thread waits using `pthread_join()` till everyone finishes
- Usually faster than processes because less overhead

---

## Building the Code

### What You Need
- GCC compiler (C11 or newer)
- Ubuntu Linux (tested on Ubuntu 24.04.3)
- pthread library (usually already there)
- math library

### Compiling

```bash
# Just build the programs
make

# This makes two programs:
#   - program_a (uses processes)
#   - program_b (uses threads)
```

### Running Everything Automatically (Recommended)

```bash
# Build programs and run all tests automatically
make run
# or
make test

# This will:
# 1. Build both programs
# 2. Run Part C tests (6 combinations)
# 3. Run Part D scaling tests
# 4. Generate all 5 plots automatically
```

No need to run scripts manually! Just use `make run` and everything happens automatically.

### Starting Fresh

```bash
# Delete all compiled stuff
make clean
```

---

## How to Run

### Basic Commands

```bash
# Program A (processes)
./program_a <worker_type> <num_processes>

# Program B (threads)
./program_b <worker_type> <num_threads>
```

### What to pass
- `worker_type`: can be `cpu`, `mem`, or `io`
- `num_processes` / `num_threads`: how many workers you want (any positive number)

### Some Examples

```bash
# Program A with CPU worker, 2 processes
./program_a cpu 2

# Program B with memory worker, 4 threads
./program_b mem 4

# Program A with IO worker, 3 processes
./program_a io 3
```

---

## Running Tests

### Automated Way (Easiest)

Just run this single command to do everything:

```bash
make run
```

This automatically runs Part C tests, Part D tests, and generates all plots. No manual steps needed!

### Manual Way (If you want more control)

#### Part C: Basic Testing

This runs all 6 combinations (2 programs × 3 worker types) with 2 workers each time:

```bash
# Make it executable first
chmod +x MT25190_Part_C_automation.sh

# Run it
./MT25190_Part_C_automation.sh
```

**What you get:**
- CSV file saved in `data/MT25190_Part_C_CSV.csv`
- Has these columns: Program+Function, CPU%, Mem(KB), IO(KB/s), Time(s)

#### Part D: Scaling Tests

This tests with different numbers of workers:
- **Program A**: tries with 2, 3, and 4 processes
- **Program B**: tries with 2, 4, 6, and 8 threads

```bash
# Make executable
chmod +x MT25190_Part_D_automation.sh

# Run the test
./MT25190_Part_D_automation.sh
```

**What you get:**
- CSV file in `data/MT25190_PART_D_CSV.csv`
- Columns include: Program, WorkerType, NumWorkers, CPU%, Mem(KB), Time(s), context_switches_per_sec, page_faults_total
- 5 plots saved in `plots_part_d/` folder

#### Making Plots Manually

If you ran scripts manually and plots didn't get created, just run:

```bash
python3 MT25190_Part_D_plot.py
```

This makes 5 graphs in `plots_part_d/` folder:
- `CPU%_vs_NumWorkers.png` - shows CPU usage vs number of workers
- `Mem(KB)_vs_NumWorkers.png` - shows memory usage
- `Time(s)_vs_NumWorkers.png` - shows how long it takes
- `context_switches_per_sec_vs_NumWorkers.png` - context switch rate
- `page_faults_total_vs_NumWorkers.png` - page faults

---

## What You Need

### For Building
- `gcc` compiler
- `make`
- `pthread` library (probably already installed)
- `libm` (math library, should be there)

### For Running on Ubuntu
- `top` or `ps` - to monitor processes
- `pidstat` - gets process stats (in `sysstat` package)
- `iostat` - for I/O stats (also in `sysstat`)
- `bc` - for calculations in bash scripts
- `taskset` - pins process to CPUs (optional, only for Part C)

All these were available on my Ubuntu 24.04.3 system after installing sysstat.

### For Graphs (optional)
- `python3` (3.6 or newer should work)
- `pandas`
- `matplotlib`

Installing python stuff:
```bash
pip3 install pandas matplotlib
```

Installing required tools on Ubuntu:
```bash
# This is what I ran on Ubuntu 24.04.3
sudo apt-get install sysstat bc

# For other distros like Fedora/RHEL
sudo yum install sysstat bc
```

---

## Important Notes

### Platform Info

- **Developed on:** Ubuntu 24.04.3 Linux
- **Tested on:** Ubuntu 24.04.3
- **Windows:** Won't work directly, you need WSL or a Linux VM
- **macOS:** Might work but some tools like `taskset` and `pidstat` aren't available

### Things to Keep in Mind

1. **Tested on Ubuntu:** This was developed and tested on Ubuntu 24.04.3, should work on other Linux distros too
2. **CPU Pinning:** The Part C script pins processes to specific CPUs using `taskset` so results are more consistent
3. **Background Stuff:** Close other programs when running tests otherwise results won't be accurate
4. **Disk Type:** SSD vs HDD makes a huge difference for the IO worker (SSD is way faster)
5. **System Load:** Your results will be different depending on your system specs and whats running
6. **Memory:** Need atleast 4GB RAM, specially for memory worker with multiple processes
7. **Overhead:** The monitoring scripts also use some resources so keep that in mind

### Common Problems

**Problem:** `pidstat: command not found`
- **Fix:** Install `sysstat` package. Without it you won't get context switches and page fault data in Part D.

**Problem:** `taskset: command not found` (only affects Part C)
- **Fix:** Script will still work but without CPU pinning. Results might vary more.

**Problem:** `iostat: command not found`
- **Fix:** Install `sysstat` or you won't get proper I/O measurements.

**Problem:** Can't write to `/tmp/` folder
- **Fix:** Check if `/tmp/` is writable. The IO worker needs to create temp files there.

**Problem:** Code won't compile
- **Fix:** Make sure GCC is installed with pthread and math libraries (`-lpthread -lm` flags).

**Problem:** Part D didn't make any plots
- **Fix:** Run `python3 MT25190_Part_D_plot.py` manually. Make sure you have pandas and matplotlib installed first.

---

## What to Expect

### Part C Results
- **CPU worker:** Should show high CPU usage, not much memory, barely any I/O
- **Memory worker:** Uses alot of memory (can go over 200MB), medium CPU, not much I/O
- **I/O worker:** Low CPU, low memory, but high I/O activity
- **Processes vs Threads:** Threads use less memory because they share memory space

### Part D Results
- **CPU tasks:** Should get faster as you add more workers, up to how many cores you have
- **Memory tasks:** Might not scale much because memory bandwidth is limited
- **I/O tasks:** Won't scale much, might even get slower with too many workers (disk bottleneck)
- **Threads vs Processes:** 
  - Threads usually have less overhead
  - Threads have fewer page faults (they share memory)
  - Processes are completely separate but use more memory
- **After a Point:** Adding more workers doesn't help much, sometimes makes it worse due to context switching

---
