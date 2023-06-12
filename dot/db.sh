# Debugging


  # <> Obligatory debugging block
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


# Vars
#set -o functrace
FUNCNEST=32
PS4='\n\e[0;104m+[${#nBS[@]}]${nBS[0]##*/}(${nL}) [$((${#nBS[@]}-1))]${nBS[1]##*/}(${nBL[0]})${nF[0]} [$((${#nBS[@]}-2))]${nBS[2]##*/}(${nBL[1]})${nF[1]} [$((${#nBS[@]}-3))]${nBS[3]##*/}(${nBL[2]})${nF[2]} [$((${#nBS[@]}-4))]${nBS[4]##*/}(${nBL[3]})${nF[3]} \e[m\n    |=\t=|> \e[0;93m '
export FUNCNEST PS4


# Print a function trace stack, and capture the FN's LINENO on line 0
function _fn_trc(){ local line_hyphen="${nL:?}:$-"
  : '_fn_trc BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
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
  echo "(+1):${nBS[0]:?}:${line:?}:_fn_trc:${nL}"
  [[ "${hyphen:?}" =~ x ]] && set -x
  : '_fn_trc ENDS' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -fxt _fn_trc

# shadow the `exit` builtin, for when debugging is turned off
function exit(){ local line="$1"
  : 'function exit BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  set -; 
  set -x; 
  
  # reset the terminal prompt color
  unset PS4
  printf '\e[m'
  
  builtin exit "${line}";
  : 'function exit ENDS' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -fxt exit


: '<>: Debug functions & traps'

_trap_ctrl_C() {
  : '_trap_ctrl_C BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
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
trap '_trap_ctrl_C' INT


: '<> Delete any left over xtrace files from -mktemp -p /tmp-'

# Vars
xtr_time_f="/tmp/tmp.mtime_file.${xtr_f_nm}"
xtr_delta_sum_f="$(mktemp -p /tmp --suffix=."${xtr_f_nm}.E")"
export xtr_f_nm xtr_time_f xtr_delta_sum_f
unset f xtr_rm_list xtr_files

# Create the xtrace time file
touch -d "${max_age_of_tmp_files:?}" "${xtr_time_f}"

# Remove any errant xtrace log files

# Get the list of remaining xtrace log files (older than the time file)
mapfile -d '' -t xtr_files < <(
  find -P /tmp -maxdepth 1 -type f \
    -name "tmp.[a-zA-Z0-9]*.${repo_nm:?}.[0-9]*.[0-9]*.xtr*" \
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


: '<> Debug: "Full xTrace" variables and functions'

fn_lvl=0; fn_bndry=' +++ +++ +++ '

#   _xtrace_duck: If xtrace was previously on, then on first execution
# of this function, turn xrtrace off, and on second execution, turn
# xtrace back on and forget about this function's settings. If xtrace
# was previously off, then leave it off.

_xtrace_duck() {
  : '_xtrace_duck BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"

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

_mk_v_setenv_pre() { 
  : '_mk_v_setenv_pre BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"

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
  : '_mk_v_setenv_novv BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"

  # create 'now' file
  xtr_senv_now="$(mktemp -p /tmp --suffix=."${xtr_f_nm}")"

  # output data to new file
  set |& tee -- "${xtr_senv_now}" >/dev/null
  env |& tee -a -- "${xtr_senv_now}" >/dev/null

  : '_mk_v_setenv_novv ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -ftx _mk_v_setenv_novv


_mk_v_setenv_delta() {
  : '_mk_v_setenv_delta BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"

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
    xtr_senv_delt="$(mktemp -p /tmp --suffix=."${xtr_f_nm}.A")"

      # write the diff of the 'prev' and 'now' files to the new
      # 'delta' file
      diff --color=always --palette='ad=1;3;38;5;190:de=1;3;38;5;129' \
        --suppress-{common-lines,blank-empty} \
        "${xtr_senv_prev}" "${xtr_senv_now}" \
        |& tee -a "${xtr_senv_delt}"

    # set colors for `wc` output
    export GREP_COLORS='mt=01;104'
    wc "${xtr_senv_delt}" \
      | grep --color=always -E '.*'

    # reset colors for `grep` output
    export GREP_COLORS='mt=01;43'
  fi

  : '_mk_v_setenv_delta ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -ftx _mk_v_setenv_delta


_mk_deltas() {
  : '_mk_deltas BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"

  #_xtrace_duck
  _mk_v_setenv_pre
  _mk_v_setenv_novv
  _mk_v_setenv_delta
  #_xtrace_duck

  : '_mk_deltas ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -ftx _mk_deltas


_debug_prompt() {
  : '_debug_prompt BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  local hyphen="$-"
  _mk_deltas
  : '                                ~~~ ~~ ~ PROMPT ~ ~~ ~~~'
  read -rp " +[${nBS[0]}:${nL}] ${BASH_COMMAND}?" _
  [[ "${hyphen}" =~ x ]] && set -x

  : '_debug_prompt ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -ftx _debug_prompt


_full_xtrace() {
  : '_full_xtrace BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"

  # Bug? for the line numbers in _fn_trace to be correct, this `trap` 
  # command must have two separate command parsings on the same line.
  trap '_debug_prompt "$_";' DEBUG; echo cmd after DEBUG trap, $LINENO
  set -x 

  : '_full_xtrace ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}; declare -ftx _full_xtrace


  # <> Obligatory debugging block
  #declare -p FUNCNAME BASH_SOURCE LINENO BASH_LINENO
  #_full_xtrace
  #: "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x
  sleep 3

exit 00
