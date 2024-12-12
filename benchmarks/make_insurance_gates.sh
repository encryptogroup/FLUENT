#!/usr/bin/env bash

set -e

PRIV_LUT_SIZES="2 3 4 8"
PUB_LUT_SIZES="none 4 8"

mkdir -p csv

file="csv/insurance_gates.csv"
echo "framework,mode,pub_lut_size,priv_lut_size,gates" > "$file"

# SFE
for pub_lut_size in $PUB_LUT_SIZES ; do
    num_and_gates=$(./calc_and_gates.awk "insurance/insurance_pub.v_${pub_lut_size}_2_luc.spfe")
    echo "fluent,sfe,${pub_lut_size},-,${num_and_gates}" >> "$file"
done

# numbers from CBMC-GC-based SPFE paper (Günther et al.)
echo "cbmc,spfe,none,-,377032" >> "$file"
echo "cbmc,pfe,none,-,3389525" >> "$file"

for pub_lut_size in $PUB_LUT_SIZES ; do
    for priv_lut_size in $PRIV_LUT_SIZES ; do
        num_and_gates=$(./calc_and_gates.awk "insurance/insurance.v_${pub_lut_size}_${priv_lut_size}_luc.spfe")
        echo "fluent,spfe,${pub_lut_size},{priv_lut_size},${num_and_gates}" >> "$file"

        num_and_gates=$(./calc_and_gates.awk "insurance/insurance_priv.v_${pub_lut_size}_${priv_lut_size}_luc.spfe")
        echo "fluent,pfe,${pub_lut_size},{priv_lut_size},${num_and_gates}" >> "$file"
    done
done
