# ID and sudo
# shellcheck shell=bash


  # <> Obligatory debugging block
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  post_src "${nBS[0]}" "${nL}" "$@"
  #x_trace
  #: "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


: 'ID and -sudo-'
if [[ ${UID} == 0 ]]; then
  printf '\n\t Must be a regular user and use sudo. \n\n'
  exit 1
elif ! sudo -v; then
  printf '\n\tValidation failed of user\x27s \x60sudo\x60 timestamp; '
  printf 'exiting.\n\n'
  exit "${nL}"
fi


  # <> Obligatory debugging block
  #post_src "${nBS[0]}" "${nL}" "$@"
  #x_trace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"

: "Finishing $0; exiting at line ${LINENO}"
return 0

