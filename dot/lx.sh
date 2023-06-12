# Locks


  # <> Obligatory debugging block
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  set -x


# Non-critical 

## Vars & Functions

POSIXLY_CORRECT=0
LC_ALL=C
export POSIXLY_CORRECT LC_ALL
unset IFS

lk_cmds_reqd=( pathchk mv link unlink nice sync timeout stdbuf nohup ps )
lk_cmds_opt=( fuser pgrep )
export lk_cmds_reqd lk_cmds_opt


## <> Reset the FS during debugging

### /dev/shm must exist & remove all previous lock files
d=/dev/shm
if [[ ! -e "$d" ]]; then 
  sudo mkdir -m 1777 "$d" || _erx "${nL}"
else 
  [[ -d "$d" ]] ||  _erx "${nL}"
fi
rm -frv --one-file-system --preserve-root=all -- "${d:?}"/* ||
  _erx "${nL}"
unset d


## Commands 

### Required: if any of these are missing, print an error and exit
hash -r 
for c in "${lk_cmds_reqd[@]}"; do
  lk_cmd_abspth="$(type -P "$c" 2> /dev/null)"
  
  if [[ -z "${lk_cmd_abspth}" ]]; then
    _erx "line: ${nL}, command ${c} is not available."
  fi
done

### Optional: if any of these are missing, print an info message and continue
for c in "${lk_cmds_opt[@]}"; do
  declare -x "lk_cmd_abspth=$(type -P "${c}" 2> /dev/null)"
  
  if [[ -z "$lk_cmd_abspth" ]]; then
    echo "INFO: line: ${nL}, command ${c} is not available." >&2
  else
    declare -x "${c}"="${c}"
  fi
done; unset c lk_cmd_abspth


# Trying

## Verify file names -- using POSIX 2017 functionality
f="/dev/shm/$$_${rand_i}.f"
l="/dev/shm/${repo_nm}"
set -C

for x in "${f}" "${l}"; do
  pathchk -p "${x}" || 
    echo "INFO: line: ${nL}, command pathchk failed." >&2 # <>
  pathchk -P "${x}" || 
    echo "INFO: line: ${nL}, command pathchk failed." >&2 # <>
done; unset x

set -- 'dollar:' "$$" 'BASH:' "$BASH" 'BASH_ARGV0:' "$BASH_ARGV0" 'BASH_SOURCE[@]:' "${BASH_SOURCE[@]}" 'EPOCHREALTIME:' "$EPOCHREALTIME" 'EUID:' "$EUID" 'HOME:' "$HOME" 'PATH:' "$PATH" 'PPID:' "$PPID" 'PWD:' "$PWD" 'SECONDS:' "$SECONDS" 'SHELL:' "$SHELL" 'SHLVL:' "$SHLVL" 'TMPDIR:' "$TMPDIR" 'UID:' "$UID"
printf "%b\n" "$*" > "${f}" || "${Halt:?}" # printf cmd syntax, POSIX 2017
set --

if pathchk "${l}"; then
  
  if link -- "${f}" "${l}"; then
    printf 'Creation of lockfile succeeded.\n'
    if [[ "$f" -ef "$l" ]]; then 
      unlink -- "${f}" || "${Halt:?}"
    fi
  else
    printf 'A lock already exists:\n'
    ls -alhFi "${l}"
    ps aux | grep -e "${script_nm}"
  fi
fi; unset f l


  # <> Obligatory debugging block
  #_full_xtrace
  #: "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


return "${LINENO}"


# Critical




# Exit














# flock mkdir ln pathchk mv link unlink nice lsof fuser stat chattr logger echo pgrep timeout nohup stdbuf ps rm parallel lockfile sync



# Almost certainly atomic operation on Linux ext4 ...but on tmpfs ?? 
# `pathchk` with `set -C` is atomic per POSIX 1003.1-2017
# https://pubs.opengroup.org/onlinepubs/9699919799/utilities/pathchk.html



printf 'Wait for the lock to be freed? [Y/n]\n'
read -r ans
case "$ans" in
  [Yy])
    while :; do
      sleep 60;
      if [[ -e "/dev/shm/${repo_nm}" ]]; then
        continue
      else
        break
      fi;
    done ;;
esac;
unset POSIXLY_CORRECT

# lhunath: "mkdir is not defined to be an atomic operation and as 
#+ such that "side-effect" is an implementation detail of the file 
#+ system"
if mkdir -m 0700 -- "/dev/shm/${repo_nm}" 2> /dev/null; then
  printf 'Creation of lockdir succeeded.\n'

  i="$( for f in "/dev/shm/${repo_nm}"/*; do 
          if [[ -e "$f" ]]; then 
            basename "$f"; 
          else 
            if : > "${f/\*/${i:=$((n))}}"; then 
              export creation_t="${EPOCHSECONDS}"
              printf 'Process file created.\n' 1>&2 
            else
              : 'touch failed'
            fi
          fi;
                  done
    )" _mv_file;


  # for use of `lsof`
  pushd "/dev/shm/${repo_nm}" ||
    "${Halt:?}"
  for f in "/dev/shm/${repo_nm}"/[0-9]*; do
    if [[ -e "$f" ]]; then
      printf 'Racing process exists; exiting.\n'
      head "/dev/shm/${repo_nm}"/*
      exit "${nL}"
    fi
  done
    exit 101
    sleep 60
  unset i f
  # benchmark this syntax
  i="$( for f in "/dev/shm/${repo_nm}"/*; do
          if [[ -e "$f" ]]; then
            basename "$f";
          else
                        # SC2030 (info): Modification of i is local (to subshell caused by $(..) expansion).
            #+ SC2030 (info): Modification of creation_t is local (to subshell caused by $(..) expansion).
            if : > "${f/\*/${i:=$((n))}}"; then
              export creation_t="${EPOCHSECONDS}"
              printf 'Process file created.\n' 1>&2
            else
              : 'touch failed'
            fi
          fi;
        done
    )" _mv_file;


    # benchmark this syntax
  for f in "/dev/shm/${repo_nm}"/*; do
          if [[ -e "$f" ]]; then
            i="$(basename "$f")";
          else
      # trying `: >` vs `touch`
            if : > "${f/\*/${i:=$((n))}}"; then
              export creation_t="${EPOCHSECONDS}"
              printf 'Process file created.\n' 1>&2
            else
              : 'touch failed'
            fi
          fi;
        done
 mv -v "/dev/shm/${repo_nm}/$i" "/dev/shm/${repo_nm}/$((++i))";



  veri_lockfile="${f/\*/$((i))}"
  present_lock_count="$(basename "$veri_lockfile")";
  for f in "/dev/shm/${repo_nm}"/[0-9]*; do
    if [[ -e "$f" ]]; then
      if [[ $present_lock_count -ne 0 ]]; then
        printf 'Racing process exists; exiting.\n'
        exit "${nL}"
      fi
    else
      _erx "${nL}"
    fi;
      done
  [[ -z "$veri_lockfile" ]] \
    && veri_lockfile="/dev/shm/${repo_nm}/0"
  echo "$EPOCHSECONDS,$BASHPID,$PPID" > "/dev/shm/${repo_nm}/pidfile" \
    || _erx "${nL}"
  if mv -f "/dev/shm/${repo_nm}/pidfile" "$veri_lockfile"; then
    printf 'Writing data to process file.\n'
  else
    printf 'Racing process exists; exiting.\n'
    exit "${nL}"
  fi
elif [[ -e "/dev/shm/${repo_nm}" ]]; then
  if [[ -d "/dev/shm/${repo_nm}" ]]; then
    printf 'Creation of lockdir already occurred.\n'
    unset i f
    i="$( for f in "/dev/shm/${repo_nm}"/*; do
            if [[ -e "$f" ]]; then
              basename "$f";
            fi;
          done
    )" _mv_file;
    shopt -s nullglob
        prior_process_files=("/dev/shm/${repo_nm}"/[0-9]*)

    # wrong
    if [[ "${#prior_process_files[@]}" -eq 0 ]]; then


      rm -frv -- "/dev/shm/${repo_nm}"
      printf 'A prior process failed to clean up properly; exiting.\n'
      exit "${nL}"
    fi


    for f in "${prior_process_files[@]}"; do
      if [[ -e "$f" ]]; then
        present_lock_count="$(basename "$f")";
      fi;
      if [[ -s "$f" ]]; then
          #cat $f
        IFS=',' read -r _ bashpid ppid < "$f"
          #declare -p epochseconds bashpid ppid
      fi;
      zero="${0#./}"
      #set -
      ps_o="$(ps aux \
        |& grep -e "${bashpid:='bash'}" -e "${ppid:="${repo_nm}"}" -e "${zero:='.sh'}" \
        |& grep -ve grep -e "${BASHPID}" -e "${PPID}")"

      #set -x
      case "$present_lock_count" in
        0)  if [[ -z "${ps_o}" ]]; then
              if [[ -z "${creation_t}" ]]; then
                _erx "${nL}"
              fi
              printf 'Lockdir left over from previous process.\n'
            else
              printf 'Possible previous process.\n'
              set -
              printf '\t%s\n' "$ps_o"
              #set -x

            fi
            exit "${nL}"
          ;;
        *)  printf 'Likely previous process.\n'
            if [[ -n "${ps_o:0:32}" ]]; then
              set -
              printf '\t%s\n' "$ps_o"
              #set -x
            else
              printf 'No processes other than this one found.\n'
            fi
          ;;
      esac
      printf 'Removing lockdir and exiting.\n'
      rm -frv -- "/dev/shm/${repo_nm}"
      exit "${nL}"
    done
    shopt -u nullglob
  else
    _erx "Possible DOS; probable error. line: ${nL}"
  fi
else
  _erx "${nL}"
fi;
#declare -p f i; ls -a "/dev/shm/${repo_nm}/"; set -;
echo
stat "/dev/shm/${repo_nm}"/[0-9]*;
head "/dev/shm/${repo_nm}"/[0-9]*;
unset f i ps_o
exit 101




  # <> Obligatory debugging block
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  set -x



