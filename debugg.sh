# Debugging


  # <> Obligatory debugging block
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  set -x


shopt -s expand_aliases

_test(){
  #declare -n n=nBS
  #declare -n e=nL
  #declare -a l
  declare -a a1
  #alias L_='declare -a "a1[8-${#nBS[@]}]=$nL"'
  #function M_ { m=("${a1[@]}");}
  #L_;
  declare -a "a1[8-${#nBS[@]}]=$nL"
  echo $?
  #M_;
  a2=("${a1[@]}")
  echo $?
  declare -p a1 a2
  #alias M_='m=("${l[@]}")';
}; declare -fxt _test
#history -a

_test

  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  exit "${nL}"
  set -x

x+=([32-3]=d)
y=("${x[@]}")
declare -p y
#declare -a y=([0]="d" [1]="c" [2]="b" [3]="a")


foo(){
  echo bar "$@";
}
L_;
foo "$e"
declare -p l


trap _exit_trap EXIT TERM
#_full_xtrace

declare -a "l[8-${#n[@]}]=$nL"; exit "${l[8-${#n[@]}]}"

: "count, nBL: ${#nBL[@]}"
declare -p nBL
: "count, nBS: ${#nBS[@]}"
declare -p nBS
: "count, nF: ${#nF[@]}"
declare -p nF
"${Halt:?}"




: '<>: Debug functions & traps'

_trap_ctrl_C() {
  set -x
  trap - INT
  for f in "${xtr_time_f}" "${xtr_senv_prev}" \
    "${xtr_senv_now}" "${xtr_senv_delt}";
  do
    if [[ -f "$f" ]]; then
      if ! rm --one-file-system --preserve-root=all "${f}"; then
          _erx "rm failed -- ${f} -- line ${nL}"
      fi
    fi
  done
  kill -s INT "$$"
}; declare -fxt _trap_ctrl_C
trap '_trap_ctrl_C' INT
  #sleep 10 # <>


: '<> Debug: Delete any left over xtrace files from -mktemp -p /tmp-'

xtr_f_nm="${rand_uniq_str}.xtr"
xtr_time_f="/tmp/tmp.mtime_file.${xtr_f_nm}"
xtr_delta_sum_f="$(mktemp -p /tmp --suffix=."${xtr_f_nm}.E")"
export xtr_f_nm xtr_time_f xtr_delta_sum_f
unset f xtr_rm_list xtr_files

touch -d "${max_age_of_tmp_files}" "${xtr_time_f}"
mapfile -d '' -t xtr_files < <(
  find -P /tmp -maxdepth 1 -type f \
    -name "tmp.[a-zA-Z0-9]*.${repo_nm}.[0-9]*.[0-9]*.xtr*" \
    '!' -newer "${xtr_time_f}" '!' -name "${xtr_time_f##*/}" -print0
)

# ...if they're (inodes are for) files & not symlinks, & owned by the
# same EUID.
for f in "${xtr_files[@]}"; do
  if [[ -f "${f}" ]] && [[ ! -L "${f}" ]] && [[ -O "${f}" ]]; then
    sudo
    chmod 000 "$f"
    xtr_rm_list+=("${f}")
  fi
done; unset f

if [[ -n "${xtr_rm_list[*]}" ]]; then
  rm -fv --one-file-system --preserve-root=all "${xtr_rm_list[@]}"
  break
fi; unset xtr_rm_list xtr_files


  # <> Obligatory debugging block
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


: '<> Debug: XTrace variables and functions'

funclvl=0
fence=' +++ +++ +++ '

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
}; declare -ftx _xtrace_duck

# A set of functions for printing changes in shell variables and para-
# meters between each execution of a command; for use when the DEBUG
# trap is enabled.

_mk_v_setenv_pre() {
  : '_mk_v_setenv_pre BEGINS' "$((++funclvl))" "${fence}"
  : 'if now'
  if [[ -n "${xtr_senv_now}" ]]; then
    : 'if prev'
    if [[ -n "${xtr_senv_prev}" ]]; then
      rm --one-file-system --preserve-root=all  -f -- "${xtr_senv_prev}"
    fi
    xtr_senv_prev="${xtr_senv_now}"
  fi
  : '_mk_v_setenv_pre ENDS  ' "$((--funclvl))" "${fence}"
}; declare -ftx _mk_v_setenv_pre

_mk_v_setenv_novv() {
  : '_mk_v_setenv_novv BEGINS' "$((++funclvl))" "${fence}"
  # work on printing function trace stack
  for i in "${!n[@]}"; do
    caller "$i"
  done
  set -- "${!n[@]}"
  for i; do
    : $'\t\t\t\t'"${i}"$'\t'"${nBL[$i]}"$'\t'"${nF[$i]}"$'\t'"${nBS[$i+1]} lineno-array-index"
  done
  ${Halt:?}

  xtr_senv_now="$(mktemp -p /tmp --suffix=."${xtr_f_nm}")"
    # `{ set; env;} | tee`: env & set dont print in simple xtrace
    set \
      |& tee -- "${xtr_senv_now}" >/dev/null
    env \
      |& tee -a -- "${xtr_senv_now}" >/dev/null
  : '_mk_v_setenv_novv ENDS  ' "$((--funclvl))" "${fence}"
}; declare -ftx _mk_v_setenv_novv

_mk_v_setenv_delta() {
  : '_mk_v_setenv_delta BEGINS' "$((++funclvl))" "${fence}"
  : 'if now and prev'
  if [[ -n "${xtr_senv_now}" ]] \
    && [[ -n "${xtr_senv_prev}" ]];
  then
    : 'if delta'
    if [[ -n "${xtr_senv_delt}" ]]; then
      tee -a "${xtr_delta_sum_f}" < "${xtr_senv_delt}"
      rm --one-file-system --preserve-root=all  -f -- "${xtr_senv_delt}"
      wait -f
    fi

		# syntax caused a weird bug?
		# 	with alsa-info.sh line ~465-466
		#	and then again
        ## create a new delta file, each time
    #xtr_senv_delt="$(mktemp -p /tmp --suffix=."${xtr_f_nm}")" #
    #{
      #diff -y --suppress-{common-lines,blank-empty} --color=never \
        #"${xtr_senv_prev}" "${xtr_senv_now}" \
        #|& grep -v setenv \
        #| grep --color=always -E '.*'
    #} \
      #|& tee -- "${xtr_senv_delt}"
    #{
      #diff --suppress-{common-lines,blank-empty} --color=always \
        #--palette='ad=1;3;38;5;190:de=1;3;38;5;129' \
        #"${xtr_senv_prev}" "${xtr_senv_now}" \
        #| grep -ve nBL -e BASH_COMMAND -e nBS \
          #-e setenv_ -Fe '---'
    #} \
      #|& tee -a "${xtr_senv_delt}"

    # create a new delta file, each time
    xtr_senv_delt="$(mktemp -p /tmp --suffix=."${xtr_f_nm}.A")"
      #diff -y -W 500 --suppress-{common-lines,blank-empty} \
		    #--color=never "${xtr_senv_prev}" "${xtr_senv_now}" \
        #|& grep -v setenv \
        #| grep --color=always -E '.*' \
        #|& tee -- "${xtr_senv_delt}"
      #wait -f
      diff --suppress-{common-lines,blank-empty} --color=always \
        --palette='ad=1;3;38;5;190:de=1;3;38;5;129' \
        "${xtr_senv_prev}" "${xtr_senv_now}" \
        |& tee -a "${xtr_senv_delt}"
        #| grep -ve nBL -e BASH_COMMAND -e nBS \
          #-e setenv_ -Fe '---' \
    # set colors for `wc` output
    export GREP_COLORS='mt=01;104'
    wc "${xtr_senv_delt}" \
      | grep --color=always -E '.*'
    # reset colors for `grep` output
    export GREP_COLORS='mt=01;43'
  fi
  : '_mk_v_setenv_delta ENDS  ' "$((--funclvl))" "${fence}"
}; declare -ftx _mk_v_setenv_delta

_mk_deltas() {
  : '_mk_deltas BEGINS' "$((++funclvl))" "${fence}"
  #_xtrace_duck
  _mk_v_setenv_pre
  _mk_v_setenv_novv
  _mk_v_setenv_delta
  #_xtrace_duck
  : '_mk_deltas ENDS  ' "$((--funclvl))" "${fence}"
}; declare -ftx _mk_deltas

_debug_prompt() {
  : '_debug_prompt BEGINS' "$((++funclvl))" "${fence}"
  _mk_deltas
  : '~~~ ~~ ~ PROMPT ~ ~~ ~~~'
  read -rp " +[${nBS[0]}:${nL}] ${BASH_COMMAND[0]}?" _
  : '_debug_prompt ENDS  ' "$((--funclvl))" "${fence}"
}; declare -ftx _debug_prompt

_full_xtrace() {
  : '_full_xtrace BEGINS' "$((++funclvl))" "${fence}"
  #set -o functrace
  trap '_debug_prompt "$_";' DEBUG
  set -x
  : '_full_xtrace ENDS  ' "$((--funclvl))" "${fence}"
}; declare -ftx _full_xtrace


  # <> Obligatory debugging block
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x

