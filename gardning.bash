#!/bin/bash
# Debugging
# shellcheck shell=bash

# put BEGINS and ENDS on same column


  # <> Obligatory debugging block
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  post_src "${nBS[0]}" "${nL}" "$@"
  #x_trace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


# Vars
# shellcheck disable=SC2016
#set -o functrace
FUNCNEST=32
# Note: the full -set -o functrace- cmd includes command substitutions 
# and subshells, so -- using CS-s in PROMPT vars messed up xtrace output

#close_ps4='\n\e[0;104m+[${#nBS[@]}]${nBS[0]##*/}( ${nL} ) [$(( ${#nBS[@]} - 1 ))]${nBS[1]##*/}( ${nBL[0]} )${nF[0]:-""} [$(( ${#nBS[@]} - 2 ))]${nBS[2]##*/}( ${nBL[1]} )${nF[1]} [$(( ${#nBS[@]} - 3 ))]${nBS[3]##*/}( ${nBL[2]} )${nF[2]} [$(( ${#nBS[@]} - 4 ))]${nBS[4]##*/}( ${nBL[3]} )${nF[3]} \e[m\n    |=\t=|> \e[0;93m '

#close_ps4='\n\e[0;104m+ $( II={#nBS[@]} for (( ii=0; ii<=II; ii++ )); do printf "[%d]%s( %d )%s " $(( II - ii )) "${nBS[ii+1]##*/}" "${nBL[ii]:-""}" "${nF[ii]:-""}"; done) \e[m\n    |=\t=|> \e[0;93m '
  

#far_ps4='\e[0;104m+ At:[${#nBS[@]}]${nBS[0]##*/}( ${nL} ) In:<${nF[0]:-""}> Fr:[$(( ${#nBS[@]} - 1 ))]${nBS[1]##*/}( ${nBL[0]} ) \e[m > \e[0;93m '
#far_ps4='\e[0;104m+ At:[${#nBS[@]}]$( cut -c -8 <<< ${nBS[0]##*/} )( ${nL} ) In:<${nF[0]:-""}> Fr:[$(( ${#nBS[@]} - 1 ))]${nBS[1]##*/}( ${nBL[0]} ) \e[m > \e[0;93m '
#far_ps4='\e[0;104m+ At:[${#nBS[@]}]$( cut -c -8 <<< ${nBS[0]##*/} )( ${nL} ) In:< $( cut -c -8 <<< ${nF[0]:-""} ) > Fr:[$(( ${#nBS[@]} - 1 ))]${nBS[1]##*/}( ${nBL[0]} ) \e[m > \e[0;93m '
#far_ps4='\e[0;104m+ At:[${#nBS[@]}]$( cut -c -8 <<< ${nBS[0]##*/} )( ${nL} ) In:<$( cut -c -8 <<< ${nF[0]:-""} )> Fr:[$(( ${#nBS[@]} - 1 ))]$( cut -c -8 <<< ${nBS[1]##*/} )( ${nBL[0]} ) \e[m > \e[0;93m '
#far_ps4='\e[0;104m+ At:[${#nBS[@]}]$( cut -c -8 <<< ${nBS[0]##*/} )(${nL}) In:<${nF[0]:-""}> Fr:[$(( ${#nBS[@]} - 1 ))]$( cut -d "/" -f 3- <<< ${nBS[1]:-" "} )(${nBL[0]}) \e[m > \e[0;93m '

# shellcheck disable=SC2089,SC2016 # 04 July 2023
far_ps4='\e[0;104m+ At:[$( printf "%2d" ${#nBS[@]} )]$( : 21594 )$( cut -c -8 <<< ${nBS[0]##*/} )($( printf "%4d" ${nL} )) In:<$( printf "%-8s" ${nF[0]:-""})> Fr:[$( printf "%2d" $(( ${#nBS[@]} - 1 )) )]$( cut -c -8 <<< ${nBS[1]##*/} )($( printf "%4d" ${nBL[0]} )) $( set -x )\e[m > \e[0;93m'

#PS4="${close_ps4}" export PS4
PS4="${far_ps4}" export PS4

# shellcheck disable=SC2090 # 04 July 2023
export FUNCNEST close_ps4 far_ps4 


: '<>: Debug functions & traps'

# Okay. At line with 22035, if xtrace and the DEBUG trap are turned 
# off, then the function trace prints without PS4, which is much easier 
# to read. 


# Print a function trace stack, and capture the FN's LINENO on line 0
function fun_trc(){ : "$_"'=?"fun_trc"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"; local line_hyphen="${nL:?}:$-"
  set - # normally set - # check number 22035
  local line=${line_hyphen%:*}
  local hyphen_sav="${line_hyphen#*:}"
  unset line_hyphen
  local ii
  local -a ir # indices reversed
  mapfile -t ir < <( rev <<< "${!nBS[@]}" | tr ' ' '\n') 
  for ii in "${ir[@]}"
  do
    printf '( -%d ):%s:%s:%s  ' "${ii}" "${nBS[$ii+1]:-$0}" "${nBL[$ii]:?}" "${nF[$ii]:?}"
  done
  unset ii ir
  echo "( +1 ):${nBS[0]:?}:${line:?}:fun_trc:${nL}"
  [[ "${hyphen_sav:?}" =~ x ]] && 
    set -x
  unset line hyphen_sav
  : 'fun_trc ENDS' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
export -f fun_trc
declare -ft fun_trc

function trp_int(){ : "$_"'=?"trp_int"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  set -x
  trap - INT

  # accommodating set -u
  local a_xtr_files=( xtr_time_f xtr_senv_prev xtr_senv_now xtr_senv_delt )
  for v in "${!a_xtr_files[@]}"
  do
    [[ ! -v "${a_xtr_files[v]}" ]] &&
      unset 'a_xtr_files[v]'
  done

  # remove all the current xtrace environment log files
  for v in "${!a_xtr_files[@]}"
  do
    local f="${!a_xtr_files[v]}"
  
    # as possible, add each to an array $rm_list
    if [[ -f "${f}" ]] && 
      [[ ! -L "${f}" ]] && 
      [[ -O "${f}" ]]
    then
      rm_list+=( "${f}" )
    fi
  done
  unset f xtr_time_f xtr_senv_prev xtr_senv_now xtr_senv_delt

  # if there are any files in array $rm_list, then remove then all at once
  if [[ -n "${rm_list[*]:0:1}" ]]
  then
    if ! rm -f --one-file-system --preserve-root=all "${verb[@]}" "${rm_list[@]}"
    then
      er_x "rm failed, line ${nL}"
    fi
  fi
  unset rm_list

  # reset the terminal prompt color
  unset PS4
  printf '\e[m'
  
  # kill the script with INT
  command -p kill -s INT "$$"
  : 'trp_int ENDS' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
export -f trp_int
declare -ft trp_int


# redefine the INT trap
trap ': "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"; trp_int; : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"' INT


: 'Some standard data- & file-maintenance functions' 
# Probably not nec in final script

function fun_bak(){ : "$_"'=?"fun_bak"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  # for each of multiple input files
  for filename_a in "${@}"; do
    # test verifying existence of input
    if sudo /bin/test -f "${filename_a}"; then 

      # Bug: Why does this ^ test req sudo when this test \/ doesnt?
      # Requires use of fun_bak or fun_bak to debug this.
      # -~line 2000, 15 May-

      # if the destination -.bak- file already exists,
      # then age it first.
      if [[ -f "${filename_a}.bak" ]]; then 
        if [[ -s "${filename_a}.bak" ]]; then 
          return
        else
          sudo  rm --one-file-system --preserve-root=all -f -- \
            "${filename_a}.bak"
        fi
      fi   
      # write a new .bak file
      sudo rsync -acq -- "${filename_a}"{,.bak} \
        || er_x "${nL}"
    # if input file DNE, then print an error and exit
    else 
      {    
        echo WARNING: file DNE "${filename_a}"
        return
      }    
    fi   
  done 
  : 'fun_bak ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}


function wrt_ary(){ : "$_"'=?"wrt_ary"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  # Write each array to a file on disk.
  # Usage: wrt_ary [arrays]
  write_d_b="${curr_time_ssubd}arrays"
  if [[ ! -d "${write_d_b}" ]]; then
    sudo mkdir -p -- "${write_d_b}" \
      || er_x "${nL}"
  fi
  # for each of multiple input array names
  for unquotd_array_nm_b in "${@}"; do
    # create local variables, for use as both array and string
    local -n nameref_b="${unquotd_array_nm_b}"
    array_nm="${unquotd_array_nm_b}"
    write_f_b="${write_d_b}/_${sc_sev_abrv}"
    write_f_b+="_${ABBREV_REL_SEARCH_DIRS}_${array_nm}"
    decl_o="$(
      declare -p "${array_nm}" 2>&1
      )"

    # Bug? When array correctly is empty: 'declare -p ... > ||' ?
    # requires use of wrt_ary or wrt_ary to debug this.
    # ~line 2000, 15 May-

    # if the input array holds no data, then populate it
    if [[ ! -v nameref_b[@] ]]; then
      nameref_b=( [0]='wrt_ary: Empty array' )
    fi
    # then write a data file to disk
    [[ -n "${decl_o}" ]] &&
      cat "${decl_o}" > "${write_f_b}" # stderr to console
    # write a backup of the new data file
    fun_bak "${write_f_b}"
  done
  : 'wrt_ary ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}



: '<> Debug: "Full xTrace" variables and functions'

#   xt_hush: If xtrace was previously on, then on first execution
# of this function, turn xrtrace off, and on second execution, turn
# xtrace back on and forget about this function's settings. If xtrace
# was previously off, then leave it off.

# Error: the variable "$_" should point to mkv_pre, but instead, its still defined as xt_hush
# +[5]gardening.sh(308) <_mk_delt> [4]gardening.sh(326)  >  : xt_hush
# +[5]gardening.sh(310) <_mk_delt> [4]gardening.sh(326)  >  mkv_pre
# +[6]gardening.sh(247) <_mk_v_se> [5]gardening.sh(310)  >  : xt_hush BEGINS ' +++ +++ +++ ' '3>4'
# +[6]gardening.sh(248) <_mk_v_se> [5]gardening.sh(310)  >  : 'if now file exists'
# +[6]gardening.sh(249) <_mk_v_se> [5]gardening.sh(310)  >  [[ -n '' ]]


function xt_hush(){ : "$_"'=?"xt_hush"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  # If xtrace is on...
  if [[ "$-" =~ x ]]; then
    # ...then record its state
    local -gx xtrace_prev
    # and turn xtrace off
    #set -
  # but if xtrace is off...
  else
    # ...then if xtrace was previously on...
    : 'if prev'
    if [[ -v xtrace_prev ]]; then
      # ...then restore xtrace and unset the record of its state
      set -x
      unset xtrace_prev
    # but if xtrace is off and was previously off... -return-.
    fi
  fi
  : 'xt_hush ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
export -f xt_hush
declare -ft xt_hush


#   Remaining functions: A set of functions for printing changes in
# shell variables and parameters between each execution of a command;
# for use when the DEBUG trap is enabled.
function mkv_pre(){ : "$_"'=?"mkv_pre"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  : 'if now-file exists'
  if [[ -v xtr_senv_now ]]; then
    : 'if prev file exists'
    if [[ -v xtr_senv_prev ]]; then
      : 'remove prev file'
      sync -f
      unlink -- "${xtr_senv_prev}"
      sync -f
      wait -f
    fi
    # turn the "now" file into the "prev" file
    xtr_senv_prev="${xtr_senv_now}"
  fi
  : 'mkv_pre ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
export -f mkv_pre
declare -ft mkv_pre


function mkv_now(){ : "$_"'=?"mkv_now"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  
  # create 'now' file
  xtr_senv_now="$(
    mktemp -p /tmp --suffix=."${rand_f_nm}" 2>&1
    )"
  
  # output data to new file
  set >> "${xtr_senv_now}" # stderr to term
  env >> "${xtr_senv_now}" # stderr to term
  : 'mkv_now ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
export -f mkv_now
declare -ft mkv_now


function mkv_dlt(){ : "$_"'=?"mkv_dlt"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  : 'if now and prev'
  if [[ -n "${xtr_senv_now}" ]] \
    && [[ -v xtr_senv_prev ]];
  then
    : 'if delta'
    if [[ -v xtr_senv_delt ]]; then
      
      # add the current delta data to the history thereof
      cat "${xtr_senv_delt}" >> "${xtr_delta_sum_f}" # stderr to term
      
      # and unlink the current delta data file
      sync -f
      unlink -- "${xtr_senv_delt}"
      sync -f
      wait -f
    fi
    
    # create a new delta file, each time
    xtr_senv_delt="$(
      mktemp -p /tmp --suffix=."${rand_f_nm}.A" 2>&1
      )"
      
      # write the diff of the 'prev' and 'now' files to the new 'delta' file
      diff --color=always --palette='ad=1;3;38;5;190:de=1;3;38;5;129' --suppress-{common-lines,blank-empty} "${xtr_senv_prev}" "${xtr_senv_now}" >> "${xtr_senv_delt}"
   
    # Keep this section 
    # set colors for wc output
    #GREP_COLORS='mt=01;101' export GREP_COLORS
    #wc "${xtr_senv_delt}" | grep --color=always -E '.*'
    #GREP_COLORS='' export GREP_COLORS
    #printf '\e[m'
    # reset colors for grep output
    #GREP_COLORS='mt=01;43' export GREP_COLORS
    #grep --color=always -E '.*' < "${xtr_senv_delt}"
    sudo cat "${xtr_senv_delt}"
  fi

  : 'mkv_dlt ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
export -f mkv_dlt
declare -ft mkv_dlt


function mk_dlts(){ : "$_"'=?"mk_dlts"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  
  # Note: comment out xt_hush with : -and not #-
  : xt_hush
  mkv_pre
  mkv_now
  mkv_dlt
  : xt_hush
  
  : 'mk_dlts ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
export -f mk_dlts
declare -ft mk_dlts


function dbg_pmt(){ : 'dbg_pmt BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"

  echo dbg_pmt  
  fun_trc
  #echo 'ampersand, dbg_pmt:' "$@"
  local hyphen_sav="$-"
  
  mk_dlts
  
  : '                                                           ~~~ ~~ ~ PROMPT ~ ~~ ~~~'
  read -rp "R+ [${nBS[1]}:${nBL[0]}]  |  ${BASH_COMMAND}?  |: "$'\n' _
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  
  [[ "${hyphen_sav}" =~ x ]] && set -x

  : 'dbg_pmt ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
export -f dbg_pmt
declare -ft dbg_pmt


# Bug? for the line numbers in fun_trc to be correct, this trap
# command must have two separate command parsings on the same line.

# Bug? within trap, the command after dbg_pmt has line number of 351 [trap(lineno)+1], even though both commands are on line 350.

function x_trace(){ : "$_"'=?"x_trace"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  
  fun_trc
  set -x 16074
  
  # PIUSV = "Prints In Underscore Shell Variable"
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}, 28666"
  trap 'echo DEBUG trap 30013; fun_trc; : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}  |  PIUSV"; dbg_pmt "$_"; : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"' DEBUG
    echo cmd after DEBUG trap, "$LINENO", 5741
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}, 21506"
  
  : 'x_trace ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl )), 26149"
}
export -f x_trace
declare -ft x_trace
fun_trc



: '<> Delete any left over xtrace files from -mktemp -p /tmp-'

# Vars
xtr_time_f="/tmp/tmp.mtime_file.${rand_f_nm}"
xtr_delta_sum_f="$(
  mktemp -p /tmp --suffix=."${rand_f_nm}.E" 2>&1
  )"
export rand_f_nm xtr_time_f xtr_delta_sum_f
unset f xtr_rm_list xtr_files

# Create the xtrace time file
touch -d "${scr_max_age_of_tmp_files:?}" "${xtr_time_f}"

# Remove any errant xtrace log files

if [[ -v rm_stale ]]
then
  # Get the list of remaining xtrace log files -older than the time file-
  mapfile -d '' -t xtr_files < <(
    find -P /tmp -maxdepth 1 -type f -user "${UID}" \
      -name "tmp.[a-zA-Z0-9]*.${scr_repo_nm:?}.[0-9]*.[0-9]*.xtr*" \
      '!' -newer "${xtr_time_f}" '!' -name "${xtr_time_f##*/}" -print0
    )

  # ...if they're -if inodes are- for files & not symlinks, & owned by
  # the same EUID.... (also, I clearly don't trust my computer... ;-p )
  for f in "${xtr_files[@]}"; do
    if [[ -f "${f}" ]] && [[ ! -L "${f}" ]] && [[ -O "${f}" ]]; then

      # then protect them and add then to an array $xtr_rm_list
      chmod "${verb[@]}" 000 "$f" ||
	      er_x "${nL}" "$f"
      xtr_rm_list+=( "${f}" )
    fi
  done
  unset f
fi

# remove the $xtr_rm_list files all at once
if [[ -n "${xtr_rm_list[*]:0:1}" ]]; then
  rm -f --one-file-system --preserve-root=all "${verb[@]}" "${xtr_rm_list[@]}" ||
    er_x "${nL}"
fi
unset xtr_rm_list xtr_files



  # <> Obligatory debugging block
  #declare -p FUNCNAME BASH_SOURCE LINENO BASH_LINENO 
  #trap 'declare -p FUNCNAME BASH_SOURCE LINENO BASH_LINENO' EXIT
  #caller
  x_trace 3580
  : 31722
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x

  # <>
  #sleep 3
  exit 101

