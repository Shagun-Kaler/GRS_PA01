#ifndef WORKERS_H
#define WORKERS_H

#define LOOP_COUNT 9000

// CPU-intensive worker: performs complex mathematical calculations
void worker_cpu(void);

// Memory-intensive worker: performs large memory operations
void worker_mem(void);

// I/O-intensive worker: performs file read/write operations
void worker_io(void);

#endif // WORKERS_H
