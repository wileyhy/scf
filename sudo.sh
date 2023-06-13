# ID and sudo
# shellcheck shell=bash


if [[ "$3" == y ]]; then set -x; verb=(-v --); else verb=(--); fi
[[ "$2" == y ]] && exit "$1"


  # <> Obligatory debugging block
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  exit "${nL}"
  #set -x


if [[ "${UID}" == 0 ]]; then
  printf '\n\t Must be a regular user and use sudo. \n\n'
  exit 1
elif ! sudo -v; then
  printf '\n\tValidation failed of user\x27s \x60sudo\x60 timestamp; '
  printf 'exiting.\n\n'
  exit "${nL}"
fi


  # <> Obligatory debugging block
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x

