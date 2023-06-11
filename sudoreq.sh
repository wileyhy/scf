# ID and sudo


  # <> Obligatory debugging block
  #_full_xtrace
  : "${BS[0]}:${LINENO} ${BS[1]}:${BASH_LINENO[0]}"
  #exit "${LINENO}"
  set -x


if [[ "${UID}" == 0 ]]; then
  printf '\n\t Must be a regular user and use sudo. \n\n'
  exit 1
elif ! sudo -v; then
  printf '\n\tValidation failed of user\x27s \x60sudo\x60 timestamp; '
  printf 'exiting.\n\n'
  exit "${LINENO}"
fi


  # <> Obligatory debugging block
  #_full_xtrace
  : "${BS[0]}:${LINENO} ${BS[1]}:${BASH_LINENO[0]}"
  #exit "${LINENO}"
  set -x

