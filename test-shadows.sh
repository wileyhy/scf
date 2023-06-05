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
PATH+=":/bin"
PATH+=":/usr/local/sbin_dangling_symlink" # < 5
PATH+=":/usr/sbin"
#declare -p PATH
IFS=':' read -ra find_path <<< "${PATH}"
#declare -p find_path

: 'remove any pre-existing "shadow" files for name-string "$x"'
for dirnm in "${find_path[@]}"; do
  fullnm="${dirnm}/${x}"
  if [[ -f "${fullnm}" ]] || [[ -L "${fullnm}" ]]
  then
    sudo rm -f --one-file-system --preserve-root=all -- "${fullnm}" || 
      fn_erx
  fi; unset fullnm
done; unset dirnm

: 'Set up testing of "shadow" files' :
xfa="${find_path[0]}/${x}" # symlink              # < 0
xfb="${find_path[1]}/${x}" # hardlink             # < 1
xfc="${find_path[2]}/${x}" # copy of inode        # < 2
xfd="/usr/bin/${x}"        # executable file      # < 3
xfe="${find_path[5]}/${x}" # dangling symlink     # < 5
xff=("${xfa}" "${xfb}" "${xfc}" "${xfd}" "${xfe}")
#exit "${LINENO}"
#set -x


: 'Tests: Remove certain values' 

: 'Remove: Regular variable' 
unset -v "${x}"

: 'Remove: Namerefs' 
unset -n "${x}"

# This code block: for testing only
: 'Remove: Unused dirs in PATH' 
for abspath in "${xff[@]}"; do
  
  # get dirname
  dirnm="${abspath%/*}"
  
  # if the dir exists...
  if [[ -d "${dirnm}" ]]; then

    # find any FSO's wi it, but only the first 32 bytes thereof...
    fsobjs="$(sudo find "${dirnm}" -mindepth 1 -printf '%p' | head -c 32)"
  fi

  # 
  if [[ -v fsobjs ]]; then   
    if [[ -z "${fsobjs}" ]]; then
      if [[ -d "${dirnm}" ]] && [[ ! -L "${dirnm}" ]]
      then
        sudo rmdir -- "${dirnm}" || 
          fn_erx "${LINENO}"
      fi
    fi 
  fi; unset dirnm fsobjs
done; unset abspath

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
set -x



: 'Create "shadow" variable' 
declare_p_o="$(declare -p "${x}" 2> /dev/null)"
if [[ -z "${declare_p_o:0:8}" ]]; then
  declare "${x}"=quux
  declare_p_o="$(declare -p "${x}" 2> /dev/null)"
  if [[ -z "${declare_p_o}" ]]; then
    fn_erx
  fi
fi; unset declare_p_o
declare -p "${x}"
#exit "${LINENO}"
set -x



: 'Create "shadow" nameref' 
# Note: at equal scope, a variable cannot be a nameref and not a nameref
# at the same time. Setting a nameref overwrites any non-nameref variable.
declare -p UID
decl_awk_o="$(declare -p "${x}" |& awk '$2 ~ /n/')" # is $x a nameref?
if [[ -z "${decl_awk_o:0:8}" ]]; then
  declare -n "${x}"=UID
  # Bug, awk cmd: w no flags from declare, var name could be in $2 and contain 'n'. specify awk regexp. 
  # I still don't trust the shell. In context, the awk command is adequate, but as shell scripts evolve and change, context changes, so commands intended to discern, for example, "is $x a nameref?" should do so completely within themselves - as completely as possible. Assuming `declare -p "${x}"` could return any string (within the possiblities of those normally produced by `declare`), how could `awk '$2 ~ /n/'` go wrong? the variable could be not a nameref, and the variable name could contain the letter 'n', and there you'd have a false positive. 
  # Or is it fame?
  decl_awk_o="$(declare -p "${x}" |& awk '$2 ~ /n/')" # is $x a nameref?
  if [[ -z "${decl_awk_o:0:8}" ]]; then
    fn_erx
  fi
fi; unset decl_awk_o
echo 'UID' "$UID"
echo 'export:' "$export"
declare -p "${x}"
exit "${LINENO}"
set -x



: 'create PATH dirs as necc' 
umask 022
for f in "${xff[@]}"; do
  d="$(dirname "${f}")"
  if [[ ! -d "${d}" ]]; then
    sudo mkdir -p "${d}" || 
      fn_erx "${LINENO}"
  fi; unset d
done; unset f
exit "${LINENO}"
set -x



: 'Create "shadow" executable file' 
if [[ ! -f "${xfa}" ]]; then
  printf '\x23\x21/usr/bin/sh\n%s \x22\x24\x40\x22\n' "${x}" | 
    sudo tee  "${xfa}" > /dev/null || 
      fn_erx "${LINENO}"
  if [[ ! -f "${xfa}" ]]; then
    fn_erx
  fi
fi
if [[ "$(type -t "${x}")" != file ]]; then
  fn_erx "${LINENO}"
fi
exit "${LINENO}"
set -x



: 'Symlink of "shadow" file' 
if [[ ! -f "${xfb}" ]]; then
  sudo ln -s "${xfa}" "${xfb}" || 
    fn_erx "${LINENO}"
  if [[ ! -f "${xfb}" ]]; then
    fn_erx
  fi
fi
if [[ "$(type -t "${x}")" != file ]]; then
  fn_erx "${LINENO}"
fi
exit "${LINENO}"
set -x



: 'Hardlink of "shadow" file' 
if [[ ! -f "${xfc}" ]]; then
  sudo ln "${xfa}" "${xfc}" || 
    fn_erx "${LINENO}"
  if [[ ! -f "${xfc}" ]]; then
    fn_erx
  fi
fi
if [[ "$(type -t "${x}")" != file ]]; then
  fn_erx "${LINENO}"
fi
exit "${LINENO}"
set -x



: 'Dangling symlink of "shadow" file' 
if [[ ! -f "${xfd}" ]]; then
  sudo cp -b "${xfa}" "${xfd}" || 
    fn_erx "${LINENO}"
  if [[ ! -f "${xfd}" ]]; then
    fn_erx
  fi
fi
if [[ ! -f "${xfe}" ]]; then
  sudo ln -s "${xfd}" "${xfe}" || 
    fn_erx "${LINENO}"
  if [[ ! -f "${xfd}" ]]; then
    fn_erx
  fi
  sudo rm -f i--one-file-system --preserve-root=all -- "${xfd}" || 
    fn_erx "${LINENO}"
  if [[ -f "${xfd}" ]]; then
    fn_erx
  fi
fi
if [[ "$(type -t "${x}")" != file ]]; then
  fn_erx "${LINENO}"
fi
: 'the actual file has been removed so the extra symlink may "dangle"' 
unset 'xff[3]'
exit "${LINENO}"
set -x



: 'DAC permissions of "shadow" files' 
for f in "${xff[@]}" ; do
  if [[ -L "${f}" ]]; then
    continue
  fi
  fa="$(sudo stat -c%a "${f}")"
  if [[ "${fa}" != 755 ]]; then
    sudo chmod 755 "${f}" || 
      fn_erx "${LINENO}"
    so="$(sudo stat -c%a "${f}")" || 
      fn_erx "${LINENO}"
    if ! grep -q 755 <<< "${so}"; then
      fn_erx
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

