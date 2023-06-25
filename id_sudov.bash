# ID and sudo
# shellcheck shell=bash


  # <> Obligatory debugging block
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  _post_src "${nBS[0]}" "${nL}" "$@"
  #_xtrace_
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


: 'ID and -sudo-'
if [[ "${UID}" == 0 ]]; then
  printf '\n\t Must be a regular user and use sudo. \n\n'
  exit 1
#                                                                   < cmd
elif ! sudo -v; then
  printf '\n\tValidation failed of user\x27s \x60sudo\x60 timestamp; '
  printf 'exiting.\n\n'
  exit "${nL}"
fi


  # <> Obligatory debugging block
  #_post_src "${nBS[0]}" "${nL}" "$@"
  #_xtrace_
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"

return 0

