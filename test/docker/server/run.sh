#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

PASS=0
FAIL=0
pass() { echo -e "     \x1b[32m[PASS]\x1b[0m $1"; PASS=$((PASS+1)); }
fail() { echo -e "     \x1b[31m[FAIL]\x1b[0m $1"; FAIL=$((FAIL+1)); }

echo "========================================================"
echo "🛡️  RoamSwitch Server Edition — Docker Self-Check Suite"
echo "========================================================"

TARGET_IMG="rs-pentest-server-target-img"
ATTACKER_IMG="rs-pentest-server-attacker-img"
TARGET_CONT="rs-pentest-server-target"
ATTACKER_CONT="rs-pentest-server-attacker"
C2_CONT="rs-pentest-server-c2"

# Retries a reachability check a few times before trusting a single result.
# A fresh container pair's bridge port has been observed to occasionally
# drop one-off probes for a few seconds on real hosts, unrelated to any
# RoamSwitch rule (confirmed independently with tcpdump — packets left the
# sender but never arrived — and by hand-repeating a lone failure 5/5
# successfully right after with nothing else changed). A real Default-Deny
# or Air-Gap leak fails this retry consistently, not just once.
curl_reachable() { # host port
    local i
    for i in 1 2 3; do
        if docker exec "$ATTACKER_CONT" curl -s -m 2 "http://$1:$2/" >/dev/null 2>&1; then return 0; fi
        sleep 1
    done
    return 1
}
tcp_reachable() { # host port
    local i
    for i in 1 2 3; do
        if docker exec "$ATTACKER_CONT" bash -c "timeout 2 bash -c '</dev/tcp/$1/$2'" 2>/dev/null; then return 0; fi
        sleep 1
    done
    return 1
}

echo "[1/7] Cleaning up existing containers..."
docker rm -f "$TARGET_CONT" "$ATTACKER_CONT" "$C2_CONT" 2>/dev/null || true

echo "[2/7] Building Docker images..."
docker build -q -t "$TARGET_IMG" -f Dockerfile.target . >/dev/null
docker build -q -t "$ATTACKER_IMG" -f Dockerfile.attacker . >/dev/null

recreate_pentest_containers() {
    docker rm -f "$TARGET_CONT" "$ATTACKER_CONT" >/dev/null 2>&1 || true
    docker run -d --name "$TARGET_CONT" --cap-add=NET_ADMIN --cap-add=NET_RAW "$TARGET_IMG" >/dev/null
    docker run -d --name "$ATTACKER_CONT" "$ATTACKER_IMG" >/dev/null
    docker exec -d "$ATTACKER_CONT" python3 -m http.server 8000
    sleep 2
}

# Verifies the Docker bridge itself can actually deliver a packet between the
# two containers before any RoamSwitch firewall rule exists to blame if it
# can't. See README.md for why --privileged and a custom `docker network
# create` network are both deliberately avoided here.
wait_for_bridge_or_recreate() {
    local target_cont="$1" attacker_cont="$2" ip_var="$3" attempt
    for attempt in 1 2; do
        local ip ok=""
        ip=$(docker inspect -f '{{.NetworkSettings.Networks.bridge.IPAddress}}' "$target_cont")
        for i in $(seq 1 8); do
            if docker exec "$attacker_cont" curl -s -m 1 -o /dev/null "http://$ip:80/" 2>/dev/null; then ok=1; break; fi
            sleep 1
        done
        if [ -n "$ok" ]; then eval "$ip_var=$ip"; return 0; fi
        echo "  ⚠️  Docker bridge did not deliver a single packet between the containers after 8s (attempt $attempt/2)."
        if [ "$attempt" -eq 2 ]; then
            echo "  This is a host-level Docker/bridge networking quirk, not a RoamSwitch firewall behaviour — see README.md."
            return 1
        fi
        echo "  Recreating both containers to get a fresh bridge port..."
        recreate_pentest_containers
    done
}

echo "[3/7] Launching Target container ($TARGET_CONT)..."
docker run -d --name "$TARGET_CONT" --cap-add=NET_ADMIN --cap-add=NET_RAW "$TARGET_IMG" >/dev/null

echo "[4/7] Launching Attacker ($ATTACKER_CONT) and C2 decoy ($C2_CONT)..."
docker run -d --name "$ATTACKER_CONT" "$ATTACKER_IMG" >/dev/null
docker exec -d "$ATTACKER_CONT" python3 -m http.server 8000
docker run -d --name "$C2_CONT" "$ATTACKER_IMG" >/dev/null
docker exec -d "$C2_CONT" python3 -m http.server 8000
sleep 2

echo "[5/7] Verifying the Docker bridge actually delivers packets between the containers..."
if ! wait_for_bridge_or_recreate "$TARGET_CONT" "$ATTACKER_CONT" TARGET_IP; then
    echo "ABORTING: cannot proceed without basic container-to-container connectivity."
    docker rm -f "$TARGET_CONT" "$ATTACKER_CONT" "$C2_CONT" 2>/dev/null || true
    exit 1
fi
ATTACKER_IP=$(docker inspect -f '{{.NetworkSettings.Networks.bridge.IPAddress}}' "$ATTACKER_CONT")
C2_IP=$(docker inspect -f '{{.NetworkSettings.Networks.bridge.IPAddress}}' "$C2_CONT")
echo "  Target:   $TARGET_IP"
echo "  Attacker: $ATTACKER_IP"
echo "  C2 decoy: $C2_IP"

echo "[6/7] Seeding the egress-guard malicious-IP feed with the C2 decoy's address (NOT the attacker's)..."
docker exec "$TARGET_CONT" bash -c "echo '${C2_IP}/32' > /var/lib/roamswitch/threatfeed/malicious_ips.txt"

echo "[7/7] Starting roamswitch-server-daemon..."
docker exec -d "$TARGET_CONT" bash -c "stdbuf -oL -eL /usr/lib/roamswitch/roamswitch-server-daemon > /var/log/roamswitch-server.log 2>&1"
sleep 5
log() { docker exec "$TARGET_CONT" cat /var/log/roamswitch-server.log 2>/dev/null || true; }

echo ""
echo "[BOOT] daemon startup log excerpt:"
log | grep -E "Starting RoamSwitch|Applying Default-Deny|Loaded eBPF guard policy|egress guard|eBPF Runtime Guard event listener armed" || echo "  (no matching startup lines yet)"

echo ""
echo "========================================================"
echo "⚡ External: attacker -> target"
echo "========================================================"

echo "[TEST 1] Nmap SYN scan..."
docker exec "$ATTACKER_CONT" nmap -sS -p 22,80,443,3306,8080 --open "$TARGET_IP" -n || true

echo ""
echo "[TEST 2] Default-Deny: allowed vs. disallowed ports..."
if curl_reachable "$TARGET_IP" 80; then pass "Allowed port 80 responded."; else fail "Port 80 did not respond."; fi
if docker exec "$ATTACKER_CONT" curl -s -m 2 "http://$TARGET_IP:3306/" >/dev/null; then fail "Disallowed port 3306 was reachable!"; else pass "Disallowed port 3306 was dropped."; fi
if docker exec "$ATTACKER_CONT" curl -s -m 2 "http://$TARGET_IP:8080/" >/dev/null; then fail "Disallowed port 8080 was reachable!"; else pass "Disallowed port 8080 was dropped."; fi

echo ""
echo "[TEST 3] Egress / C2 blocklist: target -> C2 decoy is blocked, target -> attacker still works..."
if docker exec "$TARGET_CONT" curl -s -m 2 "http://$C2_IP:8000/" >/dev/null; then fail "Target reached the pre-seeded malicious IP!"; else pass "Egress guard blocked the malicious-IP connection."; fi
if docker exec "$TARGET_CONT" curl -s -m 2 "http://$ATTACKER_IP:8000/" >/dev/null; then pass "Target can still reach a non-blocklisted host."; else fail "Target could not reach a non-blocklisted host — over-blocking!"; fi

echo ""
echo "========================================================"
echo "⚡ Internal: target self-checks"
echo "========================================================"

echo "[TEST 4] 25-item security audit (ja + en)..."
docker exec "$TARGET_CONT" env LANG=ja_JP.UTF-8 roamswitch status --server | head -5
docker exec "$TARGET_CONT" env LANG=C roamswitch status --server | head -5

echo ""
echo "[TEST 5] Critical-Path FIM: tamper /bin/login, expect detection..."
docker exec "$TARGET_CONT" roamswitch fim verify >/dev/null 2>&1 && pass "Baseline clean before the attack." || fail "Baseline already reports tampering!"
docker exec "$TARGET_CONT" bash -c "cp /bin/login /bin/login.bak && echo '# BACKDOOR_TAMPER' >> /bin/login"
set +e
docker exec "$TARGET_CONT" roamswitch fim verify
FIM_RET=$?
set -e
if [ $FIM_RET -ne 0 ]; then pass "FIM detected the tampering."; else fail "FIM did NOT detect the tampering!"; fi
docker exec "$TARGET_CONT" bash -c "mv /bin/login.bak /bin/login"
docker exec "$TARGET_CONT" roamswitch fim update --quiet
docker exec "$TARGET_CONT" roamswitch fim verify >/dev/null 2>&1 && pass "Baseline re-synced after restore." || fail "Baseline still reports tampering after restore!"

echo ""
echo "[TEST 6] guard.yaml on_critical: real decoy process + kill_process:true..."
docker exec -d "$TARGET_CONT" bash -c "exec -a fake_exploit sleep 3600"
sleep 1
EXPLOIT_PID=$(docker exec "$TARGET_CONT" pgrep -f "fake_exploit" | head -n1)
docker exec "$TARGET_CONT" bash -c "echo '{\"priority\":\"Critical\",\"rule\":\"fake_kernel_exploit\",\"time\":\"2026-09-07T00:00:00Z\",\"output_fields\":{\"proc.name\":\"fake_exploit\",\"proc.pid\":$EXPLOIT_PID,\"user.name\":\"attacker\"}}' | socat - UNIX-CONNECT:/run/roamswitch/events.sock"
sleep 2
if log | grep -q "eBPF Security Event Received"; then pass "Daemon logged the injected Critical event."; else fail "Daemon did not log the injected event."; fi
if docker exec "$TARGET_CONT" bash -c "kill -0 $EXPLOIT_PID" 2>/dev/null; then fail "kill_process:true did not terminate the offending PID."; else pass "on_critical (isolate + kill_process) terminated the offending PID."; fi

echo ""
echo "[TEST 7] Protected-process safety rail: real sshd must survive a Critical alert..."
SSHD_PID=$(docker exec "$TARGET_CONT" pgrep -x sshd | head -n1)
docker exec "$TARGET_CONT" bash -c "echo '{\"priority\":\"Critical\",\"rule\":\"fake_kernel_exploit\",\"time\":\"2026-09-07T00:00:00Z\",\"output_fields\":{\"proc.name\":\"sshd\",\"proc.pid\":$SSHD_PID,\"user.name\":\"root\"}}' | socat - UNIX-CONNECT:/run/roamswitch/events.sock"
sleep 2
if docker exec "$TARGET_CONT" bash -c "kill -0 $SSHD_PID" 2>/dev/null; then pass "sshd survived — protected-process list honoured."; else fail "sshd was killed/frozen! Protected-process exclusion failed."; fi

echo ""
echo "[TEST 8] guard.yaml on_emergency: host-wide Air-Gap, SSH lockout prevention..."
docker exec "$TARGET_CONT" bash -c "echo '{\"priority\":\"Emergency\",\"rule\":\"fake_ransomware_c2\",\"time\":\"2026-09-07T00:00:00Z\",\"output_fields\":{\"proc.name\":\"fake_ransom\",\"proc.pid\":99999,\"user.name\":\"attacker\"}}' | socat - UNIX-CONNECT:/run/roamswitch/events.sock"
sleep 2
if docker exec "$ATTACKER_CONT" curl -s -m 2 "http://$TARGET_IP:80/" >/dev/null; then fail "Target still reachable after an Emergency alert!"; else pass "Air-Gap isolation engaged."; fi
if tcp_reachable "$TARGET_IP" 22; then pass "SSH stayed reachable during Air-Gap (preserve_ssh_on_isolation)."; else fail "SSH was cut off during Air-Gap!"; fi

echo ""
echo "[TEST 9] Safety timer: auto-restore with no ACK (guard.yaml sets safety_timer_secs=5)..."
sleep 20
if curl_reachable "$TARGET_IP" 80; then pass "Air-Gap auto-restored without any ACK."; else fail "Air-Gap did NOT auto-restore."; fi

echo ""
echo "[TEST 10] Safety timer: 'roamswitch server ack' suppresses auto-restore..."
docker exec "$TARGET_CONT" bash -c "echo '{\"priority\":\"Emergency\",\"rule\":\"fake_ransomware_c2\",\"time\":\"2026-09-07T00:00:01Z\",\"output_fields\":{\"proc.name\":\"fake_ransom\",\"proc.pid\":99998,\"user.name\":\"attacker\"}}' | socat - UNIX-CONNECT:/run/roamswitch/events.sock"
sleep 2
docker exec "$TARGET_CONT" roamswitch server ack
sleep 20
if curl_reachable "$TARGET_IP" 80; then fail "Air-Gap auto-restored even though ACKed!"; else pass "ACKed incident correctly stayed isolated."; fi
docker exec "$TARGET_CONT" roamswitch emergency-restore
sleep 2
if curl_reachable "$TARGET_IP" 80; then pass "'emergency-restore' lifted the Air-Gap."; else fail "'emergency-restore' did not restore connectivity."; fi

echo ""
echo "[TEST 11] Kernel hardening degrades gracefully under a read-only /proc/sys (see README.md)..."
if log | grep -q "Server Edition permanent kernel hardening applied"; then pass "Hardening routine ran to completion without crashing."; else fail "Hardening routine did not report completion."; fi

echo ""
echo "[TEST 12] CLI configuration surface..."
docker exec "$TARGET_CONT" roamswitch server config show | head -10
docker exec "$TARGET_CONT" roamswitch server config set ssh_ports 2222 >/dev/null
docker exec "$TARGET_CONT" roamswitch server config get ssh_ports
docker exec "$TARGET_CONT" roamswitch server config set ssh_ports 22 >/dev/null
docker exec "$TARGET_CONT" roamswitch server test-notify all || true

echo ""
echo "[TEST 13] eBPF socket at the canonical /run path..."
if docker exec "$TARGET_CONT" test -S /run/roamswitch/events.sock; then pass "Socket present at /run/roamswitch/events.sock."; else fail "Socket missing."; fi

echo ""
echo "========================================================"
echo "📋 Results: PASS=$PASS  FAIL=$FAIL"
echo "========================================================"
log | tail -80

docker rm -f "$TARGET_CONT" "$ATTACKER_CONT" "$C2_CONT" 2>/dev/null || true
echo "All containers cleaned up."
[ "$FAIL" -eq 0 ]
