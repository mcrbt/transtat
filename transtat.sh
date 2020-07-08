#!/bin/bash
##
## transtat - show data amount transferred since boot
## Copyright (C) 2020  Daniel Haase
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.
##

TITLE="transtat"      ## application name
VERSION="1.1.2"       ## script version
AUTHOR="Daniel Haase" ## script author
CRYEARS="2020"        ## years of active development for copyright notice
SYM_UP=$'\u2191'      ## unicode arrow up symbol
SYM_DW=$'\u2193'      ## unicode arrow down symbol
SCALE=2               ## number of decimal digits

## print script version and copyright notice
function version
{
  echo "$TITLE $VERSION"
  echo "copyright (c) $CRYEARS $AUTHOR"
}

## print detailed usage information
function usage
{
  echo ""
  version
  echo ""; echo ""
  echo "usage:   $TITLE [<transspec>] [<ifspec>] [packet[s]]"
  echo "         $TITLE [list | route | home | version | help]"
  echo ""; echo ""
  echo "data transfer direction specification <transspec>:"
  echo ""
  echo "   down, up, each, sum"
  echo "      print data amount received, transmitted, each of them, or their sum"
  echo "      if no direction is given \"sum\" is assumed"
  echo ""; echo ""
  echo "interface specification <ifspec>:"
  echo ""
  echo "   <interface>"
  echo "      print value(s) only for <interface>"
  echo ""
  echo "   all"
  echo "      print value(s) for all interfaces, grouped by interface,"
  echo "      including the loopback device"
  echo ""
  echo "   link | net"
  echo "      print value(s) for all interfaces, grouped by interface,"
  echo "      excluding the loopback device"
  echo ""
  echo "   cumulative"
  echo "      sum up the value(s) for all interfaces and print a cumulative"
  echo "      amount, excluding the loopback device"
  echo "      (not yet supported)"
  echo ""
  echo "   default | current"
  echo "      print value(s) only for the current default route interface"
  echo ""
  echo "   loopback"
  echo "      print value(s) only for loopback device"
  echo ""
  echo "   if no interface(s) is/are given, \"default\" is assumed"
  echo "   if \"packet\" or \"packets\" is given, also print the number of packets"
  echo ""; echo ""
  echo "other commands:"
  echo ""
  echo "   list"
  echo "      list all installed network interfaces and exit immediately"
  echo ""
  echo "   route"
  echo "      print name of current default route interface"
  echo ""
  echo "   home"
  echo "      print name of loopback device"
  echo ""
  echo "   version"
  echo "      print version of this script and exit immediately"
  echo ""
  echo "   help"
  echo "      print this usage information and exit immediately"
  echo ""; echo ""
  echo "all of the options can appear in any order"
  echo "if contrary options are given the latter one applies"
  echo ""
  echo "running $TITLE with no arguments is the same as:"
  echo "   \"bash transtat.sh default sum\""
  echo ""; echo ""
}

## check if command "$1" is availalbe from "$PATH"
## return 0 on success, 1 on failure
function hascmd
{
  local c="$1"
  if [ $# -eq 0 ] || [ -z "$c" ]; then return 0; fi
  which "$c" &> /dev/null
  if [ $? -eq 0 ]; then return 0
  else return 1; fi
}

## exit with error message if command "$1" is not available from "$PATH"
function checkcmd
{
  if hascmd "$1"; then return 0
  else echo "command \"$c\" not found"; exit 1; fi
}

## return 0 (success) if bash version is greater 4.2, 1 (failure) if not
function bashversion
{
  local BASH_VERSION="$(bash --version | awk '/GNU bash, version/ {print $4}' | awk -F "(" '{print $1}')"
  if [[ $BASH_VERSION > '4.2' ]]; then return 0
  else return 1; fi
}

## echo binary "human readable" data amount (powers of 2) from number of bytes "$1"
function human
{
  local a="$1"
  if [ $# -eq 0 ] || [ -z "$a" ]; then echo "0.00   B"; return; fi

  local fmt="0.00   B"

  ## the first two units do not fit in Bash's integer type!
  #if [ $a -gt 1208925819614629174706176 ]; then fmt="$(echo "scale=$SCALE; $a / 1208925819614629174706176" | bc) YiB"
  #elif [ $a -gt 1180591620717411303424 ]; then fmt="$(echo "scale=$SCALE; $a / 1180591620717411303424" | bc) ZiB"
  if [ $a -gt 1152921504606846976 ]; then fmt="$(echo "scale=$SCALE; $a / 1152921504606846976" | bc) EiB"
  elif [ $a -gt 1125899906842624 ]; then fmt="$(echo "scale=$SCALE; $a / 1125899906842624" | bc) PiB"
  elif [ $a -gt 1099511627776 ]; then fmt="$(echo "scale=$SCALE; $a / 1099511627776" | bc) TiB"
  elif [ $a -gt 1073741824 ]; then fmt="$(echo "scale=$SCALE; $a / 1073741824" | bc) GiB"
  elif [ $a -gt 1048576 ]; then fmt="$(echo "scale=$SCALE; $a / 1048576" | bc) MiB"
  elif [ $a -gt 1024 ]; then fmt="$(echo "scale=$SCALE; $a / 1024" | bc) KiB"
  else fmt="${a}.00   B"; fi
  echo "$fmt"
}

## get name of loopback interface
function loopback
{
  echo "$(ip link show | awk '/LOOPBACK/ {print $2}' | sed 's/.$//')"
}

## get space separated list of available network interfaces
function interfaces
{
  echo "$(ip link show | awk '/mtu|state|qlen/ {print $2}' \
    | perl -pe 's/.\n/ /g')"
}

## get list of available network interfaces (one interface per line)
function list
{
  for i in $(interfaces); do echo "$i"; done
}

## get space separated list of available network interfaces excluding
## loopback device
function links
{
  echo "$(ip link show | awk '/mtu|state|qlen/ {print $2}' \
    | grep -v $(loopback): | perl -pe 's/.\n/ /g')"
}

## return 0 (success) if interface "$1" exists, 1 (failure) if not
function hasinterface
{
  local if="$1"
  if [ $# -eq 0 ] || [ -z "$if" ]; then return 1; fi

  local res="$(ip link show | awk '/mtu|state|qlen/ {print $2}' \
    | sed 's/.$//' | grep $if)"
  if [ -z "$res" ]; then return 1 ## interface does not exists
  else return 0; fi ## interface exists
}

## echo network interface currently used for the default route
function currentinterface
{
  echo "$(ip route | awk '/^default/ {print $5}')"
}

## get number of bytes received using interface "$1"
function rxbytes
{
  local if="$1"
  if [ $# -eq 0 ] || [ -z "$if" ]; then echo "0"; return; fi
  read rx < "/sys/class/net/${if}/statistics/rx_bytes"
  echo "$rx"
}

## get number of packets received using interface "$1"
function rxpackets
{
  local if="$1"
  if [ $# -eq 0 ] || [ -z "$if" ]; then echo "0"; return; fi
  read rx < "/sys/class/net/${if}/statistics/rx_packets"
  echo "$rx"
}

## get number of bytes sent using interface "$1"
function txbytes
{
  local if="$1"
  if [ $# -eq 0 ] || [ -z "$if" ]; then echo "0"; return; fi
  read tx < "/sys/class/net/${if}/statistics/tx_bytes"
  echo "$tx"
}

## get number of packets sent using interface "$1"
function txpackets
{
  local if="$1"
  if [ $# -eq 0 ] || [ -z "$if" ]; then echo "0"; return; fi
  read tx < "/sys/class/net/${if}/statistics/tx_packets"
  echo "$tx"
}

## get list of data amount downloaded grouped by interface
## if $p ("$1") equals 1 also print number of packets received
## $ifs ("$2[@]") is a list of interfaces
function opdown
{
  if [ $# -lt 2 ]; then echo -n ""; return; fi

  local p="$1"
  shift
  local ifs="$@"
  local res=""
  local ires=""

  if [ -z "$p" ] || [ -z "$ifs" ]; then echo -n ""; return; fi

  for k in $ifs; do
    if ! hasinterface "$k"; then continue; fi
    local rxb=$(rxbytes "$k")

    if [ $p -eq 1 ]; then
      local rxp=$(rxpackets "$k")
      ires=$(printf "  %-12s %s %11s (%s packets)" \
        "$k" "$SYM_DW" "$(human $rxb)" "$rxp")
    else
      ires=$(printf "  %-12s %s %11s" \
        "$k" "$SYM_DW" "$(human $rxb)")
    fi

    res="${res}${ires}\n"
  done

  if [ -z "$res" ]; then echo -n ""
  else printf "$res"; fi
}

## get list of data amount uploaded grouped by interface
## if $p ("$1") equals 1 also print number of packets transmitted
## $ifs ("$2[@]") is a list of interfaces
function opup
{
  if [ $# -lt 2 ]; then echo -n ""; return; fi

  local p="$1"
  shift
  local ifs="$@"
  local res=""
  local ires=""

  if [ -z "$p" ] || [ -z "$ifs" ]; then echo -n ""; return 1; fi

  for k in $ifs; do
    if ! hasinterface "$k"; then continue; fi
    local txb=$(txbytes "$k")

    if [ $p -eq 1 ]; then
      local txp=$(txpackets "$k")
      ires=$(printf "  %-12s %s %11s (%s packets)" \
        "$k" "$SYM_UP" "$(human $txb)" "$txp")
    else
      ires=$(printf "  %-12s %s %11s" \
        "$k" "$SYM_UP" "$(human $txb)")
    fi

    res="${res}${ires}\n"
  done

  if [ -z "$res" ]; then echo -n ""
  else printf "$res"; fi
}

## get list of data amount downloaded and uploaded grouped by interface
## if $p ("$1") equals 1 also print number of packets received/transmitted
## $ifs ("$2[@]") is a list of interfaces
function opeach
{
  if [ $# -lt 2 ]; then echo -n ""; return; fi

  local p="$1"
  shift
  local ifs="$@"
  local res=""
  local ires=""

  if [ -z "$p" ] || [ -z "$ifs" ]; then echo -n ""; return; fi

  for k in $ifs; do
    if ! hasinterface "$k"; then continue; fi
    local rxb=$(rxbytes "$k")
    local txb=$(txbytes "$k")

    if [ $p -eq 1 ]; then
      local rxp=$(rxpackets "$k")
      local txp=$(txpackets "$k")
      ires=$(printf "  %-12s %s %11s (%s packets)     %s %11s (%s packets)" \
        "$k" "$SYM_DW" "$(human $rxb)" "$rxp" \
        "$SYM_UP" "$(human $txb)" "$txp")
    else
      ires=$(printf "  %-12s %s %11s     %s %11s" \
        "$k" "$SYM_DW" "$(human $rxb)" "$SYM_UP" "$(human $txb)")
    fi

    res="${res}${ires}\n"
  done

  if [ -z "$res" ]; then echo -n ""
  else printf "$res"; fi
}

## get list of sums of data amounts downloaded and uploaded grouped by interface
## if $p ("$1") equals 1 also print number of packets received/transmitted
## $ifs ("$2[@]") is a list of interfaces
function opsum
{
  if [ $# -lt 2 ]; then echo -n ""; return; fi

  local p="$1"
  shift
  local ifs="$@"
  local res=""
  local ires=""
  local sumb=0
  local sump=0

  if [ -z "$p" ] || [ -z "$ifs" ]; then echo -n ""; return; fi

  for k in $ifs; do
    if ! hasinterface "$k"; then continue; fi
    local rxb=$(rxbytes "$k")
    local txb=$(txbytes "$k")
    sumb=$(echo "scale=$SCALE; ($rxb + $txb)" | bc)

    if [ $p -eq 1 ]; then
      local rxp=$(rxpackets "$k")
      local txp=$(txpackets "$k")
      sump=$(echo "scale=$SCALE; ($rxp + $txp)" | bc)
      ires=$(printf "  %-12s %s %11s (%s packets)" \
        "$k" "${SYM_DW}${SYM_UP}" "$(human $sumb)" "$sump")
    else
      ires=$(printf "  %-12s %s %11s" \
        "$k" "${SYM_DW}${SYM_UP}" "$(human $sumb)")
    fi

    res="${res}${ires}\n"
  done

  if [ -z "$res" ]; then echo -n ""
  else printf "$res"; fi
}

## collect requested interfaces from command line specification
function collect
{
  local ifs="$1"
  if [ "$ifs" == "all" ]
  then echo "$(interfaces)"
  elif [ "$ifs" == "current" ] || [ "$ifs" == "default" ]
  then echo "$(currentinterface)"
  elif [ "$ifs" == "link" ] || [ "$ifs" == "net" ]
  then echo "$(links)"
  elif [ "$ifs" == "cumulative" ]
  then echo "$(links)" ## better use "$(interfaces)"?
  elif [ "$ifs" == "loopback" ]
  then echo "$(loopback)"
  elif hasinterface "$ifs"; then echo "$ifs"
  elif ! hasinterface "$ifs"; then exit 3; fi ## no such interface
}

## process command line arguments
function cmdline
{
  if [ $# -eq 0 ] || [ -z "$1" ]; then return; fi

  local ifs=""
  while [ ! -z "$1" ]; do
    if [[ "$1" == "-"* ]]; then usage; exit 1; break; fi
    if [ "$1" == "help" ]; then usage; exit 0; break
    elif [ "$1" == "version" ]; then version; exit 0; break
    elif [ "$1" == "list" ]; then list; exit 0; break
    elif [ "$1" == "route" ]; then currentinterface; exit 0; break
    elif [ "$1" == "home" ]; then loopback; exit 0; break
    elif [ "$1" == "down" ]; then MODE="down"
    elif [ "$1" == "up" ]; then MODE="up"
    elif [ "$1" == "each" ]; then MODE="each"
    elif [ "$1" == "sum" ]; then MODE="sum"
    elif [ "$1" == "all" ]; then ifs="all"
    elif [ "$1" == "default" ] || [ "$1" == "current" ]; then ifs="default"
    elif [ "$1" == "link" ] || [ "$1" == "net" ]; then ifs="link"
    elif [ "$1" == "cumulative" ]; then ifs="cumulative"
    elif [ "$1" == "loopback" ]; then ifs="loopback"
    elif [ "$1" == "packet" ] || [ "$1" == "packets" ]; then PACKET=1
    elif hasinterface "$1"; then ifs="$1"
    elif ! hasinterface "$1"; then
      echo "no such interface \"$1\""
      #ifs="current"
      exit 3
      break
    fi
    shift
  done

  INTERFACES="$(collect $ifs)"
}

## execute actual operation based on global configuration variables
function operate
{
  local res=""

  ## ensure required parameters are set
  if [ -z "$MODE" ]; then MODE="sum"; fi
  if [ -z "$INTERFACES" ]; then INTERFACES="$(currentinterface)"; fi
  if [ -z "$PACKET" ]; then PACKET=0; fi

  if [ "$MODE" == "down" ]; then opdown $PACKET $INTERFACES
  elif [ "$MODE" == "up" ]; then opup $PACKET $INTERFACES
  elif [ "$MODE" == "each" ]; then opeach $PACKET $INTERFACES
  elif [ "$MODE" == "sum" ]; then opsum $PACKET $INTERFACES
  else echo "invalid mode \"$MODE\""; fi
}

## check for dependancies
checkcmd "awk"
checkcmd "bc"
checkcmd "grep"
checkcmd "ip"
checkcmd "perl"
checkcmd "sed"

## initializing defaults
MODE="sum"
INTERFACES="$(currentinterface)"
PACKET=0

## parse command line arguments
cmdline $@

## execute actual operation based on global configuration variables
## and print result to STDOUT iff any
operate

## exit successfully
exit 0
