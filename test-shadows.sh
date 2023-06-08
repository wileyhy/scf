#!/usr/bin/env -iS bash
# test-shadows.sh - Bash 5 required
#   hellcheck disable=SC2317,SC2096,SC2154,SC2086

: 'Regular users only, and -sudo- required' 
if [[ "$UID" == 0 ]]; then echo May not be root.; exit 1
  elif ! sudo -v; then echo sudo failed.; exit 2
  elif [[ "${BASH_VERSION:0:1}" -lt 5 ]]; then Requires bash 5; exit 3
fi

: 'Target string:'
declare -rx x='export'

: 'Functions, variables and umask' 
function fn_erx(){ local ec="$?"; echo ERROR: "$@"; exit "$ec"; }
LC_ALL=C  
unset PATH 
PATH='/home/liveuser/.local/bin_symlink:/home/liveuser/bin_hardlink:/usr/local/bin_copy-of-inode:/usr/bin:/bin:/usr/local/sbin_dangling_symlink:/usr/sbin'
IFS=':' read -ra pathdirs <<< "$PATH"
verb='-v'
symlnk="${pathdirs[0]}/$x"
hrdlnk="${pathdirs[1]}/$x"
cpinod="${pathdirs[2]}/$x"
exectbl="/usr/bin/$x"
dnglsym="${pathdirs[5]}/$x"
deldexec="${pathdirs[6]}/$x"
files=("$symlnk" "$hrdlnk" "$cpinod" "$exectbl" "$dnglsym" "$deldexec")
umask 022
shopt -s expand_aliases

: 'Additions: "shadow" dirs, etc'
for d in "${files[@]%/*}"; do
  if [[ ! -d "$d" ]]; then
    sudo mkdir -p ${verb} "$d" || fn_erx "$LINENO"
  fi;
done; unset d

if ! declare -p "$x" |& grep -q "$x"; then declare "${x}"=quux; fi
if ! declare -p "$x" |& grep -qE ' -[lrtux]*n[lrtux]*'; then
  declare -n "${x}"=UID
fi
if ! enable | grep -q "$x"; then enable "$x"; fi
if ! alias "$x" 2> /dev/null; then eval alias "$x='{ echo alias foo;}'"; fi
if ! declare -pf "$x" > /dev/null 2>&1; then
  eval function "$x" '{ echo function bar;}'
fi

: 'Additions: "shadow" files, DACs' 
if [[ ! -f "$exectbl" ]]; then
  printf '\x23\x21/usr/bin/sh\n/bin/echo %s \x22\x24\x40\x22\n' "$x" | 
    sudo tee "$exectbl" > /dev/null || fn_erx "$LINENO"
fi
if [[ ! -f "$symlnk" ]]; then
  sudo ln -s ${verb} "$exectbl" "$symlnk" || fn_erx "$LINENO"
fi
if [[ ! -f "$hrdlnk" ]]; then
  sudo ln ${verb} "$exectbl" "$hrdlnk" || fn_erx "$LINENO"
fi
if [[ ! -f "$dnglsym" ]]; then
  sudo cp -b ${verb} "$exectbl" "$deldexec" || fn_erx "$LINENO"
  sudo ln -s ${verb} "$deldexec" "$dnglsym" || fn_erx "$LINENO"
  sudo rm -f ${verb} --one-file-system --preserve-root=all \
    -- "$deldexec" || 
    fn_erx "$LINENO"
fi; unset 'files[6]'
if [[ ! -f "$cpinod" ]]; then
  sudo find "${exectbl%/*}" -inum "$(stat -c%i "$exectbl")" \
    -exec rsync -ac '{}' "$cpinod" \; || fn_erx "$LINENO"
fi

for f in "${files[@]}" ; do
  [[ -L "$f" ]] && continue
  if [[ -f "$f" ]]; then 
    if ! sudo stat -c%a "$f" | grep -q 755; then
      sudo chmod ${verb} 755 "$f" || fn_erx "$LINENO"
    fi
  fi
done

: 'Verification'
printf '\n\t hash -r; hash; type -P \n\n' 
hash -r; hash; type -P "$x"
type_P_o="$(type -P "$x")"
printf '\n\t ls -alhFi [FILE]; ls -alhFiL [FILE] \n\n' 
ls -alhFi --quoting-style=shell-always --color=always "$type_P_o"
ls -alhFiL --quoting-style=shell-always --color=always "$type_P_o"
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

: 'Removals: files, dirs, etc' 
for f in "${files[@]}"; do
  if [[ -f "$f" ]] || [[ -L "$f" ]]; then
    sudo rm -f ${verb} --one-file-system --preserve-root=all -- "$f" || 
      fn_erx "$LINENO"
  fi;
done; unset f

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

unset -v "$x"
unset -n "$x"
unset -f "$x"
[[ "$(enable -a | grep "$x")" != *-n* ]] && enable -n "$x"
unalias "$x" 2> /dev/null

exit 00

