# Required programs
# shellcheck shell=bash


  # <> Obligatory debugging block
  _post_src "${nBS[0]}" "${nL}" "$@"
  #_xtrace_
  : "${nBS[0]}:${nL}"
  #exit "${nL}"
  #set -x


reqd_cmds=( file fuser getconf getfacl mktemp namei pgrep realpath shellcheck stat strings sudo )
yn=n
# cat chmod diff env find kill mkdir rev rm rsync tee test touch tr unlink ...

hash -r;
for c in "${reqd_cmds[@]}"
do
  type_P_o="$(type -P "$c" 2>&1)"
  if [[ -n "$type_P_o" ]]
  then
    hash -p "$type_P_o" "$c"
  else
    yn=y
    list+=("$c")
  fi;
done
unset c reqd_cmds type_P_o


if [[ "$yn" == 'n' ]]
then
  : 'No additional commands are required'
else
  printf '\n\t Please install the following commands:\n'
  printf '\t\t%s\n' "${list[@]}"
  echo
  exit "$nL"
fi
unset yn list


  # <> Obligatory debugging block
  #_xtrace_
  : "${nBS[0]}:${nL}"
  #exit "${nL}"
  set -x

