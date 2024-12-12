#!/usr/bin/env bash

set -e

PUB_LUT_SIZES="none 4 8"
PRIV_LUT_SIZES="2 3 4 8"
CONSTRUCTIONS="luc vuc"

while read -r verilog ; do
    for pub_lut_size in $PUB_LUT_SIZES ; do
        for priv_lut_size in $PRIV_LUT_SIZES ; do
            for construction in $CONSTRUCTIONS ; do
                spfe="${verilog%.v}.spfe"
                prog="${verilog%.v}.spfe.prog"
                mod_file_spfe="${verilog}_${pub_lut_size}_${priv_lut_size}_${construction}.spfe"
                mod_file_prog="${verilog}_${pub_lut_size}_${priv_lut_size}_${construction}.spfe.prog"
                if [ -f "$mod_file_spfe" ] ; then
                    true
                else
                    # If the commands fail due to issues in Yosys-ABC,
                    # try opting for weaker optimization with the
                    # --dont-optimize-area command-line flag
                    if [ "$pub_lut_size" = "none" ] ; then
                        echo spfe -l "$priv_lut_size" -c "$construction" "$verilog"
                        spfe -l "$priv_lut_size" -c "$construction" "$verilog" || spfe -l "$priv_lut_size" -c "$construction" "$verilog" --dont-optimize-area
                    else
                        echo spfe -l "$priv_lut_size" -L "$pub_lut_size" -c "$construction" "$verilog"
                        spfe -l "$priv_lut_size" -L "$pub_lut_size" -c "$construction" "$verilog" || spfe -l "$priv_lut_size" -L "$pub_lut_size" -c "$construction" "$verilog" --dont-optimize-area
                    fi
                    mv "$spfe" "$mod_file_spfe"
                    mv "$prog" "$mod_file_prog"
                fi
            done
        done
    done
done < list.txt
