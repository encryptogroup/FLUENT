#!/usr/bin/env bash

set -e

MODES="pub priv"

mkdir -p csv

CIRCUITS="add32 add64 cmp32 cmp64 mul32 mul64"
for mode in $MODES ; do
    file="csv/sfe_pfe_gates_${mode}.csv"
    echo "circuit,gates" > "$file"
    for circuit in $CIRCUITS ; do
        num_and_gates=$(./calc_and_gates.awk "${circuit}/${circuit}${mode}.v_none_2_luc.spfe")
        echo "${circuit},${num_and_gates}" >> "$file"
    done
done

CIRCUITS="f32add f32cmp f32mul"
for mode in $MODES ; do
    file="csv/sfe_pfe_gates_${mode}.csv"
    for circuit in $CIRCUITS ; do
        num_and_gates=$(./calc_and_gates.awk "${circuit}/${circuit}_${mode}.v_none_2_luc.spfe")
        echo "${circuit},${num_and_gates}" >> "$file"
    done
done
