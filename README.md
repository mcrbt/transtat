# transtat

## Description

`transtat` is a Bash script capable of printing the amount of data transferred
over a network link since system boot. This may be interesting for users
connecting to a WAN network via a SIM card attached to their laptop. This way
the user can keep track of the (possibly restricted) amount of data volume that
has already been spent.

It is possible to list the amount of data that has been uploaded, or downloaded,
or both, or their sum, for a specific network interface.
Additionally, the number of packets which have been transferred can be printed.

Running `transtat` with no arguments prints the sum of data uploaded and
download via the network interface currently used (i.e. the *default route*).

For details on the command line options and their respective combinations please
take a look at the *Usage* section below.


## Usage

```

transtat 1.1.2
copyright (c) 2020 Daniel Haase


usage:   transtat [<transspec>] [<ifspec>] [packet[s]]
         transtat [list | route | home | version | help]


data transfer direction specification <transspec>:

   down, up, each, sum
      print data amount received, transmitted, each of them, or their sum
      if no direction is given "sum" is assumed


interface specification <ifspec>:

   <interface>
      print value(s) only for <interface>

   all
      print value(s) for all interfaces, grouped by interface,
      including the loopback device

   link | net
      print value(s) for all interfaces, grouped by interface,
      excluding the loopback device

   cumulative
      sum up the value(s) for all interfaces and print a cumulative
      amount, excluding the loopback device
      (not yet supported)

   default | current
      print value(s) only for the current default route interface

   loopback
      print value(s) only for loopback device

   if no interface(s) is/are given, "default" is assumed
   if "packet" or "packets" is given, also print the number of packets


other commands:

   list
      list all installed network interfaces and exit immediately

   route
      print name of current default route interface

   home
      print name of loopback device

   version
      print version of this script and exit immediately

   help
      print this usage information and exit immediately


all of the options can appear in any order
if contrary options are given the latter one applies

running transtat with no arguments is the same as:
   "bash transtat.sh default sum"


```


## Copyright

Copyright &copy; 2020 Daniel Haase

`transtat` is licensed under the **GNU General Public License**, version 3.


## License disclaimer

```
transtat - show data amount transferred since boot
Copyright (C) 2020 Daniel Haase

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see
<https://www.gnu.org/licenses/gpl-3.0.txt>.
```

[GPL](https://www.gnu.org/licenses/gpl-3.0.txt)
