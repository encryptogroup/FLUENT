#!/usr/bin/env bash

set -e

ITERATIONS="10"
NETWORKS="lan10 wan"
COPIES="1 10 100"

ID=$(date '+%Y-%m-%d-%H-%M-%S')

while read circuit ; do
    for copies in $COPIES; do
        for network in $NETWORKS ; do
            ./run_aby.sh "$circuit" "$ITERATIONS" "$network" "$copies" "$ID"
        done
    done
done < run_list.txt
