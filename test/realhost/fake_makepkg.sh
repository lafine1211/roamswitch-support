#!/bin/bash
# stand-in for a build script whose comm is "makepkg": many compressed-looking outputs from one bash process
for i in $(seq 1 40); do head -c 65536 /dev/urandom > "$D/out$i.bin"; done
