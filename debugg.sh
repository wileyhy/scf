# debug.sh

: '<> Debugging' 
# "<>" means, "This is a debugging section."

xtr_f_nm="${unique_str}.xtr"
xtr_time_f="/tmp/tmp.mtime_file.${xtr_f_nm}"
delta_sum_f="$(mktemp -p /tmp --suffix=."${xtr_f_nm}.E")"

_ctrl_C_trap() {
  set -x
  trap - INT
  for f in "${xtr_time_f}" "${setenv_prev}" \
    "${setenv_now}" "${setenv_delta}"; 
  do
    if [[ -f "$f" ]]; then
      if ! rm --one-file-system --preserve-root=all  "$f"; then 
          echo rm failed -- "$f" -- line "${LINENO}"
          #"${Halt:?}"
      fi
    fi
  done
  kill -s INT "$$"
}

trap '_ctrl_C_trap' INT
#sleep 10
:;: "${BASH_SOURCE[0]}:${LINENO} ${BASH_SOURCE[1]}:${BASH_LINENO[0]}";:
#exit "${LINENO}"
#set -x

: '<> Debug: Delete any left over xtrace files from -mktemp -p /tmp-'
# Note:   Using '/tmp' at this "stage" because it's just easier
touch -d "${max_age_of_tmp_files}" "${xtr_time_f}"

mapfile -d '' -t xtrace_files < <(
  find /tmp -maxdepth 1 -type f \
    -name "tmp.[a-zA-Z0-9]*.${repo_nm}.[0-9]*.[0-9]*.xtr*" \
    '!' -newer "${xtr_time_f}" '!' -name "${xtr_time_f##*/}" -print0 
)

# ...if they're (inodes are for) files & not symlinks, & owned by the 
# same EUID.
for f in "${xtrace_files[@]}"; do
  if [[ -f "${f}" ]] \
    && [[ ! -L "${f}" ]] \
    && [[ -O "${f}" ]];
  then
    rm --one-file-system --preserve-root=all  "$f"
  fi
done && unset f
:;: "${BASH_SOURCE[0]}:${LINENO} ${BASH_SOURCE[1]}:${BASH_LINENO[0]}";:
#exit "${LINENO}"
set -x

: '<> Debug: XTrace variables and functions'
funclvl=0
fence=' ++++++++++++++++++++++++++++++++++++++++++++ '

#   _xtrace_duck: If xtrace was previously on, then on first execution 
# of this function, turn xrtrace off, and on second execution, turn 
# xtrace back on and forget about this function's settings. If xtrace 
# was previously off, then leave it off.
_xtrace_duck() {
  : '_xtrace_duck BEGINS' "$((++funclvl))" "${fence}"
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
  : '_xtrace_duck ENDS  ' "$((--funclvl))" "${fence}"
}

# A set of functions for printing changes in shell variables and para-
# meters between each execution of a command; for use when the DEBUG
# trap is enabled.
_mk_setenv_prev() {
  : '_mk_setenv_prev BEGINS' "$((++funclvl))" "${fence}"
  : 'if now'
  if [[ -n "${setenv_now}" ]]; then
    : 'if prev'
    if [[ -n "${setenv_prev}" ]]; then
      rm --one-file-system --preserve-root=all  -f -- "${setenv_prev}"
    fi
    setenv_prev="${setenv_now}"
  fi
  : '_mk_setenv_prev ENDS  ' "$((--funclvl))" "${fence}"
}
_mk_setenv_now() {
  : '_mk_setenv_now BEGINS' "$((++funclvl))" "${fence}"
  # work on printing function trace stack
  for i in "${!n[@]}"; do 
    caller "$i"
  done
  set -- "${!n[@]}"
  for i; do 
    : $'\t\t\t\t'"${i}"$'\t'"${BASH_LINENO[$i]}"$'\t'"${FUNCNAME[$i]}"$'\t'"${BASH_SOURCE[$i+1]} lineno-array-index"
  done
  ${Halt:?}

  setenv_now="$(mktemp -p /tmp --suffix=."${xtr_f_nm}")"
    # `{ set; env;} | tee`: env & set dont print in simple xtrace 
    set \
      |& tee -- "${setenv_now}" >/dev/null 
    env \
      |& tee -a -- "${setenv_now}" >/dev/null
  : '_mk_setenv_now ENDS  ' "$((--funclvl))" "${fence}"
}
_mk_setenv_delta() {
  : '_mk_setenv_delta BEGINS' "$((++funclvl))" "${fence}"
  : 'if now and prev'
  if [[ -n "${setenv_now}" ]] \
    && [[ -n "${setenv_prev}" ]]; 
  then
    : 'if delta'
    if [[ -n "${setenv_delta}" ]]; then
      tee -a "${delta_sum_f}" < "${setenv_delta}"
      rm --one-file-system --preserve-root=all  -f -- "${setenv_delta}"
      wait -f
    fi

		# syntax caused a weird bug?
		# 	with alsa-info.sh line ~465-466
		#	and then again 
        ## create a new delta file, each time
    #setenv_delta="$(mktemp -p /tmp --suffix=."${xtr_f_nm}")" #
    #{
      #diff -y --suppress-{common-lines,blank-empty} --color=never \
        #"${setenv_prev}" "${setenv_now}" \
        #|& grep -v setenv \
        #| grep --color=always -E '.*'
    #} \
      #|& tee -- "${setenv_delta}"
    #{
      #diff --suppress-{common-lines,blank-empty} --color=always \
        #--palette='ad=1;3;38;5;190:de=1;3;38;5;129' \
        #"${setenv_prev}" "${setenv_now}" \
        #| grep -ve BASH_LINENO -e BASH_COMMAND -e BASH_SOURCE \
          #-e setenv_ -Fe '---'
    #} \
      #|& tee -a "${setenv_delta}"

    # create a new delta file, each time
    setenv_delta="$(mktemp -p /tmp --suffix=."${xtr_f_nm}.A")" 
      #diff -y -W 500 --suppress-{common-lines,blank-empty} \
		    #--color=never "${setenv_prev}" "${setenv_now}" \
        #|& grep -v setenv \
        #| grep --color=always -E '.*' \
        #|& tee -- "${setenv_delta}"
      #wait -f
      diff --suppress-{common-lines,blank-empty} --color=always \
        --palette='ad=1;3;38;5;190:de=1;3;38;5;129' \
        "${setenv_prev}" "${setenv_now}" \
        |& tee -a "${setenv_delta}"
        #| grep -ve BASH_LINENO -e BASH_COMMAND -e BASH_SOURCE \
          #-e setenv_ -Fe '---' \
    # set colors for `wc` output
    export GREP_COLORS='mt=01;104'
    wc "${setenv_delta}" \
      | grep --color=always -E '.*'
    # reset colors for `grep` output
    export GREP_COLORS='mt=01;43'
  fi
  : '_mk_setenv_delta ENDS  ' "$((--funclvl))" "${fence}"
}
_mk_deltas() {
  : '_mk_deltas BEGINS' "$((++funclvl))" "${fence}"
  #_xtrace_duck
  _mk_setenv_prev
  _mk_setenv_now
  _mk_setenv_delta
  #_xtrace_duck
  : '_mk_deltas ENDS  ' "$((--funclvl))" "${fence}"
}
_debug_prompt() {
  : '_debug_prompt BEGINS' "$((++funclvl))" "${fence}"
  _mk_deltas
  : '~~~~~~~PROMPT~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
  read -rp " +[${BASH_SOURCE[0]}:${LINENO}] ${BASH_COMMAND[0]}?" _
  :
  : '_debug_prompt ENDS  ' "$((--funclvl))" "${fence}"
}
_full_xtrace() {
  : '_full_xtrace BEGINS' "$((++funclvl))" "${fence}"
  #set -o functrace
  trap '_debug_prompt "$_";' DEBUG
  set -x
  : '_full_xtrace ENDS  ' "$((--funclvl))" "${fence}"
}
#_full_xtrace
: "${BASH_SOURCE[0]}:${LINENO} ${BASH_SOURCE[1]}:${BASH_LINENO[0]}"
#exit "${LINENO}"
set -x

