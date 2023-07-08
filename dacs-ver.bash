# Verify DAC's
# shellcheck shell=bash


  # <> Obligatory debugging block
  post_src "${nBS[0]}" "${nL}" "$@"
  #x_trace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


: 'Verify DACs'
# Bug: var path_2 is now path_2
namei_o="$(
  {
    for d in "${bash_path[@]}"; do
      namei -xl "$(
        realpath -e "$d" 2>&1
      )"
    done \
      | grep -v ^'f:' \
      | gawk --lint '$2 !~ /root/ || $3 !~ /root/ { print }'
  } 2>&1
)"
if [[ -n "${namei_o}" ]]; then
  echo 'A directory in PATH is not fully owned by root (DAC).'
  echo "${namei_o}"
  exit "${nL}"
fi


