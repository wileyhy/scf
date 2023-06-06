#!/usr/bin/env -iS bash
#!/usr/bin/bash
# shellcheck disable=SC2317 # unreachable commands
# shellcheck disable=SC2096 # excessive crashbang
# add-"shadow"s.bsh

: 'Regular users only, and -sudo- required' 
if [[ "${UID}" == 0 ]]; then
  printf '\n\t Must be a regular user and use sudo. \n\n'
  exit "${LINENO}"
elif ! sudo -v; then
  printf '\n\t Validation failed of user\x27s \x60sudo\x60 timestamp. '
  printf 'Exiting.\n\n'
  exit "${LINENO}"
fi

: 'Target string:' 
#set -vx
if [[ "$#" -eq 0 ]]; then x='export'; else x="$1"; fi;
[[ -n "$x" ]] && readonly x
#declare -p x
enable -n "$x"
#enable -a | grep "$x"
#exit "${LINENO}"

: 'Required programs' ;:;
if [[ "${BASH_VERSION:0:1}" -lt 5 ]]; then 
  echo Please install Bash version 5, thanks.
  exit "${LINENO}"
fi

reqd_cmds=( awk chmod cp cut dirname find grep ln ls mkdir rm rmdir 
  stat sudo tee )
yn=n

hash -r; 
#hash
for c in "${reqd_cmds[@]}"; do 
  if type -P "${c}" > /dev/null 2>&1; then 
    hash -p "$(type -P "${c}")" "${c}"
  else
    yn=y
    list+=("${c}")
  fi; 
done; unset c reqd_cmds
#hash

if [[ "${yn}" == 'n' ]]; then 
  : 'No additional commands are required'
else
  printf '\n\t Please install the following commands:\n'
  printf '\t\t%s\n' "${list[@]}" 
  echo
  exit "${LINENO}"
fi; unset yn list
#exit "${LINENO}"
#set -vx


: 'Functions, variables and umask' 
function fn_erx(){
  local ec="${?}"
  echo ERROR: "${@}"
  exit "${ec}"
}

: 'Set up testing of PATH dirs' :
unset PATH 
PATH="/home/liveuser/.local/bin_symlink"  # < 0
PATH+=":/home/liveuser/bin_hardlink"      # < 1
PATH+=":/usr/local/bin_copy-of-inode"     # < 2
PATH+=":/usr/bin"                         # < 3
PATH+=":/bin"                             # < 4
PATH+=":/usr/local/sbin_dangling_symlink" # < 5
PATH+=":/usr/sbin"                        # < 6
#declare -p PATH
IFS=':' read -ra find_path <<< "${PATH}"
#declare -p find_path

: 'Set up testing of "shadow" files' :
xfa="${find_path[0]}/${x}" # symlink              # < 0
xfb="${find_path[1]}/${x}" # hardlink             # < 1
xfc="${find_path[2]}/${x}" # copy of inode        # < 2
xfd="/usr/bin/${x}"        # executable file      # < 3
xfe="${find_path[5]}/${x}" # dangling symlink     # < 5
xff="${find_path[6]}/${x}" # deleted executable   # < 6
xfg=("${xfa}" "${xfb}" "${xfc}" "${xfd}" "${xfe}" "${xff}")
#exit "${LINENO}"
#set -x


: 'Tests: Remove certain values' 

: 'Remove: Regular variable' 
unset -v "${x}"

: 'Remove: Namerefs' 
unset -n "${x}"
set -x

: 'Remove: any previous test files'
declare -p xfg
for f in "${xfg[@]}"; do
  if [[ -f "${f}" ]] || [[ -L "${f}" ]]
  then
    sudo rm -f --one-file-system --preserve-root=all -- "${f}" || 
      fn_erx
  fi;
done; unset f
exit "${LINENO}"

: 'Remove: Unused dirs in PATH' 
# if the dir exists try to remove it, but if it isn't empty, then 
# ignore the error 
for d in "${xfg[@]%/*}"; do
  if [[ -d "${d}" ]]; then 
    fsobjs="$(find "$d" 2> /dev/null | tr -d '\n' | head -c32)" 
    if [[ -z "${fsobjs}" ]] && [[ ! -L "${d}" ]]; then
      sudo rmdir --ignore-fail-on-non-empty -- "${d}" || 
        fn_erx "${LINENO}"
    fi
  fi
done; unset d 
#exit "${LINENO}"

: 'Remove: Builtin' 
enable_o="$(enable -a | grep "${x}")"
if [[ "$enable_o" != *-n* ]]; then
  enable -n "${x}"
fi; unset enable_o

: 'Remove: Function' 
unset -f "${x}"

: 'Remove: Alias' 
unalias "${x}" 2> /dev/null
#exit "${LINENO}"
#set -x



: 'Create "shadow" variable' 
decl_p_o="$(declare -p "${x}" 2> /dev/null)"
if [[ -z "${decl_p_o}" ]]; then
  declare "${x}"=quux
  decl_p_o="$(declare -p "${x}" 2> /dev/null)"
  if [[ -z "${decl_p_o}" ]]; then
    fn_erx
  fi
fi; unset decl_p_o
#exit "${LINENO}"
#set -x



: 'Create "shadow" nameref' 
# Note: at equal scope, a variable cannot be a nameref and not a nameref
# at the same time. Setting a nameref overwrites any non-nameref variable.
# `awk` regex crafted with care
#   a - no, overrides nameref
#   A - no, overrides nameref
#   i - no, a nameref can only point to a variable name which cannot be 
#         an integer
#   l - ok, but cancels out 'u'
#   n - ok, overrides 'i'
#   r - ok
#   t - ok, but only meaningful if target string is a function name
#   u - ok, but cancels out 'l'
#   x - ok
decl_awk_o="$(declare -p "${x}" |& awk '$2 ~ /^-[lrtux]*n[lrtux]*/')"
if [[ -z "${decl_awk_o}" ]]; then
  declare -n "${x}"=UID
  decl_awk_o="$(declare -p "${x}" |& awk '$2 ~ /^-[lrtux]*n[lrtux]*/')"
  if [[ -z "${decl_awk_o}" ]]; then
    fn_erx
  fi
fi; unset decl_awk_o
#exit "${LINENO}"
#set -x



: 'create PATH dirs as necc' 
umask 022
for d in "${xfg[@]%/*}"; do
  if [[ ! -d "${d}" ]]; then
    sudo mkdir -p "${d}" || 
      fn_erx "${LINENO}"
  fi;
done; unset d
#exit "${LINENO}"
#set -x



: 'Create "shadow" executable file' 
if [[ ! -f "${xfd}" ]]; then
  printf '\x23\x21/usr/bin/sh\n%s \x22\x24\x40\x22\n' "${x}" | 
    sudo tee  "${xfd}" > /dev/null || 
      fn_erx "${LINENO}"
  if [[ ! -f "${xfd}" ]]; then
    fn_erx
  fi
fi
if [[ "$(type -t "${x}")" != file ]]; then
  fn_erx "${LINENO}"
fi
#exit "${LINENO}"
#set -x



: 'Symlink of "shadow" file' 
if [[ ! -f "${xfa}" ]]; then
  sudo ln -s "${xfd}" "${xfa}" || 
    fn_erx "${LINENO}"
  if [[ ! -f "${xfa}" ]]; then
    fn_erx
  fi
fi
if [[ "$(type -t "${x}")" != file ]]; then
  fn_erx "${LINENO}"
fi
#exit "${LINENO}"
#set -x



: 'Hardlink of "shadow" file' 
if [[ ! -f "${xfb}" ]]; then
  sudo ln "${xfd}" "${xfb}" || 
    fn_erx "${LINENO}"
  if [[ ! -f "${xfb}" ]]; then
    fn_erx
  fi
fi
if [[ "$(type -t "${x}")" != file ]]; then
  fn_erx "${LINENO}"
fi
#exit "${LINENO}"
#set -x



: 'Dangling symlink of "shadow" file' 
if [[ ! -f "${xfe}" ]]; then
  sudo cp -b "${xfd}" "${xff}" || 
    fn_erx "${LINENO}"
  sudo ln -s "${xff}" "${xfe}" || 
    fn_erx "${LINENO}"
  sudo rm -f i--one-file-system --preserve-root=all -- "${xff}" || 
    fn_erx "${LINENO}"
  if [[ ! -L "${xfe}" ]]; then
    fn_erx
  fi
fi
if [[ "$(type -t "${x}")" != file ]]; then
  fn_erx "${LINENO}"
fi
: 'the actual file has been removed so the extra symlink may "dangle"' 
unset 'xfg[6]'
#ls -alhFi "${xfe}" "${xff}"
#exit "${LINENO}"
set -x



: 'Copy inode of "shadow" file'
if [[ ! -f "${xfc}" ]]; then
  stat_o="$(stat -c%i "${xfd}")"
  LC_ALL=C sudo find "${xfd%/*}" -inum "${stat_o}" \
    -exec rsync -ac '{}' "${xfc}" \; ||
    fn_erx "${LINENO}"
  if [[ ! -f "${xfc}" ]]; then
    fn_erx "${LINENO}"
  fi
fi; unset stat_o
exit "${LINENO}"
set -x



: 'DAC permissions of "shadow" files' 
for f in "${xfg[@]}" ; do
  if [[ -L "${f}" ]]; then
    continue
  fi
  stat_o1="$(sudo stat -c%a "${f}")"
  if [[ "${stat_o1}" != 755 ]]; then
    sudo chmod 755 "${f}" || 
      fn_erx "${LINENO}"
    stat_o2="$(sudo stat -c%a "${f}")" || 
      fn_erx "${LINENO}"
    if ! grep -q 755 <<< "${stat_o2}"; then
      fn_erx "${LINENO}"
    fi
  fi
done
exit "${LINENO}"
set -x



: 'Builtin' 
eago="$(enable | grep "${x}")"
if [[ -z "${eago:0:8}" ]]; then
  enable "${x}"
  eago="$(enable | grep "${x}")"
  if [[ -z "${eago:0:8}" ]]; then
    fn_erx
  fi
fi; unset eago
if [[ "$(type -t "${x}")" != builtin ]]; then
  fn_erx "${LINENO}"
fi
exit "${LINENO}"
set -x



: 'Create "shadow" function' 
dpfo="$(declare -pf "${x}" 2> /dev/null)"
if [[ -z "${dpfo:0:8}" ]]; then
  : 'define function'
  eval function "${x}" '{ echo function bar;}'
  dpfo="$(declare -pf "${x}")"
  if [[ -z "${dpfo:0:8}" ]]; then
    fn_erx
  fi
fi; unset dpfo
if [[ "$(type -t "${x}")" != function ]]; then
  fn_erx "${LINENO}"
fi
exit "${LINENO}"
set -x



: 'Create "shadow" alias' 
shopt -s expand_aliases
ao="$(alias "${x}" 2> /dev/null)"
if [[ -z "${ao:0:8}" ]]; then
  eval alias "${x}='{ echo alias foo;}'"
  ao="$(alias "${x}")"
  if [[ -z "${ao:0:8}" ]]; then
    fn_erx
  fi
fi; unset ao
if [[ "$(type -t "${x}")" != alias ]]; then
  fn_erx "${LINENO}"
fi
exit "${LINENO}"
set -x



: 'Verification 1: type -P' 
printf '\n\t hash -r; hash; type -P \n\n' 
hash -r; hash; type -P "${x}" 
type_P_o="$(type -P "${x}")"
printf '\n\t ls -alhFi [FILE]; ls -alhFiL [FILE] \n\n' 
ls -alhFi --quoting-style=shell-always --color=always "${type_P_o}"
ls -alhFiL --quoting-style=shell-always --color=always "${type_P_o}"
exit "${LINENO}"
set -x



: 'Verification 2: type -a' 
printf '\n\t declare -p find_path # (Same as PATH.) \n\n' 
declare -p find_path
printf '\n\t command -pV; command -v \n\n' 
command -pV "${x}"; command -v "${x}"
printf '\n\t find \n\n' 
sudo find / '(' '!' -path '*/1000/*' -a '!' -path '*/zsh/*' -a '!' \
  -path '*/selinux/*' -a '!' -path '*/tracker3/*' ')' '(' \
  -name "${x}" -o -name "${x}_*" ')' 2> /dev/null
printf '\n\t type -a\n\n' 
type -a "${x}"

exit 00

