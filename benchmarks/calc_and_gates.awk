#!/usr/bin/env -S awk -f

BEGIN { num_and_gates = 0 }

/^A/ { num_and_gates += 1; }
/^X/ { num_and_gates += 1; }
/^Y/ { num_and_gates += 1; }
/^U/ {
    num_inputs = NF - 2;
    num_mux = (2 ^ num_inputs) - 1;
    num_and_gates += num_mux;
}

END { print num_and_gates }
