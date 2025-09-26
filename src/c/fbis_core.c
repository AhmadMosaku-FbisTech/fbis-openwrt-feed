#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>

static volatile int running = 1;

void handle_sigint(int sig) {
    running = 0;
}

int main(int argc, char **argv) {
    signal(SIGINT, handle_sigint);
    signal(SIGTERM, handle_sigint);

    printf("[fbis_core] starting with dynamic SIM + VPN + twin hooks...\n");

    while (running) {
        // TODO: health monitoring, config parsing, watchdog
        sleep(5);
    }

    printf("[fbis_core] shutting down.\n");
    return 0;
}

int main(void) {
    printf("[FBIS-Core] Starting core\n");

    // run carrier check at boot
    system("/etc/fbis/carrier_check.sh");

    // bring up vpn
    system("/etc/fbis/vpn_setup.sh");

    // start sync daemon (spawned separately by init script too, but safe)
    // note: init script runs fbisd.py; this keeps process alive for legacy
    while (1) {
        sleep(300);
    }

    return 0;
}
