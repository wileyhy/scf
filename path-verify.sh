# Verify PATH


: 'Verify PATH'
_verify_path(){
  : '_verify_path BEGINS'  "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  #_full_xtrace
  # ...before running `type` / `command` or they'll print dups
  # Note: var $PATH is always processed
  local loc_var_nm
  local -n loc_nameref
  loc_var_nm="${1}"
  loc_nameref="${1}"
  # Q: "CLI optargs" here means, of this function?
  # var $bash_path is only processed when the CLI optargs say so
  if [[ "${loc_var_nm}" == bash_path ]] \
    && [[ "${verify[*]}" != *+(all|path)* ]]
  then
    return
  fi
  # Get constituent dirs from $1
  local loc_path_{1,2} p
  IFS=':' read -ra loc_path_1 <<< "${loc_nameref}"
  # get the cannonicalized paths of each such dir, replacing the
  # existing array element with the corrected value. no result
  # from `realpath` sets an empty ('') array value.
  for p in "${!loc_path_1[@]}"; do
    loc_path_1[p]="$(realpath -e "${loc_path_1[p]}" 2>/dev/null)"
    # if the resulting index value is empty, then unset it
    if [[ -z "${loc_path_1[p]}" ]]; then
      unset 'loc_path_1[p]'
    fi
  done; unset p
  # if the loc_path_1 is now empty, then exit
  if [[ "${#loc_path_1[@]}" -eq 0 ]]; then
    _erx _verify_path "${loc_nameref}"
  fi
  # Q: necc to re-exec `local p`?
  # remove any duplicates while preserving order of dirs
  for p in "${!loc_path_1[@]}"; do
    if [[ "${loc_path_2[*]}" =~ ${loc_path_1[p]} ]]; then
      unset 'loc_path_1[p]'
    else
      loc_path_2+=("${loc_path_1[p]}")
    fi
  done; unset p
  # reset indices of loc_path_2
  loc_path_2=("${loc_path_2[@]}")
  # reset path vars
  builtin printf -v "${loc_var_nm}" '%s' "$(
    printf '%s' "${loc_path_2[0]}";
    unset 'loc_path_2[0]';
    [[ -n "${loc_path_2[*]}" ]] \
      && printf ':%s' "${loc_path_2[@]}"
  )"
  # if the path var is bash_path, then reset find_path
  if [[ "${loc_var_nm}" = bash_path ]]; then
    IFS=":" read -ra find_path <<<"${bash_path}"
  fi
  : '_verify_path ENDS  '  "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}
_verify_path PATH
_verify_path bash_path
#exit "${nL}"
#_full_xtrace



