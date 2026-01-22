#!/bin/bash

# Benchmark script for Program A (multi-process) and Program B (multi-threaded)
# Saves all results to a single CSV file

# Configuration
WORKER_TYPES=("cpu" "mem" "io")
PROCESS_COUNTS=(2 3 4)           # For Program A
THREAD_COUNTS=(2 4 6 8)      # For Program B

# Output directory and CSV file
DATA_DIR="/home/shagun-kaler/Downloads/1/MT25190_PA01/data"
CSV_FILE="$DATA_DIR/MT25190_Part_D_CSV.csv"

# Create data directory if it doesn't exist
mkdir -p "$DATA_DIR"

# Initialize CSV file with headers
echo "Program,WorkerType,NumWorkers,CPU%,Mem(KB),Time(s),context_switches_per_sec,page_faults_total" > "$CSV_FILE"

echo "================================================"
echo "Started: PART D"
echo "================================================"

# Function to run program and collect metrics
run_benchmark() {
    local program_name=$1    # "program_a" or "program_b"
    local worker_type=$2     # "cpu", "mem", or "io"
    local num_workers=$3     # number of processes/threads
   
    echo ""
    echo "Running: $program_name with $worker_type worker, $num_workers workers"
   
    # Temporary files for metrics
    local temp_monitor="/tmp/monitor_$.txt"
    local temp_output="/tmp/output_$.txt"
    local temp_pidstat="/tmp/pidstat_$.txt"
    local temp_pidstat="/tmp/pidstat_io_$.txt"
   
    # Start pidstat monitoring for context switches and page faults in background
    pidstat -w -r 1 > "$temp_pidstat" 2>&1 &
    PIDSTAT_PID=$!

   
    # Start system monitoring in background
    (
        while true; do
            # Capture CPU, memory, and I/O stats
            top -b -n 1 -d 0.5 | grep -E "Cpu|MiB Mem"
            iostat -x 1 1 | awk '/avg-cpu/ {getline; print $4}'
            echo "---"
            sleep 0.5
        done
    ) > "$temp_monitor" 2>&1 &
    MONITOR_PID=$!
   
    # Run the program and measure execution time
    local start_time=$(date +%s.%N)
    ./"$program_name" "$worker_type" "$num_workers" > "$temp_output" 2>&1
    local end_time=$(date +%s.%N)
   
    # Stop monitoring
    kill $MONITOR_PID 2>/dev/null
    wait $MONITOR_PID 2>/dev/null
    kill $PIDSTAT_PID 2>/dev/null
    wait $PIDSTAT_PID 2>/dev/null

   
    # Give pidstat a moment to finish writing
    sleep 1
   
    # Calculate execution time
    local exec_time=$(echo "$end_time - $start_time" | bc)
    local exec_time_formatted=$(printf "%.2f" "$exec_time")
   
    # Extract metrics from monitoring data
    # Average CPU usage
    local avg_cpu=$(grep "Cpu(s)" "$temp_monitor" | \
                    awk '{print $2}' | \
                    sed 's/%us,//' | \
                    awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", sum/count; else print "0.00"}')
   
    # Maximum memory usage (in MB)
    local max_mem=$(grep "MiB Mem" "$temp_monitor" | \
                    awk '{print $8}' | \
                    sed 's/used,//' | \
                    awk 'BEGIN{max=0} {if($1>max) max=$1} END {printf "%.2f", max}')
   
    # Extract context switches per second from pidstat
    # pidstat output has cswch/s (voluntary) and nvcswch/s (non-voluntary) columns
    local context_switches=$(grep -v "^#" "$temp_pidstat" | \
                            grep -v "Linux" | grep -v "Average" | grep -v "^$" | \
                            awk '{if(NF>=8) {sum+=$8+$9}} END {if(NR>0) printf "%.2f", sum/NR; else print "0.00"}')
   
    # Extract total page faults from pidstat
    # pidstat -r shows minflt/s (minor faults) and majflt/s (major faults)
    local page_faults=$(grep -v "^#" "$temp_pidstat" | \
                       grep -v "Linux" | grep -v "Average" | grep -v "^$" | \
                       awk '{if(NF>=8) {sum+=$7+$8}} END {printf "%.0f", sum}')
   
    # Handle empty metrics
    [ -z "$avg_cpu" ] && avg_cpu="0.00"
    [ -z "$max_mem" ] && max_mem="0.00"
    [ -z "$context_switches" ] && context_switches="0.00"
    [ -z "$page_faults" ] && page_faults="0"
   
    # Append to CSV file
    echo "$program_name,$worker_type,$num_workers,$avg_cpu,$max_mem,$exec_time_formatted,$context_switches,$page_faults" >> "$CSV_FILE"
   
    echo "  -> Exec Time: ${exec_time_formatted}s, CPU: ${avg_cpu}%, Mem: ${max_mem}MB, CtxSw: ${context_switches}/s, PgFlt: ${page_faults}"
   
    # Cleanup temporary files
    rm -f "$temp_monitor" "$temp_output" "$temp_pidstat"


      # Brief pause between runs
    sleep 2
}

# Main execution
echo ""
echo "========================================"
echo "PROGRAM A: Multi-Process Benchmarks"
echo "========================================"

for worker in "${WORKER_TYPES[@]}"; do
    for proc_count in "${PROCESS_COUNTS[@]}"; do
        run_benchmark "program_a" "$worker" "$proc_count"
    done
done

echo ""
echo "========================================"
echo "PROGRAM B: Multi-Threaded Benchmarks"
echo "========================================"

for worker in "${WORKER_TYPES[@]}"; do
    for thread_count in "${THREAD_COUNTS[@]}"; do
        run_benchmark "program_b" "$worker" "$thread_count"
    done
done

echo ""
echo "================================================"
echo "Completed:"
echo "================================================"
echo "Results saved to: $CSV_FILE"
echo ""
echo "CSV Summary:"
echo "------------"
cat "$CSV_FILE"
echo ""
echo "Total records: $(( $(wc -l < "$CSV_FILE") - 1 ))"