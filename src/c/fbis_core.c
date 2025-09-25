#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

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
