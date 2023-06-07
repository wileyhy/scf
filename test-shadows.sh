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
LC_ALL=C  
umask 022
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
IFS=':' read -ra pathdirs <<< "${PATH}"
#declare -p pathdirs

: 'Set up testing of "shadow" files' :
symlnk="${pathdirs[0]}/${x}"    # symlink              # < 0
hrdlnk="${pathdirs[1]}/${x}"    # hardlink             # < 1
cpinod="${pathdirs[2]}/${x}"    # copy of inode        # < 2
exectbl="/usr/bin/${x}"         # executable file      # < 3
dnglsym="${pathdirs[5]}/${x}"   # dangling symlink     # < 5
deldexec="${pathdirs[6]}/${x}"  # deleted executable   # < 6
files=("${symlnk}" "${hrdlnk}" "${cpinod}" "${exectbl}" "${dnglsym}" "${deldexec}")
#exit "${LINENO}"
#set -x


: 'Tests: Remove certain values' 

: 'Remove: Regular variable' 
unset -v "${x}"

: 'Remove: Namerefs' 
unset -n "${x}"
#set -x

: 'Remove: any previous test files'
#declare -p files
for f in "${files[@]}"; do
  if [[ -f "${f}" ]] || [[ -L "${f}" ]]; then
    sudo rm -f --one-file-system --preserve-root=all -- "${f}" || 
      fn_erx "${LINENO}"
  fi;
done; unset f
#exit "${LINENO}"

: 'Remove: Unused dirs in PATH' 
# if the dir exists try to remove it, but if it isn't empty, then 
# ignore the error 
for d in "${files[@]%/*}"; do
  if [[ -d "${d}" ]]; then 
    fsobj="$(find "$d" 2> /dev/null | tr -d '\n' | head -c32)" 
    if [[ -z "${fsobj}" ]] && [[ ! -L "${d}" ]]; then
      sudo rmdir --ignore-fail-on-non-empty -- "${d}" || fn_erx "${LINENO}"
    fi
  fi
done; unset d fsobj
#exit "${LINENO}"

: 'Remove: Builtin' 
[[ "$(enable -a | grep "${x}")" != *-n* ]] && enable -n "${x}"

: 'Remove: Function' 
unset -f "${x}"

: 'Remove: Alias' 
unalias "${x}" 2> /dev/null
#exit "${LINENO}"
#set -x

: 'Create "shadow" variable' 
if ! declare -p "${x}" 2> /dev/null | grep -q "${x}"; then
  declare "${x}"=quux
  declare -p "${x}" 2> /dev/null | grep -q "${x}" || fn_erx "${LINENO}"
fi
#exit "${LINENO}"
#set -x

: 'Create "shadow" nameref' 
if ! declare -p "${x}" |& awk '$2 ~ /^-[lrtux]*n[lrtux]*/'; then
  declare -n "${x}"=UID
  declare -p "${x}" |& awk '$2 ~ /^-[lrtux]*n[lrtux]*/' || fn_erx "${LINENO}"
fi
#exit "${LINENO}"
#set -x

: 'create PATH dirs as necc' 
for d in "${files[@]%/*}"; do
  if [[ ! -d "${d}" ]]; then
    sudo mkdir -p "${d}" || fn_erx "${LINENO}"
  fi;
done; unset d
#exit "${LINENO}"
#set -x

: 'Create "shadow" executable file' 
if [[ ! -f "${exectbl}" ]]; then
  printf '\x23\x21/usr/bin/sh\n%s \x22\x24\x40\x22\n' "${x}" | 
    sudo tee  "${exectbl}" > /dev/null || fn_erx "${LINENO}"
  [[ ! -f "${exectbl}" ]] && fn_erx "${LINENO}"
fi
[[ "$(type -t "${x}")" != file ]] && fn_erx "${LINENO}"
#exit "${LINENO}"
#set -x

: 'Symlink of "shadow" file' 
if [[ ! -f "${symlnk}" ]]; then
  sudo ln -s "${exectbl}" "${symlnk}" || fn_erx "${LINENO}"
  [[ ! -f "${symlnk}" ]] && fn_erx "${LINENO}"
fi
[[ "$(type -t "${x}")" != file ]] && fn_erx "${LINENO}"
#exit "${LINENO}"
#set -x

: 'Hardlink of "shadow" file' 
if [[ ! -f "${hrdlnk}" ]]; then
  sudo ln "${exectbl}" "${hrdlnk}" || fn_erx "${LINENO}"
  [[ ! -f "${hrdlnk}" ]] && fn_erx "${LINENO}"
fi
[[ "$(type -t "${x}")" != file ]] && fn_erx "${LINENO}"
#exit "${LINENO}"
#set -x

: 'Dangling symlink of "shadow" file' 
if [[ ! -f "${dnglsym}" ]]; then
  sudo cp -b "${exectbl}" "${deldexec}" || fn_erx "${LINENO}"
  sudo ln -s "${deldexec}" "${dnglsym}" || fn_erx "${LINENO}"
  sudo rm -f i--one-file-system --preserve-root=all -- "${deldexec}" || 
    fn_erx "${LINENO}"
  [[ ! -L "${dnglsym}" ]] && fn_erx "${LINENO}"
fi
[[ "$(type -t "${x}")" != file ]] && fn_erx "${LINENO}"
: 'the actual file has been removed so the extra symlink may "dangle"' 
unset 'files[6]'
#ls -alhFi "${dnglsym}" "${deldexec}"
#exit "${LINENO}"
#set -x

: 'Copy inode of "shadow" file'
if [[ ! -f "${cpinod}" ]]; then
  sudo find "${exectbl%/*}" -inum "$(stat -c%i "${exectbl}")" \
    -exec rsync -ac '{}' "${cpinod}" \; || fn_erx "${LINENO}"
  [[ ! -f "${cpinod}" ]] && fn_erx "${LINENO}"
fi
#exit "${LINENO}"
set -x

: 'DAC permissions of "shadow" files' 
for f in "${files[@]}" ; do
  [[ -L "${f}" ]] && continue
  if [[ -f "${f}" ]]; then 
    if ! sudo stat -c%a "${f}" | grep -q 755; then
      sudo chmod 755 "${f}" || fn_erx "${LINENO}"
      sudo stat -c%a "${f}" | grep -q 755 || fn_erx "${LINENO}"
    fi
  fi
done
exit "${LINENO}"
set -x

: 'Builtin' 
if ! enable | grep -q "${x}"; then
  enable "${x}"
  ! enable | grep -q "${x}" || fn_erx "${LINENO}"
fi
[[ "$(type -t "${x}")" != builtin ]] && fn_erx "${LINENO}"
exit "${LINENO}"
set -x

: 'Create "shadow" function' 
if ! declare -pf "${x}" 2> /dev/null | grep -q "${x}"; then
  : 'define function'
  eval function "${x}" '{ echo function bar;}'
  declare -pf "${x}" 2> /dev/null | grep -q "${x}" || fn_erx "${LINENO}"
fi
[[ "$(type -t "${x}")" != function ]] && fn_erx "${LINENO}"
exit "${LINENO}"
set -x

: 'Create "shadow" alias' 
shopt -s expand_aliases
if ! alias "${x}" 2> /dev/null | grep -q "${x}"; then
  eval alias "${x}='{ echo alias foo;}'"
  alias "${x}" 2> /dev/null | grep -q "${x}" || fn_erx "${LINENO}"
fi
[[ "$(type -t "${x}")" != alias ]] && fn_erx "${LINENO}"
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
printf '\n\t declare -p pathdirs # (Same as PATH.) \n\n' 
declare -p pathdirs
printf '\n\t command -pV; command -v \n\n' 
command -pV "${x}"; command -v "${x}"
printf '\n\t find \n\n' 
sudo find / '(' '!' -path '*/1000/*' -a '!' -path '*/zsh/*' -a '!' \
  -path '*/selinux/*' -a '!' -path '*/tracker3/*' ')' '(' \
  -name "${x}" -o -name "${x}_*" ')' 2> /dev/null
printf '\n\t type -a\n\n' 
type -a "${x}"

exit 00

