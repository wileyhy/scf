#!/usr/bin/env -iS bash
# shellcheck disable=SC2096 #(error): On most OS, shebangs can only specify a single parameter.
# shellcheck disable=SC2016 #(info): Expressions don't expand in single quotes, use double quotes for that.

var_ps4='\e[0;104m+ $( 
  echo var_ps4; 
  echo; 
  declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE; 
  echo; 
)\e[m > \e[0;93m'

set -x
declare -p PS4
PS4='\e[0;104m+ $( echo 111 )\e[m > \e[0;93m'


# prints xtrace of assignment to PS4
PS4="${var_ps4}"

# + declare -p PS4
# declare -- PS4="+ "
# + PS4='\e[0;104m+ $( echo 111 )\e[m > \e[0;93m'
# + 111 > PS4='\e[0;104m+ $( 
#     echo var_ps4
#     echo 
#     declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE 
#     echo
#   )\e[m > \e[0;93m'
# + var_ps4
#
# declare -a FUNCNAME
# declare -- LINENO="29"
# declare -- BASH_COMMAND="declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE"
# declare -a BASH_LINENO=([0]="0")
# declare -a BASH_SOURCE=([0]="./scrptPs4.bash_1") > lineno_PS4=26

# == OR ==


# if there was a previous assignment to PS4, prints an xtrace of contents of PS4
PS4="${var_ps4@P}"

# + declare -p PS4
# declare -- PS4="+ "
# + PS4='\e[0;104m+ $( echo 111 )\e[m > \e[0;93m'
# + 111 > echo var_ps4
# + 111 > echo
# + 111 > declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE
# + 111 > echo
# + 111 > PS4='+ var_ps4
# 
# declare -a FUNCNAME
# declare -- LINENO="49"
# declare -- BASH_COMMAND="declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE"
# declare -a BASH_LINENO=([0]="0")
# declare -a BASH_SOURCE=([0]="./scrptPs4.bash_1") > '
# + var_ps4
# 
# declare -a FUNCNAME
# declare -- LINENO="49"
# declare -- BASH_COMMAND="declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE"
# declare -a BASH_LINENO=([0]="0")
# declare -a BASH_SOURCE=([0]="./scrptPs4.bash_1") > lineno_PS4=46

