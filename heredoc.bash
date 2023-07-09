#!/usr/bin/env -iS bash -x
# shellcheck disable=SC2096,SC2089,SC2016,SC2090
tput sgr0

:                         "LINENO ${LINENO} :rand.28476:"

:                         "LINENO ${LINENO} :rand.7940:" 'Initial value of PS4'

read -ra default_PS4 < <(declare -p PS4)

:                         "LINENO ${LINENO} :rand.27518:"

:                         "LINENO ${LINENO} :rand.7156:" 'Verify the value is correct'

:; declare -p default_PS4

:                         "LINENO ${LINENO} :rand.13239:"

:                         "LINENO ${LINENO} :rand.15006:" 'Assigns parameter transformation'

PS4="${PS4@P}" 

:                         "LINENO ${LINENO} :rand.23445:"

:                         "LINENO ${LINENO} :rand.956:" 'Resets PS4'

eval "${default_PS4[@]}"

:                         "LINENO ${LINENO} :rand.19046:"

:                         "LINENO ${LINENO} :rand.241:" 'Assigns PS4 color codes and a command substitution'

PS4='\e[0;104m+ $( 
  :; echo                 "LINENO ${LINENO} :rand.7001:" 
  )\e[m > \e[0;93m' 

:                         "LINENO ${LINENO} :rand.21119:"

:                         "LINENO ${LINENO} :rand.4103:" 'Assigns parameter transformation'

PS4="${PS4@P}" 

:                         "LINENO ${LINENO} :rand.7926:"

:                         "LINENO ${LINENO} :rand.15207:" 'Resets PS4 to its initial value'

eval "${default_PS4[@]}"

:                         "LINENO ${LINENO} :rand.23421:"

:                         "LINENO ${LINENO} :rand.610:" 'A value for PS4 for debugging how xtrace prints line numbers'

var_ps4='\e[0;104m+ $( 
  :                       "LINENO ${LINENO} :rand.30089: variable line 1"
  :                       "LINENO ${LINENO} :rand.9617: variable line 2"
  :; printf -v var_line3  "LINENO ${LINENO} :rand.3793:" 

  declare -p FUNCNAME      LINENO BASH_LINENO BASH_SOURCE var_line3 random_no
  
  :                       "LINENO ${LINENO} :rand.25178: variable line 4"
  )\e[m > \e[0;93m'

:                       "LINENO ${LINENO} :rand.21232:"

:                       "LINENO ${LINENO} :rand.8329:" 'Commands within PS4 variable are printed in the PS4 space'

TERM="xterm-256color" export TERM

:; PS4="$(tput setaf 12) LINENO ${LINENO} :rand.14581: ${var_ps4}"

:                       "LINENO ${LINENO} :rand.14061:"

:                       "LINENO ${LINENO} :rand.4944:" 'If there was a variable value previously assigned to PS4, then this assignment syntax, of a parameter transformation, also prints the commands within the PS4 variable in the script-commands space of the xtrace output.' 

:; printf -v PS4        "LINENO ${LINENO} :rand.3692 : ${var_ps4@P}"

:                       "LINENO ${LINENO} :rand.20491:" 

