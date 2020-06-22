
void none() {}

void main() { for(;;); }
void _start() { main(); _exit(0); }

#include <sys/types.h>

void _exit(int status) { for(;;); }
int kill(pid_t pid, int sig) { for(;;); }
pid_t getpid(void) { return 0; }
void *sbrk(intptr_t increment) { for(;;); }
