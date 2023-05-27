#!/usr/bin/bash
#!/usr/bin/env -iS bash -x
# shellcheck disable=SC2316,SC2312,SC2317
# add-shadows.bsh


:;: 'Regular users only, and -sudo- required' :;:
if [[ "${UID}" == 0 ]]; then
  printf '\n\t Must be a regular user and use sudo. \n\n'
  exit 1
elif ! sudo -v; then
  printf '\n\t Validation failed of user\x27s \x60sudo\x60 timestamp. '
  printf 'Exiting.\n\n'
  exit "${LINENO}"
fi

:;: 'Target string:' :;:
set -vx
x="${1:='export'}"
readonly x
declare -p x
enable -n "$x"
exit 101

:;: 'Required programs' ;:;
[[ "${BASH_VERSION:0:1}" -lt 5 ]] \
  || echo Please install Bash version 5, thanks.

reqd_cmds=( awk chmod cp cut dirname find grep ln ls 
  mkdir rm rmdir stat sudo tee )
yn=n

for c in "${reqd_cmds[@]}"; do 
  hash -r; 
  if ! type -P "${c}" > /dev/null; then 
    yn+=" ${c}"
  fi; 
done; unset c reqd_cmds

if [[ "${yn}" == 'n' ]]; then 
  : 'No additional commands are required'
else 
  printf '\n\t Please install the following commands: \n\t   %s \n\n' \
    "${yn#n }"
  exit 1
fi; unset yn
#exit 101
#set -x


:;: 'Functions, variables and umask' :;:
function fn_erx(){
  # shellcheck disable=SC2319
  local ec="${?}"
  echo ERROR: "${@}"
  exit "${ec}"
}

unset PATH 
PATH="/home/liveuser/.local/bin_symlink"  # < 0
PATH+=":/home/liveuser/bin_hardlink"      # < 1
PATH+=":/usr/local/bin_copy-of-inode"     # < 2
PATH+=":/usr/bin"
PATH+=":/bin"
PATH+=":/usr/local/sbin_dangling_symlink" # < 5
PATH+=":/usr/sbin"
#declare -p PATH

: 'Set up testing of PATH dirs' :
IFS=':' read -ra find_path <<< "${PATH}"
#declare -p find_path

for dnm in "${find_path[@]}"; do
  nm="${dnm}/${x}"
  if [[ -f "${nm}" ]] \
    || [[ -L "${nm}" ]]
  then
    sudo rm -f --one-file-system --preserve-root=all -- "${nm}" \
      || fn_erx
  fi; unset nm; :
done; unset dnm; :

: 'Set up testing of files' :
xfa="/usr/bin/${x}"
xfb="${find_path[0]}/${x}" # symlink
xfc="${find_path[1]}/${x}" # hardlink
xfd="${find_path[2]}/${x}" # copy of inode
xfe="${find_path[5]}/${x}" # dangling symlink
xff=("${xfa}" "${xfb}" "${xfc}" "${xfd}" "${xfe}")
umask 022
#exit 101
set -x


:;: 'Tests: Remove certain values' :;:

:;: 'Remove: Regular variable' :;:
unset -v "${x}"

:;: 'Remove: Namerefs' :;:
unset -n "${x}"

# This code block: for testing only
:;: 'Remove: Unused dirs in PATH' :;:
for f in "${xff[@]}"; do
  d="$(dirname "${f}")"
  if [[ -d "${d}" ]]; then
    lo="$(sudo find "${d}" -mindepth 1 -printf '%p' \
      | head -c 32
    )"
  fi
  if [[ -z "${lo:0:32}" ]]; then
    if [[ -d "${d}" ]] \
      && [[ ! -L "${d}" ]]
    then
      sudo rmdir -- "${d}" \
        || fn_erx "${LINENO}"
    fi
  fi; unset d lo; :
done; unset f; :

:;: 'Remove: Builtin' :;:
enable -n "${x}"

:;: 'Remove: Function' :;:
unset -f "${x}"

:;: 'Remove: Alias' :;:
unalias -a 
exit 101
#set -x



:;: 'Create Shadow variable' :;:
dpo="$(declare -p "${x}" 2> /dev/null)"
if [[ -z "${dpo:0:8}" ]]; then
  eval "${x}"=quux
  dpo="$(declare -p "${x}")"
  if [[ -z "${dpo:0:8}" ]]; then
    fn_erx
  fi
fi; unset dpo
#exit 101
#set -x



:;: 'Create Shadow nameref' :;:
dao="$(declare -p "${x}" \
  | awk '$2 ~ /n/'
)"
if [[ -z "${dao:0:8}" ]]; then
  declare -n "${x}"=USER
  dao="$(declare -p "${x}" \
    | awk '$2 ~ /n/'
  )"
  if [[ -z "${dao:0:8}" ]]; then
    fn_erx
  fi
fi; unset dao
#exit 101
#set -x



:;: 'create PATH dirs as necc' :;:
for f in "${xff[@]}"; do
  d="$(dirname "${f}")"
  if [[ ! -d "${d}" ]]; then
    sudo mkdir -p "${d}" \
      || fn_erx "${LINENO}"
  fi; unset d; :
done; unset f; :
#exit 101
#set -x



:;: 'Create Shadow executable file' :;:
if [[ ! -f "${xfa}" ]]; then
  printf '\x23\x21/usr/bin/sh\n%s \x22\x24\x40\x22\n' "${x}"\
    | sudo tee  "${xfa}" > /dev/null \
    || fn_erx "${LINENO}"
  if [[ ! -f "${xfa}" ]]; then
    fn_erx
  fi
fi
if [[ "$(type -t "${x}")" != file ]]; then
  fn_erx "${LINENO}"
fi
#exit 101
#set -x



:;: 'Symlink of shadow file' :;:
if [[ ! -f "${xfb}" ]]; then
  sudo ln -s "${xfa}" "${xfb}" \
    || fn_erx "${LINENO}"
  if [[ ! -f "${xfb}" ]]; then
    fn_erx
  fi
fi
if [[ "$(type -t "${x}")" != file ]]; then
  fn_erx "${LINENO}"
fi
#exit 101
#set -x



:;: 'Hardlink of shadow file' :;:
if [[ ! -f "${xfc}" ]]; then
  sudo ln "${xfa}" "${xfc}" \
    || fn_erx "${LINENO}"
  if [[ ! -f "${xfc}" ]]; then
    fn_erx
  fi
fi
if [[ "$(type -t "${x}")" != file ]]; then
  fn_erx "${LINENO}"
fi
#exit 101
#set -x



:;: 'Dangling symlink of shadow file' :;:
if [[ ! -f "${xfd}" ]]; then
  sudo cp -b "${xfa}" "${xfd}" \
    || fn_erx "${LINENO}"
  if [[ ! -f "${xfd}" ]]; then
    fn_erx
  fi
fi
if [[ ! -f "${xfe}" ]]; then
  sudo ln -s "${xfd}" "${xfe}" \
    || fn_erx "${LINENO}"
  if [[ ! -f "${xfd}" ]]; then
    fn_erx
  fi
  sudo rm -f i--one-file-system --preserve-root=all -- "${xfd}" \
    || fn_erx "${LINENO}"
  if [[ -f "${xfd}" ]]; then
    fn_erx
  fi
fi
if [[ "$(type -t "${x}")" != file ]]; then
  fn_erx "${LINENO}"
fi
:;: 'the actual file has been removed so the extra symlink may "dangle"' :;:
unset 'xff[3]'
#exit 101
#set -x



:;: 'DAC permissions of shadow files' :;:
for f in "${xff[@]}" ; do
  if [[ -L "${f}" ]]; then
    continue
  fi
  fa="$(sudo stat -c%a "${f}")"
  if [[ "${fa}" != 755 ]]; then
    sudo chmod 755 "${f}" \
      || fn_erx "${LINENO}"
    so="$(sudo stat -c%a "${f}")" \
      || fn_erx "${LINENO}"
    if ! grep -q 755 <<< "${so}"; then
      fn_erx
    fi
  fi; :
done; :
#exit 101
#set -x



:;: 'Builtin' :;:
eago="$(enable \
  | grep "${x}"
)"
if [[ -z "${eago:0:8}" ]]; then
  enable "${x}"
  eago="$(enable \
    | grep "${x}"
  )"
  if [[ -z "${eago:0:8}" ]]; then
    fn_erx
  fi
fi; unset eago
if [[ "$(type -t "${x}")" != builtin ]]; then
  fn_erx "${LINENO}"
fi
#exit 101
#set -x



:;: 'Create Shadow function' :;:
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
#exit 101
#set -x



:;: 'Create Shadow alias' :;:
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
#exit 101
#set -x



:;: 'Verification 1: type -P' :;:
printf '\n\t hash -r; hash; type -P \n\n' 
hash -r; hash; type -P "${x}" 
type_P_o="$(type -P "${x}")"
printf '\n\t ls -alhFi [FILE]; ls -alhFiL [FILE] \n\n' 
ls -alhFi --quoting-style=shell-always --color=always "${type_P_o}"
ls -alhFiL --quoting-style=shell-always --color=always "${type_P_o}"
#exit 101
#set -x



:;: 'Verification 2: type -a' :;:
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

