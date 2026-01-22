#include "MT25190_Part_B_workers.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>

// ============================================================================
// CPU-INTENSIVE WORKER FUNCTIONS
// ============================================================================

// Helper Function: Prime number computation using trial division
// Returns 1 if prime, 0 if not prime
static int is_number_prime(long num) {
    if (num < 2) return 0;
    
    // check divisibility up to sqrt(num)
    long limit = (long)sqrt((double)num);
    for (long divisor = 2; divisor <= limit; divisor++) {
        if (num % divisor == 0) {
            return 0;  // Not prime
        }
    }
    return 1;  // Prime
}

//CPU-intensive worker function
void worker_cpu(void) {
    volatile long prime_count = 0;  // volatile prevents compiler optimization
    
    // Start from a large number to ensure sufficient computation time
    // Each iteration checks a range of numbers for primality
    const long START_NUMBER = 1000000;
    const long RANGE_PER_ITERATION = 5000;
    
    for (long iter = 0; iter < LOOP_COUNT; iter++) {
        long start = START_NUMBER + (iter * RANGE_PER_ITERATION);
        long end = start + RANGE_PER_ITERATION;
        
        // Check each number in range for primality
        for (long num = start; num < end; num++) {
            if (is_number_prime(num)) {
                prime_count++;
            }
        }
    }
    
    // Use prime_count to prevent dead code elimination
    // This ensures the computation actually executes
    if (prime_count == 0) {
        prime_count = 1;
    }
}

// ============================================================================
// MEMORY-INTENSIVE WORKER FUNCTIONS
// ============================================================================

// Helper function: Processes a single buffer with memory-intensive operations
// Returns sum to prevent compiler optimization
static long process_buffer(char *buffer, size_t size, int pass_count) {
    long sum = 0;
   
    // Multiple passes through the buffer for memory-intensive work
    for (int pass = 0; pass < pass_count; pass++) {
        for (size_t j = 0; j < size; j += 64) {
            sum += buffer[j];
        }
    }
   
    return sum;
}

// Main memory-intensive worker function
// Allocates, fills, and processes large memory buffers repeatedly
void worker_mem(void) {
    const size_t ARRAY_SIZE = 10 * 1024 * 1024; // 10MB per array
    const int NUM_BUFFERS = 20; // Keep multiple buffers allocated
    const int PASS_COUNT = 5; // No of memory passes per buffer
   
    // Allocate array of buffer pointers to keep memory allocated
    char **buffers = (char **)malloc(NUM_BUFFERS * sizeof(char *));
    if (buffers == NULL) return;
   
    // Initialize all buffer pointers to NULL
    for (int i = 0; i < NUM_BUFFERS; i++) {
        buffers[i] = NULL;
    }
   
    for (long i = 0; i < LOOP_COUNT; i++) {
        // Allocate large chunks of memory in rotating fashion
        int buf_idx = i % NUM_BUFFERS;
       
        // Free old buffer if exists
        if (i >= NUM_BUFFERS && buffers[buf_idx] != NULL) {
            free(buffers[buf_idx]);
        }
       
        // Allocate new buffer
        buffers[buf_idx] = (char *)malloc(ARRAY_SIZE);
        if (buffers[buf_idx] == NULL) {
            continue;
        }
       
        // Fill buffer with data
        memset(buffers[buf_idx], (i % 256), ARRAY_SIZE);
       
        // Perform memory-intensive operations on the buffer
        long sum = process_buffer(buffers[buf_idx], ARRAY_SIZE, PASS_COUNT);
       
        // Use sum to prevent optimization
        if (sum == 0) {
            buffers[buf_idx][0] = 1;
        }
    }
   
    // Cleanup all buffers
    for (int i = 0; i < NUM_BUFFERS; i++) {
        if (buffers[i] != NULL) {
            free(buffers[i]);
        }
    }
    free(buffers);
}


// ============================================================================
// I/O-INTENSIVE WORKER FUNCTIONS
// ============================================================================

// Helper function: Performs write operations to a file, writes buffer to file multiple times
// Returns 0 on success, -1 on failure
static int write_to_file(int fd, char *buffer, size_t buffer_size, int write_count) {
    for (int w = 0; w < write_count; w++) {
        ssize_t bytes_written = write(fd, buffer, buffer_size);
        if (bytes_written == -1) {
            return -1;
        }
    }
    return 0;
}

// Helper function: Performs read operations from a file, reads buffer from file multiple times
// Returns 0 on success, -1 on failure
static int read_from_file(int fd, char *buffer, size_t buffer_size, int read_count) {
    for (int r = 0; r < read_count; r++) {
        lseek(fd, 0, SEEK_SET); // Reset to beginning
        ssize_t bytes_read = read(fd, buffer, buffer_size);
        if (bytes_read == -1) {
            return -1;
        }
    }
    return 0;
}

// Main I/O-intensive worker function
// Performs repeated file write and read operations
void worker_io(void) {
    const size_t BUFFER_SIZE = 1024 * 1024; // 1MB per write
    const int WRITES_PER_ITERATION = 10;
    const int READS_PER_ITERATION = 5;
    const int SYNC_INTERVAL = 100; // Sync every N iterations
   
    char filename[256];
   
    // Create unique filename based on process/thread ID
    snprintf(filename, sizeof(filename), "/tmp/worker_io_%d.tmp", getpid());
   
    // Allocate buffer once outside loop
    char *buffer = (char *)malloc(BUFFER_SIZE);
    if (buffer == NULL) return;
   
    for (long i = 0; i < LOOP_COUNT; i++) {
        // === WRITE OPERATION ===
        int fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd == -1) {
            continue;
        }
       
        // Fill buffer with data
        memset(buffer, 'A' + (i % 26), BUFFER_SIZE);
       
        // Write multiple times per iteration
        write_to_file(fd, buffer, BUFFER_SIZE, WRITES_PER_ITERATION);
       
        // Sync periodically to ensure disk writes
        if (i % SYNC_INTERVAL == 0) {
            fsync(fd);
        }
       
        close(fd);
       
        // === READ OPERATION ===
        fd = open(filename, O_RDONLY);
        if (fd != -1) {
            // Read multiple times
            read_from_file(fd, buffer, BUFFER_SIZE, READS_PER_ITERATION);
            close(fd);
        }
    }
   
    free(buffer);
   
    // Cleanup temporary file
    unlink(filename);
}