#!/bin/bash
# Genuine allowlisted tools writing many high-entropy files must NOT be frozen. usage: fp_case.sh NAME COMMAND...
name=$1; shift; ts=$(date +%s)
d=$HOME/Downloads/fp_$name; rm -rf "$d"; mkdir -p "$d"
D="$d" setsid bash -c "$*" > /tmp/fp_$$.out 2>&1 < /dev/null &
pid=$!; sleep 12
state=$(ps -o stat= -p $pid 2>/dev/null | tr -d ' ')
files=$(ls "$d" 2>/dev/null | wc -l)
hits=$(sudo journalctl -u roamswitch --since "@$ts" --no-pager -o cat 2>/dev/null | grep -c -E "RANSOMWARE|ransomware entropy burst")
echo "case=$name files=$files detections=$hits state=${state:-exited}"
kill -CONT $pid 2>/dev/null; pkill -CONT -P $pid 2>/dev/null
