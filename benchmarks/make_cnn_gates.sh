#!/usr/bin/env bash

set -e

LUT_SIZES="2"

mkdir -p csv

file="csv/cnn_gates.csv"
echo "mode,gates" > "$file"

# SFE
num_and_gates=$(./calc_and_gates.awk "cnn/cnn_pub.cpp_none_2_luc.spfe")
echo "SFE,${num_and_gates}" >> "$file"

for lut_size in $LUT_SIZES ; do
    num_and_gates=$(./calc_and_gates.awk "cnn/cnn.cpp_none_${lut_size}_luc.spfe")
    echo "SPFE,${num_and_gates}" >> "$file"

    num_and_gates=$(./calc_and_gates.awk "cnn/cnn_priv.cpp_none_${lut_size}_luc.spfe")
    echo "PFE,${num_and_gates}" >> "$file"
done
