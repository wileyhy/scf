#!/usr/bin/env -iS bash
# test-shadows.sh
#   shellcheck disable=SC2317 # unreachable commands
#   shellcheck disable=SC2096 # excessive crashbang
# Bash 5 required

: 'Regular users only, and -sudo- required' 
if [[ "$UID" == 0 ]]; then
  printf '\n\t Must be a regular user and use sudo. \n\n'
  exit "$LINENO"
elif ! sudo -v; then
  printf '\n\t Validation failed of user\x27s \x60sudo\x60 timestamp. '
  printf 'Exiting.\n\n'
  exit "$LINENO"
fi

: 'Target string:' 
LC_ALL=C  
shopt -s expand_aliases
if [[ "$#" -eq 0 ]]; then x='export'; else x="$1"; fi;
[[ -n "$x" ]] && declare -rx x
unset Halt && declare -rx Halt
verb='-v' 
umask 022

: 'Required programs'
if [[ "${BASH_VERSION:0:1}" -lt 5 ]]; then 
  echo Please install Bash version 5, thanks.
  exit "$LINENO"
fi

reqd_cmds=( awk chmod cp cut dirname find grep ln ls mkdir rm rmdir 
  stat sudo tee )
yn=n

hash -r; 
for c in "${reqd_cmds[@]}"; do 
  type_P_o="$(type -P "$c")"
  if [[ -n "$type_P_o" ]]; then 
    hash -p "$type_P_o" "$c"
  else
    yn=y
    list+=("$c")
  fi; 
done; unset c reqd_cmds type_P_o

if [[ "$yn" == 'n' ]]; then 
  : 'No additional commands are required'
else
  printf '\n\t Please install the following commands:\n'
  printf '\t\t%s\n' "${list[@]}" 
  echo
  exit "$LINENO"
fi; unset yn list


: 'Functions, variables and umask' 
function fn_erx(){
  local ec="$?"
  echo ERROR: "$@"
  exit "$ec"
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
IFS=':' read -ra pathdirs <<< "$PATH"

: 'Set up testing of "shadow" files' :
symlnk="${pathdirs[0]}/$x"    # symlink              # < 0
hrdlnk="${pathdirs[1]}/$x"    # hardlink             # < 1
cpinod="${pathdirs[2]}/$x"    # copy of inode        # < 2
exectbl="/usr/bin/$x"         # executable file      # < 3
dnglsym="${pathdirs[5]}/$x"   # dangling symlink     # < 5
deldexec="${pathdirs[6]}/$x"  # deleted executable   # < 6
files=("$symlnk" "$hrdlnk" "$cpinod" "$exectbl" "$dnglsym" "$deldexec")


: 'Remove:'

: 'Remove: Regular variable' 
unset -v "$x"

: 'Remove: Namerefs' 
unset -n "$x"

: 'Remove: any previous test files'
for f in "${files[@]}"; do
  if [[ -f "$f" ]] || [[ -L "$f" ]]; then
    sudo rm -f ${verb} --one-file-system --preserve-root=all -- "$f" || 
      fn_erx "$LINENO"
  fi;
done; unset f
  #set -x # <>

: 'Remove: Unused dirs in PATH' 
for d in "${files[@]}"; do
  while :; do
    d="${d%/*}"
    if [[ -d "$d" ]]; then 
      fsobj="$(find "$d" -mindepth 1 -maxdepth 1 |& 
        tr -d '\n' |& head -c32)" 
      if [[ -z "$fsobj" ]] && [[ ! -L "$d" ]]; then
        sudo rmdir ${verb} --ignore-fail-on-non-empty -- "$d" || 
          fn_erx "$LINENO"
      else
        break
      fi
    fi
  done
done; unset d fsobj

: 'Remove: Builtin' 
[[ "$(enable -a | grep "$x")" != *-n* ]] && enable -n "$x"

: 'Remove: Function' 
unset -f "$x"

: 'Remove: Alias' 
unalias "$x"

: 'Create:'

: 'Create: "shadow" variable' 
if ! declare -p "$x" |& grep -q "$x"; then
  declare "${x}"=quux
  declare -p "$x" |& grep -q "$x" || fn_erx "$LINENO"
fi
  #set -x # <>

: 'Create: "shadow" nameref' 
  #declare -p $x # <>
#if ! declare -p "$x" |& awk '$2 ~ /^-[lrtux]*n[lrtux]*/'; then
if ! declare -p "$x" |& awk '{ print $2 }' | grep -qE '^-[lrtux]*n[lrtux]*'
then
  declare -n "${x}"=UID
    #declare -p $x # <>
  #declare -p "$x" |& awk '$2 ~ /^-[lrtux]*n[lrtux]*/' || fn_erx "$LINENO"
  declare -p "$x" |& awk '{ print $2 }' | grep -qE '^-[lrtux]*n[lrtux]*' ||
    fn_erx "$LINENO"
fi
  #exit $LINENO # <>
  #set -x # <>

: 'Create: PATH dirs as necc' 
for d in "${files[@]%/*}"; do
  if [[ ! -d "$d" ]]; then
    sudo mkdir -p ${verb} "$d" || fn_erx "$LINENO"
  fi;
done; unset d

: 'Create: "shadow" executable file' 
if [[ ! -f "$exectbl" ]]; then
  printf '\x23\x21/usr/bin/sh\n%s \x22\x24\x40\x22\n' "$x" | 
    sudo tee "$exectbl" > /dev/null || fn_erx "$LINENO"
  [[ ! -f "$exectbl" ]] && fn_erx "$LINENO"
fi
[[ "$(type -t "$x")" != file ]] && fn_erx "$LINENO"

: 'Create: symlink of "shadow" file' 
if [[ ! -f "$symlnk" ]]; then
  sudo ln -s ${verb} "$exectbl" "$symlnk" || fn_erx "$LINENO"
  [[ ! -f "$symlnk" ]] && fn_erx "$LINENO"
fi
[[ "$(type -t "$x")" != file ]] && fn_erx "$LINENO"

: 'Create: hardlink of "shadow" file' 
if [[ ! -f "$hrdlnk" ]]; then
  sudo ln ${verb} "$exectbl" "$hrdlnk" || fn_erx "$LINENO"
  [[ ! -f "$hrdlnk" ]] && fn_erx "$LINENO"
fi
[[ "$(type -t "$x")" != file ]] && fn_erx "$LINENO"

: 'Create: dangling symlink of "shadow" file' 
if [[ ! -f "$dnglsym" ]]; then
  sudo cp -b ${verb} "$exectbl" "$deldexec" || fn_erx "$LINENO"
  sudo ln -s ${verb} "$deldexec" "$dnglsym" || fn_erx "$LINENO"
  sudo rm -f ${verb} --one-file-system --preserve-root=all \
    -- "$deldexec" || 
    fn_erx "$LINENO"
  [[ ! -L "$dnglsym" ]] && fn_erx "$LINENO"
fi
[[ "$(type -t "$x")" != file ]] && fn_erx "$LINENO"
: 'the actual file has been removed so the extra symlink may "dangle"' 
unset 'files[6]'

: 'Create: copy inode of "shadow" file'
if [[ ! -f "$cpinod" ]]; then
  sudo find "${exectbl%/*}" -inum "$(stat -c%i "$exectbl")" \
    -exec rsync -ac '{}' "$cpinod" \; || fn_erx "$LINENO"
  [[ ! -f "$cpinod" ]] && fn_erx "$LINENO"
fi
  #set -x # <>

: 'Correct: DAC permissions of "shadow" files' 
for f in "${files[@]}" ; do
  [[ -L "$f" ]] && continue
  if [[ -f "$f" ]]; then 
    if ! sudo stat -c%a "$f" | grep -q 755; then
      sudo chmod ${verb} 755 "$f" || fn_erx "$LINENO"
      sudo stat -c%a "$f" | grep -q 755 || fn_erx "$LINENO"
    fi
  fi
done
  #exit "$LINENO" # <>
  #set -x # <>

: 'Enable: builtin'
  #enable -ap | grep $x # <>
if ! enable | grep -q "$x"; then
  enable "$x"
    #enable -ap | grep $x # <>
    #: "${Halt:?}" # <>
  enable | grep -q "$x" || fn_erx "$LINENO"
fi
[[ "$(type -t "$x")" != builtin ]] && fn_erx "$LINENO"
  #exit "$LINENO" # <>
  #set -x # <>

: 'Create: "shadow" function' 
  #declare -pf $x # <>
if ! declare -pf "$x" > /dev/null 2>&1; then
    #echo exit, decl-grep pipeline $? # <>
    #: 'define function' # <>
  eval function "$x" '{ echo function bar;}'
    #declare -pF $x # <>
  declare -pf "$x" > /dev/null 2>&1 || fn_erx "$LINENO"
fi
  #type -a $x # <>
[[ "$(type -t "$x")" != function ]] && fn_erx "$LINENO"
  #exit "$LINENO" # <>
  set -x # <>

: 'Create: "shadow" alias' 
if ! alias "$x" |& grep -q "$x"; then
  eval alias "${x}='{ echo alias foo;}'"
  alias "$x" |& grep -q "$x" || fn_erx "$LINENO"
fi
[[ "$(type -t "$x")" != alias ]] && fn_erx "$LINENO"
  exit "$LINENO" # <>
  set -x # <>

: 'Verification'

: 'Verification 1: type -P' 
printf '\n\t hash -r; hash; type -P \n\n' 
hash -r; hash; type -P "$x"
type_P_o="$(type -P "$x")"
printf '\n\t ls -alhFi [FILE]; ls -alhFiL [FILE] \n\n' 
ls -alhFi --quoting-style=shell-always --color=always "$type_P_o"
ls -alhFiL --quoting-style=shell-always --color=always "$type_P_o"
  exit "$LINENO" # <>
  set -x # <>

: 'Verification 2: type -a' 
printf '\n\t declare -p pathdirs # (Same as PATH.) \n\n' 
declare -p pathdirs
printf '\n\t command -pV; command -v \n\n' 
command -pV "$x"; command -v "$x"
printf '\n\t find \n\n' 
sudo find / '(' '!' -path '*/1000/*' -a '!' -path '*/zsh/*' -a '!' \
  -path '*/selinux/*' -a '!' -path '*/tracker3/*' ')' '(' \
  -name "$x" -o -name "${x}_*" ')' 2> /dev/null
printf '\n\t type -a\n\n' 
type -a "$x"

exit 00

