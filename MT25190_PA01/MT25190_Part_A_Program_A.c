//Program A: Multi-process implementation using fork()
//Creates Nchild processes, each executinng specified function
//Usage: ./program_a <worker_type> <num_processes>


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include "MT25190_Part_B_workers.h"

void usage(const char *prog_name) {
    fprintf(stderr, "Usage: %s <worker_type> <num_processes>\n", prog_name);
    fprintf(stderr, "  worker_type: cpu, mem, or io\n");
    fprintf(stderr, "  num_processes: number of child processes in this case 2\n");
    exit(1);
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        usage(argv[0]);
    }
    
    const char *worker_type = argv[1];        //read worker type(cpu/mem/io)
    int num_processes = atoi(argv[2]);         //number of process is converted to string
    
    if (num_processes <= 0 || num_processes > 100) {                  
        fprintf(stderr, "Error: Invalid number of processes\n");
        usage(argv[0]);
    }
    
    // Determine which worker function to use
    void (*worker_func)(void) = NULL;
    
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
    
    printf("Program A: Creating %d child processes with worker '%s'\n", 
           num_processes, worker_type);
    
    // Create child processes using fork()
    for (int i = 0; i < num_processes; i++) {
        pid_t pid = fork();   //create new process
        
        if (pid < 0) {
            perror("fork failed");
            exit(1);
        } else if (pid == 0) {
            // Child process
            printf("Child process %d (PID: %d) starting worker\n", i, getpid());
            worker_func();    
            printf("Child process %d (PID: %d) completed\n", i, getpid());
            exit(0);
        }
        // Parent continues to create more children
    }
    
    // Parent waits for all children to complete
    for (int i = 0; i < num_processes; i++) {
        int status;
        pid_t child_pid = wait(&status);      //wait for any child to finish
        if (child_pid > 0) {
            printf("Child PID %d finished with status %d\n", child_pid, WEXITSTATUS(status));
        }
    }
    
    printf("All child processes completed\n");
    return 0;
}
