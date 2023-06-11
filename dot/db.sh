# Debugging

  #######################################
  # <> Obligatory debugging block
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x
  #######################################

## A function so `:` always prints to xtrace
#function :(){
  #local hyphen="$-";
  #set -x;
  #printf '%b\n' "$@" >&2;
  #[[ "$hyphen" =~ x ]] || set -;
#}; declare -fxt :

# Print a function trace stack, and capture the FN's LINENO on line 0
function _fn_trc(){ local ec="${nL:?}:$-"
  set -
  local hyphen="${ec#*:}"
  ec=${ec%:*}
  local i
  local -a ir
  mapfile -t ir < <(rev <<< "${!nBS[@]}" | tr ' ' '\n')
  for i in "${ir[@]}"; do
    printf '%s:%s:%s  ' "${nBS[$i+1]:-$0}" "${nBL[$i]:?}" "${nF[$i]:?}"
  done;
  echo "${nBS[0]:?}:${ec:?}:_fn_trc:${nL}"
  [[ "${hyphen:?}" =~ x ]] && set -x
}; declare -fxt _fn_trc

# shadow the `exit` builtin, for when debugging is turned off
function exit(){ 
  set -; 
  _fn_trc; 
  set -x; 
  builtin exit;
}; declare -fxt exit

#cp -a "${verb[@]}" ./README.md ./foo

  #type -a exit
  #_fn_trc
  #exit "${nL}"
  #set -x


: '<>: Debug functions & traps'

_trap_ctrl_C() {
  set -x
  trap - INT

  # remove all the current xtrace environment log files
  for f in "${xtr_time_f:?}" "${xtr_senv_prev:?}" \
    "${xtr_senv_now:?}" "${xtr_senv_delt:?}";
  do

    # as possible, add each to an array $rm_list
    if [[ -f "${f}" ]] && [[ ! -L "${f}" ]] && [[ -O "${f}" ]]; then
      rm_list+=("${f}")
    fi
  done; unset f xtr_time_f xtr_senv_prev xtr_senv_now xtr_senv_delt

  # if there are any files in array $rm_list, then remove then all at
  # once
  if [[ -n "${rm_list[*]:0:8}" ]]; then
    if ! rm -f ${verb} --one-file-system --preserve-root=all \
      -- "${rm_list[@]}";
    then
      _erx "unlink failed, line ${nL}"
    fi
  fi; unset rm_list

  # print a function trace (or two...)
  _fn_trc
  : "${nBS[0]}:${nL}:_trap_ctrl_C"

  # kill the script with INT
  command -p kill -s INT "$$"
}; declare -fxt _trap_ctrl_C

# redefine the INT trap
trap '_trap_ctrl_C' INT

  # <>
  #_fn_trc
  #set -x
  #sleep 10


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
    chmod ${verb} 000 "$f"
    xtr_rm_list+=("${f}")
  fi
done; unset f

# remove the $xtr_rm_list files all at once
if [[ -n "${xtr_rm_list[*]}" ]]; then
  rm -f ${verb} --one-file-system --preserve-root=all -- "${xtr_rm_list[@]}"
fi; unset xtr_rm_list xtr_files


  # <> Obligatory debugging block
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


: '<> Debug: "Full xTrace" variables and functions'

fn_lvl=0; fn_bndry=' +++ +++ +++ '

#   _xtrace_duck: If xtrace was previously on, then on first execution
# of this function, turn xrtrace off, and on second execution, turn
# xtrace back on and forget about this function's settings. If xtrace
# was previously off, then leave it off.

_xtrace_duck() {
  : '_xtrace_duck BEGINS' "$((++fn_lvl))" "${fn_bndry}"

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
  : '_xtrace_duck ENDS  ' "$((--fn_lvl))" "${fn_bndry}"
}; declare -ftx _xtrace_duck


#   Remaining functions: A set of functions for printing changes in
# shell variables and parameters between each execution of a command;
# for use when the DEBUG trap is enabled.

_mk_v_setenv_pre() {
  : '_mk_v_setenv_pre BEGINS' "$((++fn_lvl))" "${fn_bndry}"

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

  : '_mk_v_setenv_pre ENDS  ' "$((--fn_lvl))" "${fn_bndry}"
}; declare -ftx _mk_v_setenv_pre


_mk_v_setenv_novv() {
  : '_mk_v_setenv_novv BEGINS' "$((++fn_lvl))" "${fn_bndry}"

  # create 'now' file
  xtr_senv_now="$(mktemp -p /tmp --suffix=."${xtr_f_nm}")"

  # output data to new file
  set |& tee -- "${xtr_senv_now}" >/dev/null
  env |& tee -a -- "${xtr_senv_now}" >/dev/null

  : '_mk_v_setenv_novv ENDS  ' "$((--fn_lvl))" "${fn_bndry}"
}; declare -ftx _mk_v_setenv_novv


_mk_v_setenv_delta() {
  : '_mk_v_setenv_delta BEGINS' "$((++fn_lvl))" "${fn_bndry}"

  : 'if now and prev'
  if [[ -n "${xtr_senv_now}" ]] \
    && [[ -n "${xtr_senv_prev}" ]];
  then

    : 'if delta'
    if [[ -n "${xtr_senv_delt}" ]]; then

      # add the current delta data to the history thereof
      tee -a "${xtr_delta_sum_f}" < "${xtr_senv_delt}"

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

  : '_mk_v_setenv_delta ENDS  ' "$((--fn_lvl))" "${fn_bndry}"
}; declare -ftx _mk_v_setenv_delta


_mk_deltas() {
  : '_mk_deltas BEGINS' "$((++fn_lvl))" "${fn_bndry}"

  #_xtrace_duck
  _mk_v_setenv_pre
  _mk_v_setenv_novv
  _mk_v_setenv_delta
  #_xtrace_duck

  : '_mk_deltas ENDS  ' "$((--fn_lvl))" "${fn_bndry}"
}; declare -ftx _mk_deltas


_debug_prompt() {
  : '_debug_prompt BEGINS' "$((++fn_lvl))" "${fn_bndry}"

  _mk_deltas

  : '~~~ ~~ ~ PROMPT ~ ~~ ~~~'
  read -rp " +[${nBS[0]}:${nL}] ${BASH_COMMAND[0]}?" _

  : '_debug_prompt ENDS  ' "$((--fn_lvl))" "${fn_bndry}"
}; declare -ftx _debug_prompt


_full_xtrace() {
  : '_full_xtrace BEGINS' "$((++fn_lvl))" "${fn_bndry}"

  trap '_debug_prompt "$_";' DEBUG
  set -x

  : '_full_xtrace ENDS  ' "$((--fn_lvl))" "${fn_bndry}"
}; declare -ftx _full_xtrace


  # <> Obligatory debugging block
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


exit 00
