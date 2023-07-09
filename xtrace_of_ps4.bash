#!/usr/bin/env -iS bash
# shellcheck disable=SC2096 #(error): On most OS, shebangs can only specify a single parameter.
# shellcheck disable=SC2016 #(info): Expressions don't expand in single quotes, use double quotes for that.

set -x
declare -p PS4

var_ps4='\e[0;104m+ $(
  echo "PS4=var_ps4 11345 "
  declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE
)\e[m > \e[0;93m'
PS4='\e[0;104m+ $( echo 7001 )\e[m > \e[0;93m'
declare -p PS4

# prints xtrace of assignment to PS4
PS4="${var_ps4} 14581 "
declare -p PS4

# == xtrace ==
#
#[liveuser@localhost-live scf]$ reset; ./xtrace_of_ps4.bash |& cat -n
#     1	+ declare -p PS4
#     2	declare -- PS4="+ "
#     3	+ var_ps4='\e[0;104m+ $(
#     4	  echo "PS4=var_ps4 11345 "
#     5	  declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE
#     6	)\e[m > \e[0;93m'
#     7	+ PS4='\e[0;104m+ $( echo 7001 )\e[m > \e[0;93m'
#     8	+ 7001 > declare -p PS4
#     9	declare -- PS4="\\e[0;104m+ \$( echo 7001 )\\e[m > \\e[0;93m"
#    10	+ 7001 > PS4='\e[0;104m+ $(
#    11	  echo "PS4=var_ps4 11345 "
#    12	  declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE
#    13	)\e[m > \e[0;93m 14581 '
#    14	+ PS4=var_ps4 11345 
#    15	declare -a FUNCNAME
#    16	declare -- LINENO="19"
#    17	declare -- BASH_COMMAND="declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE"
#    18	declare -a BASH_LINENO=([0]="0")
#    19	declare -a BASH_SOURCE=([0]="./xtrace_of_ps4.bash") >  14581 declare -p PS4
#    20	declare -- PS4=$'\\e[0;104m+ $(\n  echo "PS4=var_ps4 11345 "\n  declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE\n)\\e[m > \\e[0;93m 14581 '
#    21	+ PS4=var_ps4 11345 
#    22	declare -a FUNCNAME
#    23	declare -- LINENO="24"
#    24	declare -- BASH_COMMAND="declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE"
#    25	declare -a BASH_LINENO=([0]="0")
#    26	declare -a BASH_SOURCE=([0]="./xtrace_of_ps4.bash") >  14581 exit 22
#[liveuser@localhost-live scf]$ 

  # <> Debug
  #exit $LINENO

# == OR ==

# if there was a previous assignment to PS4, prints an xtrace of contents of PS4
PS4="${var_ps4@P} 3692 "

# == xtrace ==
#
#[liveuser@localhost-live scf]$ reset; ./xtrace_of_ps4.bash |& cat -n
#...
#    21	+ PS4=var_ps4 11345 
#    22	declare -a FUNCNAME
#    23	declare -- LINENO="59"
#    24	declare -- BASH_COMMAND="declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE"
#    25	declare -a BASH_LINENO=([0]="0")
#    26	declare -a BASH_SOURCE=([0]="./xtrace_of_ps4.bash") >  14581 echo 'PS4=var_ps4 11345 '
#    27	+ PS4=var_ps4 11345 
#    28  declare -a FUNCNAME
#    29  declare -- LINENO="60"
#    30  declare -- BASH_COMMAND="declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE"
#    31  declare -a BASH_LINENO=([0]="0")
#    32  declare -a BASH_SOURCE=([0]="./xtrace_of_ps4.bash") >  14581 declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE
#    33	+ PS4=var_ps4 11345 
#    34  declare -a FUNCNAME
#    35  declare -- LINENO="58"
#    36  declare -- BASH_COMMAND="declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE"
#    37  declare -a BASH_LINENO=([0]="0")
#    38  declare -a BASH_SOURCE=([0]="./xtrace_of_ps4.bash") >  14581 PS4='+ PS4=var_ps4 11345 
#    39  declare -a FUNCNAME
#    40  declare -- LINENO="58"
#    41  declare -- BASH_COMMAND="declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE"
#    42  declare -a BASH_LINENO=([0]="0")
#    43  declare -a BASH_SOURCE=([0]="./xtrace_of_ps4.bash") >  3692 '
#[liveuser@localhost-live scf]$ 

