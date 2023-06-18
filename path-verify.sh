# Verify PATH
# shellcheck shell=bash


  # <> Obligatory debugging block
  #_post_src "${nBS[0]}" "${nL}" "$@"
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x

  
: 'Verify PATH'
_verify_path(){
  : '_verify_path BEGINS'  "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  #_full_xtrace
  
  # Before running `type` / `command` or they'll print dups
  #   Note: var $PATH is always processed
  local var_nm
  local -n nameref
  var_nm="${1}"
  nameref="${1}"
  
  # Q: "CLI optargs" here means, of this function?
  
  # var $bash_path is only processed when the CLI optargs say so
  if [[ "${var_nm}" == bash_path ]] && 
    [[ "${verify[*]}" != *+(all|path)* ]]
  then
    return
  fi
  
  # Get constituent dirs from $1
  local path_{1,2} p
  IFS=':' read -ra path_1 <<< "${nameref}"
  
  # get the cannonicalized paths of each such dir, replacing the
  # existing array element with the corrected value. no result
  # from `realpath` sets an empty ('') array value.
  for p in "${!path_1[@]}"
  do
    #                                                               < cmd
    path_1[p]="$(realpath -e "${path_1[p]}" 2>&1)"
    
    # if the resulting index value is empty, then unset it
    if [[ -z "${path_1[p]}" ]] ||
      [[ ! -d "${path_1[p]}" ]]
    then
      unset 'path_1[p]'
    fi
  done
  unset p
  
  # if the path_1 is now empty, then exit
  if [[ "${#path_1[@]}" -eq 0 ]]
  then
    _erx _verify_path "${nameref}"
  fi
  
  # Q: necc to re-exec `local p`?
  
  # remove any duplicates while preserving order of dirs
  for p in "${!path_1[@]}"
  do
    if [[ "${path_2[*]}" =~ ${path_1[p]} ]]
    then
      unset 'path_1[p]'
    else
      path_2+=("${path_1[p]}")
    fi
  done
  unset p
  
  # reset indices of path_2
  path_2=("${path_2[@]}")
  
  # reset path vars
  builtin printf -v "${var_nm}" '%s' "$(
    {
      printf '%s' "${path_2[0]}";
      unset 'path_2[0]';
      [[ -n "${path_2[*]}" ]] && 
        printf ':%s' "${path_2[@]}"
    } 
  )"
  
  # if the path var is bash_path, then reset find_path
  if [[ "${var_nm}" = bash_path ]]
  then
    IFS=":" read -ra find_path <<< "${bash_path}"
  fi
  : '_verify_path ENDS  '  "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
}
declare -fxt

# verify path vars
_verify_path PATH
[[ -v bash_path ]] && 
  _verify_path bash_path

#exit "${nL}"
#_full_xtrace



