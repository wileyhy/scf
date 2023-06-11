# ID and sudo

  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}" # <>

if [[ "${UID}" == 0 ]]; then
  printf '\n\t Must be a regular user and use sudo. \n\n'
  exit 1
elif ! sudo -v; then
  printf '\n\tValidation failed of user\x27s \x60sudo\x60 timestamp; '
  printf 'exiting.\n\n'
  exit "${nL}"
fi
  
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}" # <>

