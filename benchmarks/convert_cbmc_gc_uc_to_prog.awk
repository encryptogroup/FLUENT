#!/usr/bin/env -S awk -f

/^0$/ {
    print $0
    next
}
/^1$/ {
    print $0
    next
}
/^2$/ {
    print "0", "0", "1", "0"
    next
}
/^3$/ {
    print "0", "0", "1", "1"
    next
}
/^4$/ {
    print "0", "1", "0", "0"
    next
}
/^5$/ {
    print "0", "1", "0", "1"
    next
}
/^6$/ {
    print "0", "1", "1", "0"
    next
}
/^7$/ {
    print "0", "1", "1", "1"
    next
}
/^8$/ {
    print "1", "0", "0", "0"
    next
}
/^9$/ {
    print "1", "0", "0", "1"
    next
}
/^10$/ {
    print "1", "0", "1", "0"
    next
}
/^11$/ {
    print "1", "0", "1", "1"
    next
}
/^12$/ {
    print "1", "1", "0", "0"
    next
}
/^13$/ {
    print "1", "1", "0", "1"
    next
}
/^14$/ {
    print "1", "1", "1", "0"
    next
}
/^15$/ {
    print "1", "1", "1", "1"
    next
}

{
    print "Unknown bit pattern: ", $0
    exit 1
}
