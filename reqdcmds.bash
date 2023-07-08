# Required programs
# shellcheck shell=bash


  # <> Obligatory debugging block
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  post_src "${nBS[0]}" "${nL}" "$@"
  #x_trace
  #: "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


yn=n
reqd_cmds=( file
            fuser
            getconf
            getfacl
            mktemp
            namei
            pgrep
            realpath
            shellcheck
            stat
            strings
            sudo
          )
cmn_cmds=(  cat
            chmo\d
            diff
            env
            fin\d
            kil\l
            mkdi\r
            rev
	          r\m
            rsync
            tee
            tes\t
            touch
            tr
            unlink
          ) # backslash escapes for disabling vim colors

hash -r
unset cc type_P_o cmds_list

for cc in "${reqd_cmds[@]}" "${cmn_cmds[@]}"
do
  type_P_o="$(\
    type -P "$cc" 2>&1
  )"
  if [[ -n "$type_P_o" ]] &&
    [[ -f "$type_P_o" ]]
  then
    hash -p "$type_P_o" "$cc"
  else
    yn=y
    cmds_list+=("$cc")
  fi
done
unset cc reqd_cmds type_P_o


if [[ "$yn" == n ]]
then
  : 'No additional commands are required'
else
  printf '\n\t Please install the following commands:\n'
  printf '\t\t%s\n' "${cmds_list[@]}"
  echo
  exit "$nL"
fi
unset yn cmds_list

  # <>
  #hash | sort | cat -n

  # <> Obligatory debugging block
  #x_trace
  : "${nBS[0]}:${nL}"
  #exit "${nL}"
  #set -x

: "Finished $0; exiting at line ${LINENO}"
return 0

