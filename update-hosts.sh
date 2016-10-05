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
# Uses the $SQLITE_DB variable as target DB
#
# $1: hostname
# $2: IP address
# returns nothing
#
function INSERT_HOST()
{
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo "Bad host"
        return
    fi
    echo "Hostname: $1"
    echo "IP: $2"
    "${LOCAL_PYTHON}" "${PYSCRIPT}" "host" "$1" "$2"
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
        INSERT_HOST $(echo $e | cut -d',' -f1) $(echo $e | cut -d',' -f2)
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
        if [ "$i" = "ham0" ] || [ "$i" == *"docker" ] || [ "$i" == *"br" ]; then
            # Because Hamachi uses /8 network mask, we skip this case for now
            echo "Skipping interface: $i"
            continue
        fi
        SCAN_HOSTS $(GET_SUBNET $i)
        INSERT_INF "$i" "$(GET_SUBNET $i)"
    done
}

main
