#!/bin/bash                                                                                                                                                                                                      #d#
#d#
#d#
#d#
#d#

function convip2dec() {
  ip=$1
  IFS=. read -r a b c d <<< "$ip"
  printf '%s%d\n' "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
}

function convdec2ip () {
    local ip dec=$@
    for e in {3..0}
    do
        ((octet = dec / (256 ** e) ))
        ((dec -= octet * 256 ** e))
        ip+=$delim$octet
        delim=.
    done
    printf '%s\n' "$ip"
}

