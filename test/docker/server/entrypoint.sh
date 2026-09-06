#!/usr/bin/env bash
set -e

echo "[Target] Starting dummy services (allowed: 80/443, disallowed: 3306/8080)..."
python3 -m http.server 80 &
python3 -m http.server 443 &
python3 -m http.server 3306 &
python3 -m http.server 8080 &

echo "[Target] Starting real sshd (SSH management port + protected-process fixture)..."
mkdir -p /run/sshd
/usr/sbin/sshd

if command -v roamswitch >/dev/null 2>&1; then
    echo "[Target] Initializing FIM baseline..."
    roamswitch fim update --quiet || true
fi

# The roamswitch-server-daemon itself is deliberately NOT started here — the
# egress-guard test needs the attacker/C2 containers' real IPs baked into the
# malicious-IP feed first, and those are only known once every container is
# up (this suite runs on the default "bridge" network with dynamically
# assigned addresses). run.sh starts the daemon itself via `docker exec -d`
# right after seeding the feed.
echo "[Target] Ready — waiting for the daemon to be started externally."
exec tail -f /dev/null
