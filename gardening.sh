# Debugging
# shellcheck shell=bash


  # <> Obligatory debugging block
  _post_src "${nL}" "$@"
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


# Vars
# shellcheck disable=SC2016
#set -o functrace
FUNCNEST=32
close_ps4='\n\e[0;104m+[${#nBS[@]}]${nBS[0]##*/}(${nL}) [$((${#nBS[@]}-1))]${nBS[1]##*/}(${nBL[0]})${nF[0]} [$((${#nBS[@]}-2))]${nBS[2]##*/}(${nBL[1]})${nF[1]} [$((${#nBS[@]}-3))]${nBS[3]##*/}(${nBL[2]})${nF[2]} [$((${#nBS[@]}-4))]${nBS[4]##*/}(${nBL[3]})${nF[3]} \e[m\n    |=\t=|> \e[0;93m '

#far_ps4='\e[0;104m+[${#nBS[@]}]${nBS[0]##*/}(${nL}) [$((${#nBS[@]}-1))]${nBS[1]##*/}(${nBL[0]})|${nF[0]} \e[m > \e[0;93m '
#         ^color       ^fnlvl    ^sub-script   ^lineno     ^((fnlvl-1))  ^callerOprev  ^lineno   ^fn colo^r p^rompt ^color
#far_ps4='\e[0;104m+ <${nF[0]:0:8}> [${#nBS[@]}]${nBS[0]##*/}(${nL}) [$((${#nBS[@]}-1))]${nBS[1]##*/}(${nBL[0]}) \e[m > \e[0;93m '
#far_ps4='\e[0;104m+[${#nBS[@]}]${nBS[0]##*/}(${nL}) [$((${#nBS[@]}-1))]${nBS[1]##*/}(${nBL[0]}) <${nF[0]:0:8}> \e[m > \e[0;93m '
#far_ps4='\e[0;104m+[${#nBS[@]}]${nBS[0]##*/}(${nL}) <${nF[0]:0:8}> [$((${#nBS[@]}-1))]${nBS[1]##*/}(${nBL[0]}) \e[m > \e[0;93m '
far_ps4='\e[0;104m+At:[${#nBS[@]}]${nBS[0]##*/}(${nL}) In:<${nF[0]:0:8}> Fr:[$((${#nBS[@]}-1))]${nBS[1]##*/}(${nBL[0]}) \e[m > \e[0;93m '
PS4="${far_ps4}"
export FUNCNEST close_ps4 far_ps4 PS4


# Print a function trace stack, and capture the FN's LINENO on line 0
function _fun_trc(){ : "$_" 'BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"; local line_hyphen="${nL:?}:$-"
  set - # normally `set -`
  local line=${line_hyphen%:*}
  local hyphen="${line_hyphen#*:}"
  unset line_hyphen
  local i
  local -a ir # (indices reversed)
  mapfile -t ir < <(rev <<< "${!nBS[@]}" | tr ' ' '\n')
  for i in "${ir[@]}"; do
    printf '(-%d):%s:%s:%s  ' "${i}" "${nBS[$i+1]:-$0}" "${nBL[$i]:?}" \
      "${nF[$i]:?}"
  done;
  echo "(+1):${nBS[0]:?}:${line:?}:_fun_trc:${nL}"
  [[ "${hyphen:?}" =~ x ]] && set -x
  : '_fun_trc ENDS' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -fxt _fun_trc


: '<>: Debug functions & traps'

function exit { : "$_" 'BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  unset PS4
  printf '\e[m'
  builtin exit "${nL}";
}; declare -fxt exit



_trap_ctrl_C() { : "$_" 'BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  set -x
  trap - INT

  # remove all the current xtrace environment log files
  for f in "${xtr_time_f}" "${xtr_senv_prev}" \
    "${xtr_senv_now}" "${xtr_senv_delt}";
  do

    # as possible, add each to an array $rm_list
    if [[ -f "${f}" ]] && [[ ! -L "${f}" ]] && [[ -O "${f}" ]]; then
      rm_list+=("${f}")
    fi
  done; unset f xtr_time_f xtr_senv_prev xtr_senv_now xtr_senv_delt

  # if there are any files in array $rm_list, then remove then all at once
  if [[ -n "${rm_list[*]:0:8}" ]]; then
    if ! rm -f --one-file-system --preserve-root=all "${verb[@]}" "${rm_list[@]}";
    then
      _erx "unlink failed, line ${nL}"
    fi
  fi; unset rm_list

  # reset the terminal prompt color
  unset PS4
  printf '\e[m'
  
  # kill the script with INT
  command -p kill -s INT "$$"
  : '_trap_ctrl_C ENDS' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -fxt _trap_ctrl_C

# redefine the INT trap
trap ': "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"; 
      _trap_ctrl_C;
      : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"' INT



: '<> Delete any left over xtrace files from -mktemp -p /tmp-'

# Vars
xtr_time_f="/tmp/tmp.mtime_file.${rand_f_nm}"
xtr_delta_sum_f="$(mktemp -p /tmp --suffix=."${rand_f_nm}.E")"
export rand_f_nm xtr_time_f xtr_delta_sum_f
unset f xtr_rm_list xtr_files

# Create the xtrace time file
touch -d "${scr_max_age_of_tmp_files:?}" "${xtr_time_f}"

# Remove any errant xtrace log files

# Get the list of remaining xtrace log files (older than the time file)
mapfile -d '' -t xtr_files < <(
  find -P /tmp -maxdepth 1 -type f \
    -name "tmp.[a-zA-Z0-9]*.${scr_repo_nm:?}.[0-9]*.[0-9]*.xtr*" \
    '!' -newer "${xtr_time_f}" '!' -name "${xtr_time_f##*/}" -print0
)

# ...if they're (if inodes are) for files & not symlinks, & owned by
# the same EUID....
for f in "${xtr_files[@]}"; do
  if [[ -f "${f}" ]] && [[ ! -L "${f}" ]] && [[ -O "${f}" ]]; then

    # then protect them and add then to an array $xtr_rm_list
    chmod "${verb[@]}" 000 "$f"
    xtr_rm_list+=("${f}")
  fi
done; unset f

# remove the $xtr_rm_list files all at once
if [[ -n "${xtr_rm_list[*]}" ]]; then
  rm -f --one-file-system --preserve-root=all "${verb[@]}" "${xtr_rm_list[@]}"
fi; unset xtr_rm_list xtr_files


  # <> Obligatory debugging block
  #_full_xtrace
  #: "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x



: 'Some standard data- & file-maintenance functions' 
# Probably not nec in final script

fn_bak() { : "$_" 'BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  # for each of multiple input files
  for filename_a in "${@}"; do
    # test verifying existence of input
    if sudo /bin/test -f "${filename_a}"; then 

      # Bug: Why does this ^ test req sudo when this test \/ doesnt?
      # Requires use of fn_bak or fn_bak to debug this.
      # (~line 2000, 15 May)

      # if the destination (.bak) file already exists,
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
      sudo  rsync -acq -- "${filename_a}"{,.bak} \
        || _erx "${nL}"
    # if input file DNE, then print an error and exit
    else 
      {    
        echo WARNING: file DNE "${filename_a}"
        return
      }    
    fi   
  done 
  : 'fn_bak ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}

fn_write_arrays() { : "$_" 'BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  # Write each array to a file on disk.
  # Usage: fn_write_arrays [arrays]
  write_d_b="${curr_time_ssubd}arrays"
  if [[ ! -d "${write_d_b}" ]]; then
    sudo  mkdir -p -- "${write_d_b}" \
      || _erx "${nL}"
  fi
  # for each of multiple input array names
  for unquotd_array_nm_b in "${@}"; do
    # create local variables, for use as both array and string
    local -n nameref_b="${unquotd_array_nm_b}"
    array_nm="${unquotd_array_nm_b}"
    write_f_b="${write_d_b}/_${sc_sev_abrv}"
    write_f_b+="_${ABBREV_REL_SEARCH_DIRS}_${array_nm}"

    # Bug? When array correctly is empty: 'declare -p ... > /dev/null ||' ?
    # requires use of fn_write_arrays or fn_write_arrays to debug this.
    # (~line 2000, 15 May)

    # if the input array holds no data, then populate it
    if [[ ! -v nameref_b[@] ]]; then
      nameref_b=([0]='fn_write_arrays: Empty array')
    fi
    # then write a data file to disk
    declare -p "${array_nm}" \
      | sudo  tee --output-error=exit  -- "${write_f_b}" >/dev/null
    # write a backup of the new data file
    fn_bak "${write_f_b}"
  done
  : 'fn_write_arrays ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}



: '<> Debug: "Full xTrace" variables and functions'

fn_lvl=0; fn_bndry=' +++ +++ +++ '

#   _xtrace_duck: If xtrace was previously on, then on first execution
# of this function, turn xrtrace off, and on second execution, turn
# xtrace back on and forget about this function's settings. If xtrace
# was previously off, then leave it off.

# Error: the code is "$_" should point to _mk_v_setenv_pre, but instead, its still defined as _xtrace_duck
# +[5]gardening.sh(308) <_mk_delt> [4]gardening.sh(326)  >  : _xtrace_duck
# +[5]gardening.sh(310) <_mk_delt> [4]gardening.sh(326)  >  _mk_v_setenv_pre
# +[6]gardening.sh(247) <_mk_v_se> [5]gardening.sh(310)  >  : _xtrace_duck BEGINS ' +++ +++ +++ ' '3>4'
# +[6]gardening.sh(248) <_mk_v_se> [5]gardening.sh(310)  >  : 'if now file exists'
# +[6]gardening.sh(249) <_mk_v_se> [5]gardening.sh(310)  >  [[ -n '' ]]


_xtrace_duck() { : "$_" 'BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
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
    if [[ -n "${xtrace_prev}" ]]; then
      # ...then restore xtrace and unset the record of its state
      set -x
      unset xtrace_prev
    # but if xtrace is off and was previously off... (return).
    fi
  fi
  : '_xtrace_duck ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -ftx _xtrace_duck


#   Remaining functions: A set of functions for printing changes in
# shell variables and parameters between each execution of a command;
# for use when the DEBUG trap is enabled.
_mk_v_setenv_pre() { : "$_" 'BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  : 'if now file exists'
  if [[ -n "${xtr_senv_now}" ]]; then
    : 'if prev file exists'
    if [[ -n "${xtr_senv_prev}" ]]; then
      : 'remove prev file'
      unlink -- "${xtr_senv_prev}"
    fi
    # turn the "now" file into the "prev" file
    xtr_senv_prev="${xtr_senv_now}"
  fi
  : '_mk_v_setenv_pre ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -ftx _mk_v_setenv_pre


_mk_v_setenv_novv() {
  : "$_" 'BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  # create 'now' file
  xtr_senv_now="$(mktemp -p /tmp --suffix=."${rand_f_nm}")"
  # output data to new file
  set |& tee -- "${xtr_senv_now}" >/dev/null
  env |& tee -a -- "${xtr_senv_now}" >/dev/null
  : '_mk_v_setenv_novv ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -ftx _mk_v_setenv_novv


_mk_v_setenv_delta() { : "$_" 'BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  : 'if now and prev'
  if [[ -n "${xtr_senv_now}" ]] \
    && [[ -n "${xtr_senv_prev}" ]];
  then
    : 'if delta'
    if [[ -n "${xtr_senv_delt}" ]]; then
      # add the current delta data to the history thereof
      tee -a "${xtr_delta_sum_f}" < "${xtr_senv_delt}" > /dev/null
      # and unlink the current delta data file
      unlink -- "${xtr_senv_delt}"
    fi
    # create a new delta file, each time
    xtr_senv_delt="$(mktemp -p /tmp --suffix=."${rand_f_nm}.A")"
      # write the diff of the 'prev' and 'now' files to the new
      # 'delta' file
      diff --color=always --palette='ad=1;3;38;5;190:de=1;3;38;5;129' \
        --suppress-{common-lines,blank-empty} \
        "${xtr_senv_prev}" "${xtr_senv_now}" \
        |& tee -a "${xtr_senv_delt}"
    # set colors for `wc` output
    export GREP_COLORS='mt=01;101'
    wc "${xtr_senv_delt}" \
      | grep --color=always -E '.*'

    # reset colors for `grep` output
    export GREP_COLORS='mt=01;43'
  fi
  : '_mk_v_setenv_delta ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -ftx _mk_v_setenv_delta


_mk_deltas() { : "$_" 'BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  # Note: comment out `_xtrace_duck` with ':' (and not '#')
  : _xtrace_duck
  _mk_v_setenv_pre
  _mk_v_setenv_novv
  _mk_v_setenv_delta
  : _xtrace_duck
  : '_mk_deltas ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -ftx _mk_deltas


_debug_prompt() { : '_debug_prompt BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  echo 'ampersand, _debug_prompt:' "$@"
  local hyphen="$-"
  _mk_deltas
  : '                                ~~~ ~~ ~ PROMPT ~ ~~ ~~~'
  read -rp "R+[${nBS[0]}:${nL}]  |  ${BASH_COMMAND}?  |" _
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  [[ "${hyphen}" =~ x ]] && set -x
  : '_debug_prompt ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -ftx _debug_prompt


_full_xtrace() { : "$_" 'BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  # Bug? for the line numbers in _fun_trc to be correct, this `trap` 
  # command must have two separate command parsings on the same line.
  
  # Bug? within `trap`, the command after `_debug_prompt` has line number of 351 [trap(lineno)+1], even though both commands are on line 350.
  _fun_trc
  trap '_fun_trc; : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}  |  prints in underscore shell variable"; _debug_prompt "$_"; : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"' DEBUG; echo cmd after DEBUG trap, $LINENO
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}" # 
  set -x 
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  : '_full_xtrace ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -ftx _full_xtrace


  # <> Obligatory debugging block
  #declare -p FUNCNAME BASH_SOURCE LINENO BASH_LINENO
  _full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x

  # <>
  #sleep 3
  #exit 00
