#!/usr/bin/env bash

set -e

PUB_LUT_SIZES="none 4 8"
PRIV_LUT_SIZES="2 3 4 8"
CONSTRUCTIONS="luc vuc"

while read -r verilog ; do
    for pub_lut_size in $PUB_LUT_SIZES ; do
        for priv_lut_size in $PRIV_LUT_SIZES ; do
            for construction in $CONSTRUCTIONS ; do
                spfe="${verilog%.c}.spfe"
                prog="${verilog%.c}.spfe.prog"
                mod_file_spfe="${verilog}_${pub_lut_size}_${priv_lut_size}_${construction}.spfe"
                mod_file_prog="${verilog}_${pub_lut_size}_${priv_lut_size}_${construction}.spfe.prog"
                if [ -f "$mod_file_spfe" ] ; then
                    true
                else
                    if [ "$pub_lut_size" = "none" ] ; then
                        echo spfe -l "$priv_lut_size" -c "$construction" -I ../libc/musl/include -I ../libc/include/arm-linux-musl -t insurance_wrapper "$verilog"
                        spfe -l "$priv_lut_size" -c "$construction" -I ../libc/musl/include -I ../libc/include/arm-linux-musl -t insurance_wrapper "$verilog"
                    else
                        echo spfe -l "$priv_lut_size" -L "$pub_lut_size" -c "$construction" -I ../libc/musl/include -I ../libc/include/arm-linux-musl -t insurance_wrapper "$verilog"
                        spfe -l "$priv_lut_size" -L "$pub_lut_size" -c "$construction" -I ../libc/musl/include -I ../libc/include/arm-linux-musl -t insurance_wrapper "$verilog"
                    fi
                    mv "$spfe" "$mod_file_spfe"
                    mv "$prog" "$mod_file_prog"
                fi
            done
        done
    done
done < ../../list_c.txt
