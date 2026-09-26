#!/bin/bash
# usage: ransom_case.sh MODE [COMM]   (run as the desktop user; prints one result line)
mode=$1; comm=$2; d=$HOME/Downloads/sim_$mode${comm:+_$comm}
rm -rf "$d"; ts=$(date +%s)
setsid perl "$(dirname "$0")/ransom_sim.pl" "$d" "$mode" $comm > /tmp/sim_$$.out 2>&1 < /dev/null &
pid=$!
sleep 14
state=$(ps -o stat= -p $pid 2>/dev/null | tr -d ' ')
locked=$(ls "$d" 2>/dev/null | grep -c '\.locked$')
hits=$(sudo journalctl -u roamswitch --since "@$ts" --no-pager -o cat 2>/dev/null | grep -c -E "RANSOMWARE|ransomware entropy burst")
shadow=$(sudo journalctl -u roamswitch --since "@$ts" --no-pager -o cat 2>/dev/null | grep -c "ransomware shadow")
echo "mode=$mode comm=${comm:-perl(default)} state=${state:-exited} files_encrypted=$locked/40 detections=$hits shadow=$shadow"
kill -CONT $pid 2>/dev/null; kill -9 $pid 2>/dev/null
