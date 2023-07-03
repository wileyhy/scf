#!/bin/bash

mercury() {
  echo 'count, nBS:' "${#BASH_SOURCE[@]}"
  declare -p BASH_SOURCE BASH_LINENO FUNCNAME LINENO
  venus
}
venus() {
  echo 'count, nBS:' "${#BASH_SOURCE[@]}"
  declare -p BASH_SOURCE BASH_LINENO FUNCNAME LINENO
  earth
}
earth() {
  echo 'count, nBS:' "${#BASH_SOURCE[@]}"
  declare -p BASH_SOURCE BASH_LINENO FUNCNAME LINENO
  mars
}
mars() {
  echo 'count, nBS:' "${#BASH_SOURCE[@]}"
  declare -p BASH_SOURCE BASH_LINENO FUNCNAME LINENO
}


lineno_script_ps4=$((LINENO+1))
script_ps4='+ \e[0;104m $(
  line="$LINENO" ; 
  mapfile -t ir < <( 
    rev <<< "${!BASH_SOURCE[@]}" | 
      tr " " "\n" )
  for ii in "${ir[@]}" ; do 
    unset d1 s2 s3 s4
    d1="${ii}" ; 
    s2="${BASH_SOURCE[$ii+1]:-$0}" ; 
    s2="${s2#./}" ; 
    s3="${BASH_LINENO[$ii]}" ; 
    s4="${FUNCNAME[$ii]}" ; 
    printf "(%d):%s:%s:%s  " "$d1" "$s2" "$s3" "$s4" ; 
  done ; 
  unset s5 d6 s7 d8
  s5="${FUNCNAME[0]#./}"
  d6="${line:-PS4}"
  s7="${LINENO:-0}"
  d8=
  printf "(-1):%s:%s:%s:%s" "$s5" "$d6" "$s7" "$d8"
  )\e[m \n \e[0;93m |=\t=| \e[m $  '
lineno_PS4=$((LINENO+1))
PS4="${script_ps4}"
set -x

echo foo

#echo bar |
  #cat -Aen

#lsblk -O |
  #grep btrfs |
  #awk '{ print $10 }'

mercury

