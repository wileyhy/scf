# Unused functions

#fn_num() {
#  : 'fn_num BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
#  # Usage: fn_num [raw arrays names]
#  # for each of multiple input array names
#  for loc_unquotd_array_nm_a in "${@}"; do
#    # set a local name reference variable
#    local -n loc_nameref_a="${loc_unquotd_array_nm_a}"
#    # and use the nameref to print the number of indices in the
#    # input array
#    echo ${#loc_nameref_a[@]}
#  done
#  : 'fn_num ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
#}

#  : 'fn_write_vars BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
#  # Usage: fn_write_vars [loc_script_section_nm] [raw variable names]
#  # first pos-parm is string used for differentiating filename
#  loc_script_section_nm="${1}"
#  loc_write_f_a="${curr_time_ssubd}/${loc_script_section_nm}_vars"
#  shift
#  # if the destination file already exists, then return from FN
#  [[ -e "${loc_write_f_a}" ]] \
#    && return
#  # write a new data file
#  declare -p "${@}" 2>/dev/null \
#    | sudo  tee --output-error=exit  -- "${loc_write_f_a}" >/dev/null
#  # and write a .bak file
#  fn_bak "${loc_write_f_a}"
#  : 'fn_write_vars ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
#}


