# Verify ACL's
# shellcheck shell=bash


  # <> Obligatory debugging block
  _post_src "${nL}" "$@"
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


: 'Verify ACLs'
# Variables, this section
unset fs_root_d full_dir_list ext_array dir sub_dir num_sub_dirs N n \
  extglob_pattern ext_first ext_last getfacl_o grep_o
fs_root_d=/
declare -A full_dir_list
ext_array=()
# for each actual directory in bash_path ("big loop"?)
for dir in "${bash_path[@]}"; do
  # limit the number of loops to the number of constituent directory
  # inodes. safely split each directory into its constituent directory
  # names, ie, by using NULL's in place of '/'s
  unset sub_dir
  num_sub_dirs="$(tr '/' '\0' <<< "$dir" \
    | gawk --lint -F'\0' '{ print NF }')"
  N=$((num_sub_dirs - 1))
  # Bug: sub_dir's sb ID'd fr dir programtcly w nulls if poss
  # create array w awk? or w read / mapfile ?
  #IFS=/ read -ra a_sub_dirs <<< "$dir"
  #mapfile -d '' -t a_sub_dirs < <(tr '/' '\0' <<< "${dir#/}")
  # Bug? shouldnt this be a regular for loop?
  # read the ACLs of each dir and sub_dir ("small loop"?)
  for ((n = N; n >= 0; --n)); do
    # Assign a value to $sub_dir as necessary
    : "${sub_dir:="${dir}"}"
    # TODO: quote ${extglob_pattern or not? - SC-2053=w.
    # Also write a lg comment explaining this section of code
      # <>
      [[ "${sub_dir}" = "${extglob_pattern}" ]]
      echo $?
      #[[ "${sub_dir}" = ${extglob_pattern} ]] ; echo $?
      #"${Halt:?}"
    # If the sub_dir is already listed in the extglob_pattern, then
    # move on to the next small loop
    # Bug: this [[ cmd is wrong; sb [ ext =~ sub ] ...correct?
    if [[ "${sub_dir}" = "${extglob_pattern}" ]]; then
      # Bug: this PE dups above same PE
      sub_dir="$(dirname "${sub_dir:="${dir}"}")"
      # If the sub_dir is '/', then move on to the next big loop
      if [[ "${sub_dir}" = "${fs_root_d}" ]]; then
        break
      fi
      # otherwise carry on w the next small loop
      continue
    fi
    # testing each constituent subdir of all dirs in PATH will
    # necessarily involve listing some dirs, ie, /usr, more than
    # once
    # Use an Associative array to filter out duplicate entries.
    # (With associative arrays, duplicate assignments are idempotent.)
    full_dir_list["${sub_dir}"]+="${n},"
    # create a list of directories and subdirectories that have been
    # tested so far. This section concatenates directories as strings
    # into a variable that the shell will later interpret as an
    # extglob.
    ext_array=("${!full_dir_list[@]}")
    ext_first="${ext_array[0]}"
    [[ -n "${ext_first}" ]] \
      && unset 'ext_array[0]'
    #_full_xtrace
    :;: "<>"
    declare -p  ext_array
    ext_last="${ext_array[*]: -1:1}" # [@] or [*] ? SC-2124=w TODO
    #_full_xtrace
    :;: "<>"
    declare -p  ext_last
    #exit "${nL}"
    [[ -n "${ext_last}" ]] \
      && unset "ext_array[${#ext_array[@]}]"
    # index math can be a little weird
    # create the exglob_pattern
    if [[ -n "${ext_first}" ]]; then
      extglob_pattern="$(printf '@(%s' "${ext_first}")"
      [[ "${#ext_array[@]}" -gt 0 ]] \
        && extglob_pattern+="$(printf '|%s' "${ext_array[@]}")"
      if [[ -n "${ext_last}" ]]; then
        extglob_pattern+="$(printf '|%s)' "${ext_last}")"
      else
        extglob_pattern+="$(printf ')')"
      fi
    fi
    # look for any ACL's on the directory
    getfacl_o="$(getfacl -enp -- "${sub_dir}" 2>/dev/null)"
    grep_o="$(grep -ve '^#' -e ^'user::' -e ^'group::' -e ^'other::' \
      <<<"${getfacl_o}")"
    # If found, exit the script and inform the user
    if [[ -n "${grep_o}" ]]; then
      printf '\n%s: ACL defined for this directory:\n\t%s\n\n' \
        "${scr_nm}" "${sub_dir}"
      echo "${getfacl_o}"
      printf '\n\tThis command will remove all ACL\x27s from the '
      printf 'specified directory:\n\n\t\tsetfacl -b %s\n\n' "${sub_dir}"
      exit 1
    # otherwise, move on to the next big loop
    else
      if [[ "${sub_dir}" = "${fs_root_d}" ]]; then
        break
      fi
    fi
    # Bug: dup PE w 2 above
    sub_dir="$(dirname "${sub_dir:="${dir}"}")"
  done
done
unset fs_root_d full_dir_list ext_array dir sub_dir num_sub_dirs \
  N n extglob_pattern ext_first ext_last getfacl_o grep_o
# <>
#_full_xtrace
#exit "${nL}"



