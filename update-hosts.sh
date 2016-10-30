#!/bin/bash

APPDIR="$(dirname $(readlink -f "${0}"))"

LOCAL_PYTHON="python3"
PYSCRIPT="${APPDIR}/src/host_discover_server.py"

#
# $1: input data
# returns processed list, CSV per line
#
function PARSE_NMAP_OUTPUT()
{
    echo "$1" | grep 'Nmap scan report'|sed 's/Nmap scan report for \([a-zA-Z0-9\.\-]*\) (\([a-zA-Z0-9\.]*\))/\1,\2/g'
}

#
# $1: input IP
# returns potential HW address from IP, through ARP table
#
function LOOKUP_HWADDR()
{
    arp "$1" -H ether -n|grep -v "HWaddress"|sed -n 1p|awk '{print $3}'
}

#
# Uses the $SQLITE_DB variable as target DB
#
# $1: hostname
# $2: IP address
# $3: HW address
# returns nothing
#
function INSERT_HOST()
{
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo "Bad host"
        return
    fi
    echo "Hostname: $1, IP: $2, MAC: $3"
    "${LOCAL_PYTHON}" "${PYSCRIPT}" "host" "$1" "$2" "$3"
}

#
# $1: interface name
# $2: subnet
# returns nothing
#
function INSERT_INF()
{
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo "Bad interface"
        return
    fi
    echo "Interface: $1"
    echo "Subnet: $2"
    "${LOCAL_PYTHON}" "${PYSCRIPT}" "inf" "$1" "$2"
}

#
# $1: subnet
# returns nothing
#
function SCAN_HOSTS()
{
    echo "Scanning subnet $1"

    local NMAP_DATA=$(nmap -sP $1)
    local PARSED_DATA=$(PARSE_NMAP_OUTPUT "$NMAP_DATA")

    for e in ${PARSED_DATA}; do
        local IP="$(echo $e | cut -d',' -f2)"
        local HOST="$(echo $e | cut -d',' -f1)"
        INSERT_HOST $HOST $IP $(LOOKUP_HWADDR $IP)
    done
}

#
# returns list of network interfaces
#
function GET_INTERFACES()
{
    # We only scan IPv4 interfaces, IPv6 takes forever
    ip -f inet addr | grep '^[0-9]'|cut -d':' -f2|sed 's/ //g'
}

#
# $1: interface
# returns interface's subnet
#
function GET_SUBNET()
{
    ip addr show $1 | grep 'inet ' | sed -n 's/.*inet \(.*\) brd .*/\1/p' | head -1
}

function main()
{
    local INTERFACES=$(GET_INTERFACES)
    
    for i in $INTERFACES; do
        if [ "$(echo $(GET_SUBNET $i) | cut -d'/' -f 2)" != "24" ]; then
            echo "Skipping interface: $i, too large mask ($(echo $(GET_SUBNET $i) | cut -d'/' -f 2))"
            continue
        fi
        SCAN_HOSTS $(GET_SUBNET $i)
        INSERT_INF "$i" "$(GET_SUBNET $i)"
    done
}

main
