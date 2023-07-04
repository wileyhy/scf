#!/bin/bash

# Note: Location of colon (`:`) commands protects line numbers
mercury() { :
  echo 'count, nBS:' "${#BASH_SOURCE[@]}"
  declare -p BASH_SOURCE BASH_LINENO FUNCNAME LINENO
  venus
}
venus() { :
  echo 'count, nBS:' "${#BASH_SOURCE[@]}"
  declare -p BASH_SOURCE BASH_LINENO FUNCNAME LINENO
  earth
}
earth() { :
  echo 'count, nBS:' "${#BASH_SOURCE[@]}"
  declare -p BASH_SOURCE BASH_LINENO FUNCNAME LINENO
  mars
}
mars() { :
  echo 'count, nBS:' "${#BASH_SOURCE[@]}"
  declare -p BASH_SOURCE BASH_LINENO FUNCNAME LINENO
}

#   Goals:

# This:****                                                ***************************************************************
#   +  {#1}[1]script-ps4(170):PS4(165)close_ps4(31:73)
#   +  {#1               }[1    ]script-ps4 (170          ):PS4(165        )close_ps4  (31           :73                 )
#      {count of BS array}[level]script-name(script-lineno):PS4($lineno_ps4)ps4-fn-name(lineno-fn-def:lineno-def-this-var)
#

# This:      ********************************************************
#        At:|[level]script-name(script-lineno) In:<function-name> Fr:[level - 1]script-name(script-lineno) |
#      + At:|[ 2   ]gardning   (  38         ) In:<...          > Fr:[ 1       ]findscan   ( 129         )
#    | + At:|[ 6   ]gardning   ( 106         ) In:<_trp_int     > Fr:| 
#            [ 5   ]gardning   (   1         ) In:<...          > Fr:
#            [ 4]...(...) In:<...> Fr:
#            [ 3]...(...) In:<...> Fr:
#            [ 2]...(...) In:<...> Fr:
#            [ 1]...(...) In:<...> Fr:
#            [ 0]...(...)

# define a PS4 for stack tracing, and capture line numbers
# Note: grouping protects correct line numbers
{
  lineno_close_ps4_outside=$((LINENO+1))
  close_ps4='+ \e[0;104m $( 
    {
      inside_line_dist_a=4 # ...lines is the line distance away from the beginning of the definition of $close_ps4
      lineno_close_ps4_inside=$(( LINENO - inside_line_dist_a )) ; 
    }
    printf "{#%d}" "${#BASH_SOURCE[@]}" 
    unset ii s4 d5 s6 d7 d8 s9 
    ii=0
    d3="${lineno_close_ps4_inside}" ;
    d5="$lineno_PS4"
    s6=close_ps4
    d7="$lineno_close_ps4_outside"
    inside_line_dist_b=1 # I don-t know why this variable has a value of =2; it was =1 a few minutes ago....?
    d8=$(( LINENO + lineno_close_ps4_outside - d3 - inside_line_dist_b )) ;
    s4=PS4
    printf ":%s%s%s%s  " "$s4" "(${d5})" "${s6}" "(${d7}:${d8})" ; 
    )\e[m \n \e[0;93m |=\t=| \e[m $  '
}
            # <> cut 
          # you want BASH_SOURCE-s list of indices, reversed
          #mapfile -t ir < <( 
          #rev <<< "${!BASH_SOURCE[@]}" | 
          #tr " " "\n" )
          # if there weren-t any indices, then add zero
          #[[ "${#ir[@]}" -eq 0 ]] && ir=(0)
          #printf "{#%d}" "${#ir[@]}" 
          #for ii in "${ir[@]}" ; do 
          #unset s4 d5 s6 d7 d8 s9 
          #unset d1 s2 d3 s4 d5 s6 d7 d8 s9 
          #d1=$((ii+1)) ; 
          #s2="${BASH_SOURCE[$ii+1]:-$0}" ; 
          #s2="${s2#./}" ; 
          #s2="${s2%.*}" ;
          #if [[ "${BASH_LINENO[$ii]}" == 0 ]] ;
          #then 
          #else
          #d3="${BASH_LINENO[$ii]}" ;
          #fi ; 
          #s4="${FUNCNAME[$ii-1]}" ;
          #if [[ -z "$s4" ]] ; 
          #then 
          #fi
          #        d  s  d   s d s dd
          #        1  2  3   4 5 6 78
          #printf "[%d]%s(%d):%s%s%s%s  " "$d1" "$s2" "$d3" "$s4" "(${d5})" "${s6}" "(${d7}:${d8})" ; 
          #s9="$(
          #printf "\n\n" ; 
          #declare -p BASH_LINENO BASH_SOURCE FUNCNAME LINENO ii lineno_PS4 lineno_close_ps4_inside lineno_close_ps4_outside
          #)"
          #printf "%s" "$s9"
          #done ; 
    
            #*)
            #unset d11 s12 d13 s14 d15 s16 d17 d18 s19 
            #d11=$((ii+1)) ; 
            #s12="${BASH_SOURCE[$ii+1]:-$0}" ; 
            #s12="${s12#./}" ; 
            #s12="${s12%.*}" ;
            #if [[ "${BASH_LINENO[$ii]}" == 0 ]] ;
            #then 
            #d13="${lineno_close_ps4_inside}" ;
            #else
            #d13="${BASH_LINENO[$ii]}" ;
            #fi ; 
            #s14="${FUNCNAME[$ii-1]}" ;
            #d15="${BASH_LINENO[$ii-1]}"
            #if [[ -z "$s14" ]] ; 
            #then
            #echo wtf 12750 
            ##s14=main
            ##d15="$lineno_PS4"
            ##s16=close_ps4
            ##d17="$lineno_close_ps4_outside"
            ##inside_line_dist_c=2 # I don-t know why this variable has a value of 2; it was 1 a few minutes ago....?
            ##d18=$(( LINENO + lineno_close_ps4_outside - d13 - inside_line_dist_c )) ;
            #fi
            ##         d  s  d   s d s dd
            ##         11 12 13  1415161718
            #printf " [%d]%s(%d):%s%s%s%s "         "$d11" "$s12" "$d13" "$s14" "(${d15})" "${s16}" "(${d17}:${d18})" ; 
            ##printf " [%d]%s(%d):%s(%s)%s(%s:%s) " "$d11" "$s12" "$d13" "$s14"    $d15      $s16      $d17   $d18 ; 
            #s19="$(
            #printf "\n\n" ; 
            #declare -p BASH_LINENO BASH_SOURCE FUNCNAME LINENO ii lineno_PS4 lineno_close_ps4_inside lineno_close_ps4_outside
            #)"
            #printf "%s" "$s19"
            #;;

# Note: grouping protects correct line numbers
{
  lineno_far_ps4_outside=$((LINENO+1))
  far_ps4='\e[0;104m+ At:[\
    {
      inside_line_dist_a=3 # ...lines is the line distance away from the beginning of the definition of $close_ps4
      lineno_far_ps4_inside=$(( LINENO - inside_line_dist_a )) ; 
    }
    $( 
    printf "%2d" ${#BASH_SOURCE[@]} 
    )]\
    $( 
      : 21594 
    ) \
    $( 
      cut -c -8 <<< ${BASH_SOURCE[0]##*/} 
    )(\
    $( 
      printf "%4d" ${LINENO} 
    )) In:<\
    $( 
      printf "%-8s" ${FUNCNAME[0]:-""}
    )> Fr:\
    \e[m > \e[0;93m'
} 
        # <> cut
        #)> Fr:[\
        #$( 
        #printf "%2d" \
        #$(
        #( ${#BASH_SOURCE[@]} - 1 )\
        #) )]\
        #$( 
        #cut -c -8 <<< ${BASH_SOURCE[1]##*/} 
        #)(\
        #$( 
        #printf "%4d" ${BASH_LINENO[0]} \
        #)) \
        #$( 
        #set -x 
        #)\e[m > \e[0;93m


# Command grouping protects correct line numbers
{
  PS4="${close_ps4}"  lineno_PS4=$LINENO
  #PS4="$far_ps4"     lineno_PS4=$LINENO
}
set -x

echo foo
#echo zero: "$0"
#echo bar |
  #cat -Aen

#lsblk -O |
  #grep btrfs |
  #awk '{ print $10 }'

declare -p BASH_LINENO BASH_SOURCE FUNCNAME LINENO ii lineno_PS4 lineno_close_ps4_inside lineno_close_ps4_outside 
mercury
declare -p BASH_LINENO BASH_SOURCE FUNCNAME LINENO ii lineno_PS4 lineno_close_ps4_inside lineno_close_ps4_outside 

exit

