# Verify PATH
# shellcheck shell=bash


  # <> Obligatory debugging block
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  post_src "${nBS[0]}" "${nL}" "$@"
  #x_trace
  #: "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


: 'Verify PATH'
verify_path(){ :
  : "verify_path BEGINS ${fn_bndry} ${fn_lvl}>$(( ++fn_lvl ))"
  local cc forced_path_search
  #x_trace

  # Path
  hash -r

  # Bug? with "halt", reliance on error conflicts with -set -u-

  for cc in getconf realpath sudo
  do
    forced_path_search="$(\
      type -P "$cc" 2>&1
      )"
    if [[ -z "$forced_path_search" ]] ||
      [[ ! -f "$forced_path_search" ]]
    then
      : "${halt:?}"
    fi
    hash -p "${forced_path_search}" "$cc"
  done
  unset cc forced_path_search

  local PATH_getconf
        PATH_getconf="$(\
          command -p getconf PATH 2>&1 ||
          : "${halt:?}"
        )"
  PATH="${PATH_getconf}:/usr/bin:/usr/sbin:${PATH}"         export PATH

  : 'Before running -type- / -command- or theyll print dups'
  # Note: var $PATH is always processed
  local     var_nm
            var_nm="${1}"
  local -n  nameref
            nameref="${1}"

  # Q: "CLI optargs" here means, of this function?

  : 'var bash_path is only processed when its option is included on the CLI optargs'
  # Note: variable $verify is from cli-opts.bash
  if [[ ${var_nm} == bash_path ]] &&
    [[ ${verify[*]} != *+(all|path)* ]]
  then
    return
  fi

  : 'Get constituent dirs from pos-parm 1'
  local path_1 pp path_2
  IFS=':' read -ra path_1 <<< "${nameref}"

  : 'get the cannonicalized paths of each such dir...'
  : '...and if the resulting index value is empty, then unset it'
  # ...replacing the existing array element with the corrected value.
  # no (valid) result from `realpath` unsets an array value.
  for pp in "${!path_1[@]}"
  do
    #                                                               < cmd
    path_1[pp]="$(\
      realpath -e "${path_1[pp]}" 2>&1
    )"

    if [[ -z ${path_1[pp]} ]] ||
      [[ ! -d "${path_1[pp]}" ]]
    then
      unset 'path_1[pp]'
    fi
  done
  unset pp

  : 'if the path_1 is now empty, then exit'
  if [[ "${#path_1[@]}" -eq 0 ]]
  then
    er_x verify_path "${nameref}"
  fi

  # Q: necc to re-exec `local p`?

  : 'remove any duplicates while preserving order of dirs'
  for pp in "${!path_1[@]}"
  do
    if [[ ${path_2[*]} =~ ${path_1[pp]} ]]
    then
      unset 'path_1[pp]'
    else
      path_2+=( "${path_1[pp]}" )
    fi
  done
  unset pp

  : 'reset indices of path_2'
  path_2=( "${path_2[@]}" )

  : 'reset path vars'
  printf -v "${var_nm}" '%s' "$(\
    {
      printf '%s' "${path_2[0]}"
      unset 'path_2[0]'
      [[ -n "${path_2[*]}" ]] &&
        printf ':%s' "${path_2[@]}"
    }
  )"

  : 'if the path var is PATH, then reset PATH globally'
  : 'if the path var is bash_path, then reset find_path'
  if [[ "${var_nm}" = PATH ]]
  then
    local path_2_end
          path_2_end="${path_2[-1]}"
    unset 'path_2[-1]'
    PATH="$(\
      printf '%s:' "${path_2[@]}"
    )"
    PATH+="${path_2_end}"
    local -gx PATH

  elif [[ "${var_nm}" = bash_path ]]
  then
    local -Ig find_path
    IFS=':' read -ra find_path <<< "${bash_path}"
  fi
  : "verify_path ENDS ${fn_bndry} ${fn_lvl}>$(( --fn_lvl ))"
}
export  -f  verify_path
declare -ft verify_path

: 'verify path vars'

verify_path     PATH
readonly        PATH
export          PATH

[[ -v           bash_path ]] &&
  verify_path   bash_path
export          bash_path

  # <> Obligatory debugging block
  #post_src "${nBS[0]}" "${nL}" "$@"
  #x_trace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x

: "Finishing script zero $0 at line ${LINENO}"
return 0

