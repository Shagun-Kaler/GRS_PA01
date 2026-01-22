//Program B: Multi-threaded implementation using pthread
 //Creates N threads, each executing a specified worker function
 //Usage: ./program_b <worker_type> <num_threads>
 

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include "MT25190_Part_B_workers.h"

//passes argument to each thread
typedef struct {
    int thread_id;
    void (*worker_func)(void);
} thread_arg_t;

void *thread_worker(void *arg) {
    thread_arg_t *targ = (thread_arg_t *)arg;
    printf("Thread %d (TID: %lu) starting worker\n", targ->thread_id, pthread_self());
    targ->worker_func();     //execute assigned worker function
    printf("Thread %d (TID: %lu) completed\n", targ->thread_id, pthread_self());
    return NULL;
}

void usage(const char *prog_name) {
    fprintf(stderr, "Usage: %s <worker_type> <num_threads>\n", prog_name);
    fprintf(stderr, "  worker_type: cpu, mem, or io\n");
    fprintf(stderr, "  num_threads: number of threads (e.g., 2)\n");
    exit(1);
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        usage(argv[0]);
    }
    
    const char *worker_type = argv[1];        //read worker type(cpu/mem/io)
    int num_threads = atoi(argv[2]);         //number of threads is converted to string
    
    if (num_threads <= 0 || num_threads > 100) {
        fprintf(stderr, "Error: Invalid number of threads\n");
        usage(argv[0]);
    }
    
    // Function pointer to determine which worker function to use
    void (*worker_func)(void) = NULL;
    
    //select worker function based on worker_type
    if (strcmp(worker_type, "cpu") == 0) {
        worker_func = worker_cpu;
    } else if (strcmp(worker_type, "mem") == 0) {
        worker_func = worker_mem;
    } else if (strcmp(worker_type, "io") == 0) {
        worker_func = worker_io;
    } else {
        fprintf(stderr, "Error: Invalid worker type '%s'\n", worker_type);
        usage(argv[0]);
    }
    
    printf("Program B: Creating %d threads with worker '%s'\n", 
           num_threads, worker_type);
    
    pthread_t *threads = malloc(num_threads * sizeof(pthread_t));   //allocate memory for thread dynamically
    thread_arg_t *args = malloc(num_threads * sizeof(thread_arg_t));
    
    if (threads == NULL || args == NULL) {
        fprintf(stderr, "Error: Memory allocation failed\n");
        exit(1);
    }
    
    // Create threads
    for (int i = 0; i < num_threads; i++) {
        args[i].thread_id = i;
        args[i].worker_func = worker_func;
        
        int ret = pthread_create(&threads[i], NULL, thread_worker, &args[i]);
        if (ret != 0) {
            fprintf(stderr, "Error: pthread_create failed for thread %d\n", i);
            exit(1);
        }
    }
    
    // Wait for all threads to complete
    for (int i = 0; i < num_threads; i++) {
        pthread_join(threads[i], NULL);
    }
    
    printf("All threads completed\n");
    
    free(threads);
    free(args);
    
    return 0;
}
