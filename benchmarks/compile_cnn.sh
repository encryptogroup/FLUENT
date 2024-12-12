#!/usr/bin/env bash

set -e

PUB_LUT_SIZES="none"
PRIV_LUT_SIZES="2 3"
CONSTRUCTIONS="luc"

while read -r verilog ; do
    for pub_lut_size in $PUB_LUT_SIZES ; do
        for priv_lut_size in $PRIV_LUT_SIZES ; do
            for construction in $CONSTRUCTIONS ; do
                spfe="${verilog%.cpp}.spfe"
                prog="${verilog%.cpp}.spfe.prog"
                mod_file_spfe="${verilog}_${pub_lut_size}_${priv_lut_size}_${construction}.spfe"
                mod_file_prog="${verilog}_${pub_lut_size}_${priv_lut_size}_${construction}.spfe.prog"
                if [ -f "$mod_file_spfe" ] ; then
                    true
                else
                    if [ "$pub_lut_size" = "none" ] ; then
                        echo spfe -l "$priv_lut_size" -c "$construction" -t network --dont-optimize-area "$verilog"
                        spfe -l "$priv_lut_size" -c "$construction" -t network --dont-optimize-area "$verilog"
                    else
                        echo spfe -l "$priv_lut_size" -L "$pub_lut_size" -c "$construction" -t network --dont-optimize-area "$verilog"
                        spfe -l "$priv_lut_size" -L "$pub_lut_size" -c "$construction" -t network --dont-optimize-area "$verilog"
                    fi
                    mv "$spfe" "$mod_file_spfe"
                    mv "$prog" "$mod_file_prog"
                fi
            done
        done
    done
done < list_cnn.txt
