#!/bin/bash
# shellcheck disable=SC2034,SC2016

fn_bndry=' ~~~ ~~~ ~~~ '
fn_lvl=0
export fn_lvl fn_bndry

# 'exit' function: name is intended, at global scope, to supercede builtin
# shellcheck disable=SC2317
function exit() { : "$_"'=?"exit"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  unset PS4
  printf '\e[m'
  builtin exit "${LINENO}"
}
declare -fx exit
declare -t exit

# Note: Location of colon (`:`) commands protects line numbers
function mercury() { :
  echo 'count, nBS:' "${#BASH_SOURCE[@]}"
  declare -p BASH_SOURCE BASH_LINENO FUNCNAME LINENO
  venus
}
function venus() { :
  echo 'count, nBS:' "${#BASH_SOURCE[@]}"
  declare -p BASH_SOURCE BASH_LINENO FUNCNAME LINENO
  earth
}
function earth() { :
  set -x
  echo 'count, nBS:' "${#BASH_SOURCE[@]}"
  declare -p BASH_SOURCE BASH_LINENO FUNCNAME LINENO
  mars
}
function mars() { :
  echo 'count, nBS:' "${#BASH_SOURCE[@]}"
  declare -p BASH_SOURCE BASH_LINENO FUNCNAME LINENO
}
declare -fx mercury venus earth mars
declare -t mercury
declare -t venus
declare -t earth
declare -t mars

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

{
  lineno_far_ps4_outside=$(( LINENO + 1 )) export lineno_far_ps4_outside
  far_ps4='\e[0;104m+ $(
    unset inside_line_dist_a lineno_far_ps4_inside bash_source_0 ii bash_source_count bash_source_ii func_array
    inside_line_dist_a=4 export inside_line_dist_a ;
    lineno_far_ps4_inside=$(( LINENO - inside_line_dist_a )) export lineno_far_ps4_inside ;
    lineno_far_ps4_ext_cmd=$(( lineno_far_ps4_inside + 1 )) export lineno_far_ps4_ext_cmd ;

    bash_source_0=${BASH_SOURCE[0]##*/} ;
    printf "[%2d]" ${#BASH_SOURCE[@]} ;
    printf "%s" "${bash_source_0:0:8}" ;
    printf "(%4d)" $lineno_far_ps4_ext_cmd ;
    
    if [[ ${#FUNCNAME[@]} -ne 0 ]] ;
    then

      I="${#BASH_SOURCE[@]}" ; 
      for (( i=I-1; i>=0; i-- )) ; 
      do 
        ir+=("$i") ; 
      done ;
      unset I i 

      for ii in "${!FUNCNAME[@]}" ;
      do
        bash_source_count=$(( ${#BASH_SOURCE[ii]} - 1 )) export bash_source_count ;
        bash_source_ii=${BASH_SOURCE[ii]##*/} export bash_source_ii ;
        
        func_array+=( [$ii]+="$( printf "In:<%-8s> " ${FUNCNAME[$ii]} )" ) ;
        func_array+=( [$ii]+="$( printf "Fr:[%2d]" ${bash_source_count} )" ) ;
        func_array+=( [$ii]+="$( printf "%s" "${bash_source_ii:0:8}" )" ) ;
        func_array+=( [$ii]+="$( printf "(%4d)" ${BASH_LINENO[ii]} )" ) ;
      done
      printf "%s " "${func_array[@]}"
    fi ;
    
    unset inside_line_dist_a lineno_far_ps4_inside bash_source_0 ii bash_source_count bash_source_ii func_array
  )\e[m > \e[0;93m'
}

# Bug: a `declare` in the prompt variable seems to affect the LINENO var. also an `echo`.

{
  lineno_close_ps4_outside=$(( LINENO + 1 ))
  close_ps4='\e[0;104m+ $(
    unset inside_line_dist_a lineno_close_ps4_inside bash_source_0 ii bash_source_count bash_source_ii func_array
    inside_line_dist_a=4 export inside_line_dist_a ;
    lineno_close_ps4_inside=$(( LINENO - inside_line_dist_a )) export lineno_close_ps4_inside ;
    lineno_close_ps4_ext_cmd=$(( lineno_close_ps4_inside + 1 )) export lineno_close_ps4_ext_cmd ;
    
    bash_source_0=${BASH_SOURCE[0]##*/} ;
    printf "[%2d]" ${#BASH_SOURCE[@]} ;
    printf "%s" "${bash_source_0:0:8}" ;
    printf "(%4d) " $lineno_close_ps4_ext_cmd ;
    
    if [[ ${#FUNCNAME[@]} -ne 0 ]] ;
    then

      I="${#BASH_SOURCE[@]}" ; 
      for (( i=I-1; i>=0; i-- )) ; 
      do 
        ir+=("$i") ; 
      done ;
      unset I i 

      for ii in "${!ir[@]}" ;
      do
        if [[ ${ir[ii]} -ne 0 ]] ; 
        then
          BASH_SOURCE_ii=${BASH_SOURCE[ii]##*/} export ir_ii ;
        
          func_array+=( [$ii]+="$( printf "In:<%-8s> " ${FUNCNAME[$ii]} )" ) ;
          func_array+=( [$ii]+="$( printf "Fr:[%2d]" ${ir[ii]} )" ) ;
          func_array+=( [$ii]+="$( printf "%s" "${BASH_SOURCE_ii:0:8}" )" ) ;
          func_array+=( [$ii]+="$( printf "(%4d)" ${BASH_LINENO[ii]} )" ) ;
        fi
      done
      printf "%s " "${func_array[@]}"
    fi ;
    unset inside_line_dist_a lineno_close_ps4_inside bash_source_0 ii bash_source_ii func_array

    # PS4-trace section
    unset ii d3 d5 d7 s4 s6 ;
    ii=0 ;
    d5="${lineno_PS4}" ;

    # name of this function; a string
    s6=close_ps4 ;
    d7="${lineno_close_ps4_outside}" ;

    # a string
    s4=PS4 ;
    printf "PS4(%d)%s(%d) " "${d5}" "${s6}" "${d7}" ;
    unset ii d3 d5 d7 s4 s6 ;

  )\e[m > \e[0;93m'
}

# Command grouping protects correct line numbers
{
  #PS4="${close_ps4}"  lineno_PS4=$LINENO
  PS4="$far_ps4"      lineno_PS4=$LINENO
}
#set -x

#declare -p BASH_LINENO BASH_SOURCE FUNCNAME LINENO lineno_PS4 lineno_close_ps4_outside 
#echo foo
#echo zero: "$0"
#echo bar |
  #cat -Aen
#lsblk -O |
  #grep btrfs |
  #awk '{ print $10 }'

declare -p BASH_LINENO BASH_SOURCE FUNCNAME LINENO lineno_PS4 lineno_close_ps4_outside 
mercury

#declare -p BASH_LINENO BASH_SOURCE FUNCNAME LINENO lineno_PS4 lineno_close_ps4_outside 

exit 00

