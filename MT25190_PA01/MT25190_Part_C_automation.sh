#!/bin/bash

# MT25190 Part C Automation Script
# Runs all 6 program+worker combinations and collects metrics
# Usage: ./MT25190_Part_C_automation.sh

set -e

# Configuration
ROLL_NUM="MT25190"
CSV_FILE="data/${ROLL_NUM}_Part_C_CSV.csv"
PROGRAM_A="./program_a"
PROGRAM_B="./program_b"
NUM_WORKERS=2
CPUSET="0,1"  # Pin to CPUs 0 and 1

# Check if programs exist
if [ ! -f "$PROGRAM_A" ] || [ ! -f "$PROGRAM_B" ]; then
    echo "Error: Programs not found. Run 'make' first."
    exit 1
fi

# Check if running on Linux with required tools
if ! command -v taskset &> /dev/null; then
    echo "Warning: taskset not found. CPU pinning will be skipped."
    USE_TASKSET=false
else
    USE_TASKSET=true
fi

if ! command -v iostat &> /dev/null; then
    echo "Warning: iostat not found. I/O statistics will be limited."
    USE_IOSTAT=false
else
    USE_IOSTAT=true
fi

# Create data directory
mkdir -p data

# Initialize CSV file
echo "Program+Function,CPU%,Mem(KB),IO(KB/s),Time(s)" > "$CSV_FILE"

# Function to measure program execution
measure_execution() {
    local program_name=$1
    local program_path=$2
    local worker_type=$3
    local num_workers=$4
    
    echo "========================================="
    echo "Running: $program_name + $worker_type"
    echo "========================================="
    
    local label="${program_name}+${worker_type}"
    
    # Temporary files for monitoring
    local time_file="/tmp/time_${program_name}_${worker_type}.txt"
    local monitor_file="/tmp/monitor_${program_name}_${worker_type}.txt"
    local io_file="/tmp/io_${program_name}_${worker_type}.txt"
    
    # Clear old monitoring data
    > "$monitor_file"
    > "$io_file"
    
    # Start iostat monitoring in background if available
    local iostat_pid=""
    if [ "$USE_IOSTAT" = true ]; then
        iostat -dxk 1 > "$io_file" 2>&1 &
        iostat_pid=$!
    fi
    
    # Get start time
    local start_time=$(date +%s.%N)
    
    # Run the program in background
    if [ "$USE_TASKSET" = true ]; then
        taskset -c $CPUSET $program_path $worker_type $num_workers &
        local prog_pid=$!
    else
        $program_path $worker_type $num_workers &
        local prog_pid=$!
    fi
    
    echo "Started program with PID: $prog_pid"
    
    # Wait a moment for the process to spawn children
    sleep 0.5
    
    # Monitor CPU and memory usage with faster sampling
    local max_cpu=0.0
    local total_cpu=0.0
    local max_mem=0
    local sample_count=0
    
    while kill -0 $prog_pid 2>/dev/null; do
        # Get all PIDs (parent + children)
        local all_pids="$prog_pid"
        local children=$(pgrep -P $prog_pid 2>/dev/null || echo "")
        if [ -n "$children" ]; then
            all_pids="$all_pids,$children"
        fi
        
        # Use top for more accurate CPU measurement (single snapshot)
        if command -v top &> /dev/null; then
            # Get CPU% for all processes in one top call
            local cpu_sum=0.0
            for pid in ${all_pids//,/ }; do
                if [ -d "/proc/$pid" ]; then
                    local cpu_val=$(top -b -n 1 -p $pid 2>/dev/null | tail -n 1 | awk '{print $9}' | tr -d '%')
                    if [ -n "$cpu_val" ] && [ "$cpu_val" != "CPU" ]; then
                        cpu_sum=$(echo "$cpu_sum + $cpu_val" | bc 2>/dev/null || echo "$cpu_sum")
                    fi
                fi
            done
            
            # Update max and average CPU
            if (( $(echo "$cpu_sum > $max_cpu" | bc -l 2>/dev/null || echo "0") )); then
                max_cpu=$cpu_sum
            fi
            total_cpu=$(echo "$total_cpu + $cpu_sum" | bc 2>/dev/null || echo "$total_cpu")
        fi
        
        # Get memory usage (RSS in KB) for all processes
        local mem_sum=0
        for pid in ${all_pids//,/ }; do
            if [ -d "/proc/$pid" ]; then
                local mem_val=$(ps -p $pid -o rss= 2>/dev/null | awk '{print $1}')
                if [ -n "$mem_val" ]; then
                    mem_sum=$((mem_sum + mem_val))
                fi
            fi
        done
        
        if [ $mem_sum -gt $max_mem ]; then
            max_mem=$mem_sum
        fi
        
        sample_count=$((sample_count + 1))
        
        # Sample every 1 second for better accuracy
        sleep 1
    done
    
    # Wait for program to complete
    wait $prog_pid 2>/dev/null || true
    
    # Stop iostat monitoring
    if [ -n "$iostat_pid" ]; then
        kill $iostat_pid 2>/dev/null || true
        wait $iostat_pid 2>/dev/null || true
    fi
    
    # Calculate end time
    local end_time=$(date +%s.%N)
    local exec_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0.0")
    
    # Calculate average CPU
    local avg_cpu=0.0
    if [ $sample_count -gt 0 ]; then
        avg_cpu=$(echo "scale=2; $total_cpu / $sample_count" | bc 2>/dev/null || echo "0.0")
    fi
    
    # Use max CPU (better indicator of actual usage)
    local final_cpu=$(printf "%.2f" "$max_cpu" 2>/dev/null || echo "0.0")
    
    # Extract I/O statistics (average kB/s read+write)
    local io_stat="0.0"
    if [ "$USE_IOSTAT" = true ] && [ -f "$io_file" ]; then
        # Extract read and write kB/s, calculate average
        io_stat=$(awk '/sd[a-z]|nvme/ {reads+=$6; writes+=$7; count++} END {if(count>0) print (reads+writes)/count; else print 0.0}' "$io_file" 2>/dev/null || echo "0.0")
        io_stat=$(printf "%.2f" "$io_stat" 2>/dev/null || echo "0.0")
    fi
    
    # Format execution time
    local exec_time_formatted
    if (( $(echo "$exec_time < 60" | bc -l) )); then
        exec_time_formatted=$(printf "%.3f" "$exec_time")
    else
        local minutes=$(echo "$exec_time / 60" | bc)
        local seconds=$(echo "$exec_time - ($minutes * 60)" | bc)
        exec_time_formatted="${minutes}m$(printf "%.3f" "$seconds")"
    fi
    
    echo "$label,$final_cpu,$max_mem,$io_stat,$exec_time_formatted" >> "$CSV_FILE"
    
    echo "Result: CPU=${final_cpu}% (avg=${avg_cpu}%), Mem=${max_mem}KB, IO=${io_stat}KB/s, Time=${exec_time_formatted}s"
    echo "Samples collected: $sample_count"
    echo ""
    
    # Cleanup
    rm -f "$time_file" "$monitor_file" "$io_file"
}

# Main execution
echo "MT25190 Part C: Automation Script"
echo "=================================="
echo ""
echo "Running all 6 combinations of Program + Worker Function"
echo "Using $NUM_WORKERS workers per run"
echo "CPU pinning: $CPUSET"
echo ""

# Run all combinations
measure_execution "A" "$PROGRAM_A" "cpu" "$NUM_WORKERS"
measure_execution "A" "$PROGRAM_A" "mem" "$NUM_WORKERS"
measure_execution "A" "$PROGRAM_A" "io" "$NUM_WORKERS"
measure_execution "B" "$PROGRAM_B" "cpu" "$NUM_WORKERS"
measure_execution "B" "$PROGRAM_B" "mem" "$NUM_WORKERS"
measure_execution "B" "$PROGRAM_B" "io" "$NUM_WORKERS"

echo "========================================="
echo "Part C: All measurements completed!"
echo "========================================="
echo "Results saved to: $CSV_FILE"
echo ""
echo "Summary:"
cat "$CSV_FILE"
