# Required programs
# shellcheck shell=bash


  # <> Obligatory debugging block
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  _post_src "${nBS[0]}" "${nL}" "$@"
  #_xtrace_
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x
  

reqd_cmds=( file        fuser getconf getfacl 
            mktemp      namei pgrep   realpath 
            shellcheck  stat  strings sudo 
          )
  # <>
  #reqd_cmds+=( codeblocks  gcc-c++ )

# otherwise, common commands: cat chmod diff env find kill mkdir rev 
#   rm rsync tee test touch tr unlink ...
yn=n

builtin hash -r;
for c in "${reqd_cmds[@]}"
do
  type_P_o="$(builtin type -P "$c" 2>&1)"
  if [[ -n "$type_P_o" ]] &&
    [[ -f "$type_P_o" ]]
  then
    builtin hash -p "$type_P_o" "$c"
  else
    yn=y
    list+=("$c")
  fi;
done
unset c reqd_cmds type_P_o


if [[ "$yn" == n ]]
then
  : 'No additional commands are required'
else
  printf '\n\t Please install the following commands:\n'
  printf '\t\t%s\n' "${list[@]}"
  echo
  exit "$nL"
fi
unset yn list

  # <>
  #hash | sort | cat -n

  # <> Obligatory debugging block
  #_xtrace_
  : "${nBS[0]}:${nL}"
  #exit "${nL}"
  #set -x

return 0

