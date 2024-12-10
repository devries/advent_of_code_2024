#!/bin/sh

fullstart=$(date -u +%s)
for day in $(seq -f "%02g" 1 25); do
  finecho=1
  start=$(date -u +%s)
  dir="src/day${day}"
  if [ -d $dir ]; then
    printf "Day $day:\n"
    /usr/bin/time gleam run --no-print-progress -m day${day}/solution
    printf "\n"
  fi
done
fullend=$(date -u +%s)
duration=$((fullend-fullstart))
echo ""
echo "Total time elapsed: ${duration}s"
