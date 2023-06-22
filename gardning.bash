#!/bin/bash
# Debugging
# shellcheck shell=bash


  # <> Obligatory debugging block
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  _post_src "${nBS[0]}" "${nL}" "$@"
  #_xtrace_
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


# Vars
# shellcheck disable=SC2016
#set -o functrace
FUNCNEST=32
# Note: the full -set -o functrace- cmd includes command substitutions 
# and subshells, so -- using CS-s in PROMPT vars messed up xtrace output
close_ps4='\n\e[0;104m+[${#nBS[@]}]${nBS[0]##*/}( ${nL} ) [$(( ${#nBS[@]} - 1 ))]${nBS[1]##*/}( ${nBL[0]} )${nF[0]} [$(( ${#nBS[@]} - 2 ))]${nBS[2]##*/}( ${nBL[1]} )${nF[1]} [$(( ${#nBS[@]} - 3 ))]${nBS[3]##*/}( ${nBL[2]} )${nF[2]} [$(( ${#nBS[@]} - 4 ))]${nBS[4]##*/}( ${nBL[3]} )${nF[3]} \e[m\n    |=\t=|> \e[0;93m '
#far_ps4='\e[0;104m+ At:[${#nBS[@]}]${nBS[0]##*/}( ${nL} ) In:<${nF[0]:-""}> Fr:[$(( ${#nBS[@]} - 1 ))]${nBS[1]##*/}( ${nBL[0]} ) \e[m > \e[0;93m '
#far_ps4='\e[0;104m+ At:[${#nBS[@]}]$( cut -c -8 <<< ${nBS[0]##*/} )( ${nL} ) In:<${nF[0]:-""}> Fr:[$(( ${#nBS[@]} - 1 ))]${nBS[1]##*/}( ${nBL[0]} ) \e[m > \e[0;93m '
far_ps4='\e[0;104m+ At:[${#nBS[@]}]$( cut -c -8 <<< ${nBS[0]##*/} )( ${nL} ) In:< $( cut -c -8 <<< ${nF[0]:-""} ) > Fr:[$(( ${#nBS[@]} - 1 ))]${nBS[1]##*/}( ${nBL[0]} ) \e[m > \e[0;93m '
#far_ps4='\e[0;104m+ At:[${#nBS[@]}]$( cut -c -8 <<< ${nBS[0]##*/} )( ${nL} ) In:<$( cut -c -8 <<< ${nF[0]:-""} )> Fr:[$(( ${#nBS[@]} - 1 ))]$( cut -c -8 <<< ${nBS[1]##*/} )( ${nBL[0]} ) \e[m > \e[0;93m '
PS4="${far_ps4}" export PS4
export FUNCNEST close_ps4 far_ps4 


: '<>: Debug functions & traps'

# Print a function trace stack, and capture the FN's LINENO on line 0
function _fun_trc { : "$_"'=?"_fun_trc"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"; local line_hyphen="${nL:?}:$-"
  #set - # normally set -
  local line=${line_hyphen%:*}
  local hyphen="${line_hyphen#*:}"
  unset line_hyphen
  local i
  local -a ir # indices reversed
  mapfile -t ir < <(
    rev <<< "${!nBS[@]}" | 
    tr ' ' '\n'
    )
  for i in "${ir[@]}"
  do
    printf '( -%d ):%s:%s:%s  ' "${i}" "${nBS[$i+1]:-$0}" "${nBL[$i]:?}" \
      "${nF[$i]:?}"
  done
  echo "( +1 ):${nBS[0]:?}:${line:?}:_fun_trc:${nL}"
  [[ "${hyphen:?}" =~ x ]] && 
    set -x
  : '_fun_trc ENDS' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
declare -fx _fun_trc
declare -t _fun_trc


# 'exit' function: name is intended, at global scope, to supercede builtin
function exit { : "$_"'=?"exit"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  unset PS4
  printf '\e[m'
  builtin exit "${nL}"
}
declare -fx exit
declare -t exit



function _trp_int { : "$_"'=?"_trp_int"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
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
  if [[ -n "${rm_list[*]:0:8}" ]]
  then
    if ! rm -f --one-file-system --preserve-root=all "${verb[@]}" "${rm_list[@]}"
    then
      _erx "rm failed, line ${nL}"
    fi
  fi
  unset rm_list

  # reset the terminal prompt color
  unset PS4
  printf '\e[m'
  
  # kill the script with INT
  command -p kill -s INT "$$"
  : '_trp_int ENDS' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
declare -fx _trp_int
declare -t _trp_int


# redefine the INT trap
trap ': "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"; _trp_int; : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"' INT


: 'Some standard data- & file-maintenance functions' 
# Probably not nec in final script

function _fun_bak { : "$_"'=?"_fun_bak"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  # for each of multiple input files
  for filename_a in "${@}"; do
    # test verifying existence of input
    if sudo /bin/test -f "${filename_a}"; then 

      # Bug: Why does this ^ test req sudo when this test \/ doesnt?
      # Requires use of _fun_bak or _fun_bak to debug this.
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
        || _erx "${nL}"
    # if input file DNE, then print an error and exit
    else 
      {    
        echo WARNING: file DNE "${filename_a}"
        return
      }    
    fi   
  done 
  : '_fun_bak ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}


function _wrt_ary { : "$_"'=?"_wrt_ary"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  # Write each array to a file on disk.
  # Usage: _wrt_ary [arrays]
  write_d_b="${curr_time_ssubd}arrays"
  if [[ ! -d "${write_d_b}" ]]; then
    sudo mkdir -p -- "${write_d_b}" \
      || _erx "${nL}"
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
    # requires use of _wrt_ary or _wrt_ary to debug this.
    # ~line 2000, 15 May-

    # if the input array holds no data, then populate it
    if [[ ! -v nameref_b[@] ]]; then
      nameref_b=( [0]='_wrt_ary: Empty array' )
    fi
    # then write a data file to disk
    [[ -n "${decl_o}" ]] &&
      cat "${decl_o}" > "${write_f_b}" # stderr to console
    # write a backup of the new data file
    _fun_bak "${write_f_b}"
  done
  : '_wrt_ary ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}



: '<> Debug: "Full xTrace" variables and functions'

#   _xtr_hsh: If xtrace was previously on, then on first execution
# of this function, turn xrtrace off, and on second execution, turn
# xtrace back on and forget about this function's settings. If xtrace
# was previously off, then leave it off.

# Error: the code is "$_" should point to _mkv_pre, but instead, its still defined as _xtr_hsh
# +[5]gardening.sh(308) <_mk_delt> [4]gardening.sh(326)  >  : _xtr_hsh
# +[5]gardening.sh(310) <_mk_delt> [4]gardening.sh(326)  >  _mkv_pre
# +[6]gardening.sh(247) <_mk_v_se> [5]gardening.sh(310)  >  : _xtr_hsh BEGINS ' +++ +++ +++ ' '3>4'
# +[6]gardening.sh(248) <_mk_v_se> [5]gardening.sh(310)  >  : 'if now file exists'
# +[6]gardening.sh(249) <_mk_v_se> [5]gardening.sh(310)  >  [[ -n '' ]]


function _xtr_hsh { : "$_"'=?"_xtr_hsh"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  # If xtrace is on...
  if [[ "$-" =~ x ]]; then
    # ...then record its state
    local -gx xtrace_prev
    # and turn xtrace off
    set -
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
  : '_xtr_hsh ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
declare -fx _xtr_hsh
declare -t _xtr_hsh


#   Remaining functions: A set of functions for printing changes in
# shell variables and parameters between each execution of a command;
# for use when the DEBUG trap is enabled.
function _mkv_pre { : "$_"'=?"_mkv_pre"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  : 'if now file exists'
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
  : '_mkv_pre ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
declare -fx _mkv_pre
declare -t _mkv_pre


function _mkv_now { : "$_"'=?"_mkv_now"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  
  # create 'now' file
  xtr_senv_now="$(
    mktemp -p /tmp --suffix=."${rand_f_nm}" 2>&1
    )"
  
  # output data to new file
  set >> "${xtr_senv_now}" # stderr to term
  env >> "${xtr_senv_now}" # stderr to term
  : '_mkv_now ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
declare -fx _mkv_now
declare -t _mkv_now


function _mkv_dlt { : "$_"'=?"_mkv_dlt"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
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

  : '_mkv_dlt ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
declare -fx _mkv_dlt
declare -t _mkv_dlt


function _mk_dlts { : "$_"'=?"_mk_dlts"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  
  # Note: comment out _xtr_hsh with : -and not #-
  : _xtr_hsh
  _mkv_pre
  _mkv_now
  _mkv_dlt
  : _xtr_hsh
  
  : '_mk_dlts ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
declare -fx _mk_dlts
declare -t _mk_dlts


function _dbg_pmt { : '_dbg_pmt BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"

  echo _dbg_pmt  
  _fun_trc
  #echo 'ampersand, _dbg_pmt:' "$@"
  local hyphen="$-"
  
  _mk_dlts
  
  : '                                                           ~~~ ~~ ~ PROMPT ~ ~~ ~~~'
  read -rp "R+ [${nBS[1]}:${nBL[0]}]  |  ${BASH_COMMAND}?  |: " _
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  
  [[ "${hyphen}" =~ x ]] && set -x
  
  : '_dbg_pmt ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl ))"
}
declare -fx _dbg_pmt
declare -t _dbg_pmt


# Bug? for the line numbers in _fun_trc to be correct, this trap
# command must have two separate command parsings on the same line.

# Bug? within trap, the command after _dbg_pmt has line number of 351 [trap(lineno)+1], even though both commands are on line 350.

function _xtrace_ { : "$_"'=?"_xtrace_"' 'BEGINS' "${fn_bndry}" "${fn_lvl}>$(( ++fn_lvl ))"
  
  #_fun_trc
  #set -x 16074
  
  # PIUSV = "Prints In Underscore Shell Variable"
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}, 28666"
  trap 'echo DEBUG trap; _fun_trc; : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}  |  PIUSV"; _dbg_pmt "$_"; : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"' DEBUG; 
    echo cmd after DEBUG trap, $LINENO, 5741
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}, 21506"
  
  : '_xtrace_ ENDS  ' "${fn_bndry}" "${fn_lvl}>$(( --fn_lvl )), 26149"
}
declare -fx _xtrace_
declare -t _xtrace_




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

# Get the list of remaining xtrace log files -older than the time file-
mapfile -d '' -t xtr_files < <(
  find -P /tmp -maxdepth 1 -type f \
    -name "tmp.[a-zA-Z0-9]*.${scr_repo_nm:?}.[0-9]*.[0-9]*.xtr*" \
    '!' -newer "${xtr_time_f}" '!' -name "${xtr_time_f##*/}" -print0
  )

# ...if they're -if inodes are- for files & not symlinks, & owned by
# the same EUID....
for f in "${xtr_files[@]}"; do
  if [[ -f "${f}" ]] && [[ ! -L "${f}" ]] && [[ -O "${f}" ]]; then

    # then protect them and add then to an array $xtr_rm_list
    chmod "${verb[@]}" 000 "$f" ||
	  _erx "${nL}" "$f"
    xtr_rm_list+=( "${f}" )
  fi
done
unset f

# remove the $xtr_rm_list files all at once
if [[ -n "${xtr_rm_list[*]:0:8}" ]]; then
  rm -f --one-file-system --preserve-root=all "${verb[@]}" "${xtr_rm_list[@]}" ||
    _erx "${nL}"
fi
unset xtr_rm_list xtr_files



  # <> Obligatory debugging block
  #declare -p FUNCNAME BASH_SOURCE LINENO BASH_LINENO 
  #trap 'declare -p FUNCNAME BASH_SOURCE LINENO BASH_LINENO' EXIT
  #caller
  _xtrace_ 3580
  : 31722
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x

  # <>
  #sleep 3
  exit 101