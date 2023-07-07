#!/usr/bin/env -iS bash

letters_ps4='\e[0;104m+ $( 
  echo letters_ps4; 
  echo a; 
  echo b; 
  echo c 
)\e[m > \e[0;93m'

far_ps4='\e[0;104m+ $( 
  echo far_ps4; 
  echo; 
  declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE; 
  echo; 
)\e[m > \e[0;93m'

set -x
declare -p PS4
PS4='\e[0;104m+ $( echo 111 )\e[m > \e[0;93m'


# prints xtrace of assignment to PS4
PS4="${far_ps4}" lineno_PS4="$LINENO" 

# + declare -p PS4
# declare -- PS4="+ "
# + PS4='\e[0;104m+ $( echo 111 )\e[m > \e[0;93m'
# + 111 > PS4='\e[0;104m+ $( 
#     echo far_ps4
#     echo 
#     declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE 
#     echo
#   )\e[m > \e[0;93m'
# + far_ps4
#
# declare -a FUNCNAME
# declare -- LINENO="29"
# declare -- BASH_COMMAND="declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE"
# declare -a BASH_LINENO=([0]="0")
# declare -a BASH_SOURCE=([0]="./scrptPs4.bash_1") > lineno_PS4=26

# == OR ==


# prints xtrace of contents of PS4
PS4="${far_ps4@P}" lineno_PS4="$LINENO" 

# + declare -p PS4
# declare -- PS4="+ "
# + PS4='\e[0;104m+ $( echo 111 )\e[m > \e[0;93m'
# + 111 > echo far_ps4
# + 111 > echo
# + 111 > declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE
# + 111 > echo
# + 111 > PS4='+ far_ps4
# 
# declare -a FUNCNAME
# declare -- LINENO="49"
# declare -- BASH_COMMAND="declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE"
# declare -a BASH_LINENO=([0]="0")
# declare -a BASH_SOURCE=([0]="./scrptPs4.bash_1") > '
# + far_ps4
# 
# declare -a FUNCNAME
# declare -- LINENO="49"
# declare -- BASH_COMMAND="declare -p FUNCNAME LINENO BASH_COMMAND BASH_LINENO BASH_SOURCE"
# declare -a BASH_LINENO=([0]="0")
# declare -a BASH_SOURCE=([0]="./scrptPs4.bash_1") > lineno_PS4=46

