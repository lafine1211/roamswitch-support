#!/bin/bash
# usage: victim_monitor.sh SECONDS GW_IP OUTFILE
end=$((SECONDS+$1)); gw=$2; out=$3; : > $out
while [ $SECONDS -lt $end ]; do
  rec=$(cat /run/roamswitch/airgap_isolation.json 2>/dev/null | tr -d '\n ' | cut -c1-160)
  echo "$(date +%T) gw=[$(ip neigh show $gw | awk '{print $3,$4,$5}')] emergency_table=$(nft list tables 2>/dev/null | grep -c roamswitch_emergency) record=[$rec]" >> $out
  sleep 1
done
