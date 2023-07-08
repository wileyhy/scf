# Data directories
# shellcheck shell=bash


: 'Data dirs'

# This section is super buggy.
    
# Bugs: Hardcoded $mountpoint 

: 'Assign varnames and paths for the data directories'
mountpoint=/run/media/root/29_Mar_2023
main_d="${mountpoint}/${scr_dirnm}"
data_subd="${main_d}/latest_data"
curr_time_ssubd="${data_subd}/t_${scr_tcode}/"
list_crunchbangs="${curr_time_ssubd}/crunchbangs"
: 'data files'
a_write_path_nms=("${list_crunchbangs:=crunchbangs}"
  "/tmp/${list_crunchbangs##*/}"
) 
: 'make sure -data_subd- is a directory OR create the -data_subd- dir '
: 'if necessary'
[[ -d "${data_subd}" ]] \
  || mkdir "${data_subd}" # as liveuser
#set -x; :;: "<>"; sudo namei -xl  -- "${data_subd}"
: 'Label the current data as -latest.-'
mapfile -d '' -t a_previous_time_dirs < <(
  find "${data_subd}" -mindepth 1 -maxdepth 1 -type d -a \! -type l \
    -name 't_*' -print0
)
: 'if -prev_time_ssubd- is empty, delete it, otherwise -mv- it out'
: 'of the -latest- dir'
for prev_time_ssubd in "${a_previous_time_dirs[@]}"; do
  rmdir -v --ignore-fail-on-non-empty -- "${prev_time_ssubd}"
  : 'of previous prev_time_ssubd'
  if [[ -d "${prev_time_ssubd}" ]] \
    && [[ ! -L "${prev_time_ssubd}" ]]; then
    sudo mv -- "${a_previous_time_dirs[@]}" "${main_d}"
  else
    continue
  fi
done
: 'of curr_time_ssubd'
if [[ ! -d "${curr_time_ssubd}" ]]; then
  sudo  mkdir -p -- "${curr_time_ssubd}" \
    || er_x "${nL}"
fi
#set -x; :;: "<>"; sudo namei -xl  -- "${curr_time_ssubd}"

# <>
#x_trace
#exit "${nL}"

