# Locks


  # <> Obligatory debugging block
  #_full_xtrace
  : "${BASH_SOURCE[0]}:${LINENO} ${BASH_SOURCE[1]}:${BASH_LINENO[0]}"
  #exit "${LINENO}"
  set -x


# Vars & Functions
POSIXLY_CORRECT=0
LC_ALL=C
unset IFS
set -C


# Non-critical 

## <> Debugging: remove all previous lock files
rm -frv -- '/dev/shm' ||
  _erx "line: ${LINENO}, command rm failed."

## Commands 
### Required: if any of these are missing, print an error and exit
hash -r
reqd_commands=(pathchk mv link unlink echo set nice sync timeout stdbuf nohup sleep ps)
for c in "${reqd_commands[@]}"; do
  full_path="$(type -P "$c" 2> /dev/null)"
  if [[ -z "$full_path" ]]; then
    _erx "line: ${LINENO}, command ${c} is not available."
  fi
done

### Optional: if any of these are missing, print an info message and continue
optl_commands=(fuser)
for c in "${optl_commands[@]}"; do
  full_path="$(type -P "$c" 2> /dev/null)"
  if [[ -z "$full_path" ]]; then
    echo "INFO: line: ${LINENO}, command ${c} is not available." 2>&
  else
    declare -x "${c}=${c}"
  fi
done; unset c full_path

## /dev/shm must exist
if [[ ! -e /dev/shm ]]; then
  mkdir -m 1777 /dev/shm ||
   _erx "${LINENO}"
fi

## <?> retained for POSIX 2017 functionality
pathchk -p /dev/shm || 
  echo "INFO: line: ${LINENO}, command pathchk failed." 2>& # <>
pathchk -P /dev/shm || 
  echo "INFO: line: ${LINENO}, command pathchk failed." 2>& # <>


# Trying
f="/dev/shm/$$_${rand_i}.f"
l="/dev/shm/${repo_nm}"
set -- "${f}"
printf "%b\n" "$*" || "${Halt:?}" # printf cmd per POSIX 2017
set --

if pathchk "${l}"; then
  if link -- "${f}" "${l}" ; then
    printf 'Creation of lockfile succeeded.\n'
    unlink -- "${f}" || "${Halt:?}"
  else
    printf 'A lock already exists:\n'
    ls -alhFi "${l}"
    fuser_o="$(fuser -v "${l}")"
    printf '%s\n' "${fuser_o}"
    fuser_pid="$(tail -n1 <<< "${fuser_o}" | awk '{ printf $2 }')"
    ps aux | grep "${fuser_pid}"
  fi
fi


  # <> Obligatory debugging block
  #_full_xtrace
  : "${BASH_SOURCE[0]}:${LINENO} ${BASH_SOURCE[1]}:${BASH_LINENO[0]}"
  exit "${LINENO}"
  set -x





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
      exit "${LINENO}"
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
        exit "${LINENO}"
      fi
    else
      _erx "${LINENO}"
    fi;
      done
  [[ -z "$veri_lockfile" ]] \
    && veri_lockfile="/dev/shm/${repo_nm}/0"
  echo "$EPOCHSECONDS,$BASHPID,$PPID" > "/dev/shm/${repo_nm}/pidfile" \
    || _erx "${LINENO}"
  if mv -f "/dev/shm/${repo_nm}/pidfile" "$veri_lockfile"; then
    printf 'Writing data to process file.\n'
  else
    printf 'Racing process exists; exiting.\n'
    exit "${LINENO}"
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
      exit "${LINENO}"
    fi


    for f in "${prior_process_files[@]}"; do
      if [[ -e "$f" ]]; then
        present_lock_count="$(basename "$f")";
      fi;
      if [[ -s "$f" ]]; then
          #cat $f
        IFS=',' read -r epochseconds bashpid ppid < "$f"
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
                _erx "${LINENO}"
              fi
              printf 'Lockdir left over from previous process.\n'
            else
              printf 'Possible previous process.\n'
              set -
              printf '\t%s\n' "$ps_o"
              #set -x

            fi
            exit "${LINENO}"
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
      exit "${LINENO}"
    done
    shopt -u nullglob
  else
    _erx "Possible DOS; probable error. line: ${LINENO}"
  fi
else
  _erx "${LINENO}"
fi;
#declare -p f i; ls -a "/dev/shm/${repo_nm}/"; set -;
echo
stat "/dev/shm/${repo_nm}"/[0-9]*;
head "/dev/shm/${repo_nm}"/[0-9]*;
unset f i ps_o
exit 101




  # <> Obligatory debugging block
  #_full_xtrace
  : "${BASH_SOURCE[0]}:${LINENO} ${BASH_SOURCE[1]}:${BASH_LINENO[0]}"
  #exit "${LINENO}"
  set -x



