# Required programs

  # <> Obligatory debugging block
  #_full_xtrace
  : "${BASH_SOURCE[0]}:${LINENO} ${BASH_SOURCE[1]}:${BASH_LINENO[0]}"
  #exit "${LINENO}"
  set -x


reqd_cmds=( awk chmod cp cut dirname find grep ln ls mkdir rm rmdir
  stat sudo tee )
yn=n


hash -r;
for c in "${reqd_cmds[@]}"; do
  type_P_o="$(type -P "$c")"
  if [[ -n "$type_P_o" ]]; then
    hash -p "$type_P_o" "$c"
  else
    yn=y
    list+=("$c")
  fi;
done; unset c reqd_cmds type_P_o


if [[ "$yn" == 'n' ]]; then
  : 'No additional commands are required'
else
  printf '\n\t Please install the following commands:\n'
  printf '\t\t%s\n' "${list[@]}"
  echo
  exit "$LINENO"
fi; unset yn list


  # <> Obligatory debugging block
  #_full_xtrace
  : "${BASH_SOURCE[0]}:${LINENO} ${BASH_SOURCE[1]}:${BASH_LINENO[0]}"
  #exit "${LINENO}"
  set -x

