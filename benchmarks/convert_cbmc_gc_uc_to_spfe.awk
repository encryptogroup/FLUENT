#!/usr/bin/env -S awk -f

/^C/ {
    $1 = "";
    client_wires = $0;
}
/^S/ {
    $1 = "";
    print "C", client_wires, $0;
}
/^O/ { print $0 }

/^A/ { print $0 }
/^Y/ { print $0 }
/^U/ { print $0 }
/^X/ { print "E", $2, $3, $4 }
/^P/ { print "X", $2, $3, $4, $5 }
