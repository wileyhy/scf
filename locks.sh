# Locks
# shellcheck shell=bash


# TODO: resolve approaches, prior w lockdirs and current w lockfiles
#   Prev: "use lock dir as main_d"

### Transfers from ./fndsc

a_poss_proces_lock_dirs+=("/dev/shm/${scr_scr_repo_nm}" /var/lock \
  "${XDG_RUNTIME_DIR}" "${TMPDIR}" /var/lock "${HOME}" /tmp \
  /var/tmp)

_get_lockdirs(){
  #_full_xtrace
  local -gax lkdrs

  mapfile -d '' -t lkdrs < <(
    sudo find "${a_poss_proces_lock_dirs[@]}" \
      -mindepth 1 -maxdepth 1 \( \
      -type d -o -type l \) \( \
      -name '*lock*' -a -name '*scf*' \) \
      -print0 2> /dev/null
  )
  #export lkdrs
}

_exit_trap() {
  #set -x
  : "EXIT trap BEGINS" "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  trap - DEBUG
  trap - EXIT
  # If no such array exists yet, then search for possible lockdirs
  if ! declare -pa lkdrs 2> /dev/null 1>&2; then
    : 'lkdrs DNE'
    _get_lockdirs
    declare -p lkdrs
  else
    : 'lkdrs exists'
  fi
  # Delete all possible existing process _lock_directories_.
  for pld in "${lkdrs[@]}"; do
    # test and delete lock directories.
    if [[ -d "${pld}" ]] && [[ ! -L "${pld}" ]]; then
      echo sudo rm --one-file-system --preserve-root=all -rfv -- \
        "${pld}" \
        || exit "${nL}"
    fi
  done && unset pld
    # <>
    #: "${Halt?}"
  command -p kill -s INT "$$"
}
trap _exit_trap EXIT TERM
#_full_xtrace
#exit "$nL"

: 'Process Lock'

#   So, what's the critical section?  For now, its the main `find`
# command. The script can take so much time to execute, running
# more than one process at once is wasteful of system resources.


: 'Variables for Traps and Process Locks'

declare -A A_process_lock_dirs
#a_poss_proces_lock_dirs+=("${XDG_RUNTIME_DIR}" "${TMPDIR}" /var/lock \
#  "${HOME}" /tmp /var/tmp)
i=0
#pld="" # SC2155
#scr_tcode="$(builtin printf '%(%F_%H%M%S)T')"

#   The purpose of listing so many possible lock locations is that who
# knows which of these directory locations will exist on disk whenever
# down the road. The issue with including world-writeable dirs such as
# /tmp is that /tmp is a consistent part of the Linux file structure,
# and that probably isn't going to change any time soon. The notion
# behind creating lockdirs, whose names include random number strings
# according to a template, is to foil the predictability, and hence
# the risk of DOS, that placing a (statically named) lock mechanism in
# a world-writeable directory creates. The idea being, if the template
# is unique enough that accurately predicting it will be impractical....
# So,
  : 'Form of filenames for process lock dirs:'
  : $'\t' "/tmp/.${scr_scr_repo_nm}.${$}.${rand_i}.lock.d"
#   Still, the issue occurs of the race condition. Since the filename
# changes, the advantage of the atomicity of using `mkdir` is lost....
# or is it?
#   So what if you just create a lockdir first, according to the
# template, then look for other lockdirs, and based on the info in the
# found lockdirs' xattrs, determine whether a duplicate process is
# running?
#   It seems like that could possibly work, although the entire script
# down to plausible filenames could be reconstructed, but for
# practicality.

# Bug: is there a simpler way to do this section?

# An associative array, in case TMPDIR duplicates another array value
for v in "${a_poss_proces_lock_dirs[@]}"; do
  if [[ -d "${v}" ]]; then
    v="$(realpath -e "${v}")"
    A_process_lock_dirs+=( ["${v}/${rand_lock_nm}"]=$((i++)) )
  fi
done; unset i v

for i in "${!A_process_lock_dirs[@]}"; do
  a_process_lock_dirs+=( ["${A_process_lock_dirs[$i]}"]="$i" );
done; unset A_process_lock_dirs i

#_full_xtrace
#exit "${nL}"


# Bug: race condition btw defining and mkdir?

: 'Process Lock: Define and create the lockdir'

#target_fso=d

for poss_lk_d in "${a_process_lock_dirs[@]}"; do

  #case "${target_fso}" in
    #d)
      if
        #sudo find "${poss_lk_d%/*}" -maxdepth 0 '(' \
        #-type d -a '!' -type l ')' -writable -readable -executable \
        #-true -exec

        sudo mkdir -vm 0700 "${poss_lk_d}";
      then
        process_lock_d="${poss_lk_d}"
        break
        #target_fso=L
      else
		printf '\t\nA filesystem object already exists at %s\n\n' "${poss_lk_d}"
		file "${poss_lk_d}"
		stat "${poss_lk_d}"
		fuser "${poss_lk_d}"
		ls -alhFiR "${poss_lk_d}"
		continue
      fi
      #;;

    # ln cannot make hardlinks to dirs; chattr -i not supported
    #L)
      #sudo find "${poss_lk_d%/*}" -maxdepth 0 '(' \
        #-type d -a '!' -type l ')' -writable -readable -executable \
        #-true -exec sudo ln -vs "${process_lock_d}" "${poss_lk_d}" ';'
      #;;
  #esac
done

  # Bug: for some reason, the lockdir gets deleted while the
  # symlinks stay put.

  #shopt -o functrace
  #"${Halt:?}"

for poss_lk_d in "${a_process_lock_dirs[@]}"; do
  # use the first one that fulfills certain requirements
  mapfile -d '' -t find_out < <(
    find "${poss_lk_d}" -maxdepth 0 '(' \
    -type d -a '!' -type l ')' -writable -readable -executable \
    -exec mkdir -m 0700 '()' ';'
  )

  : 'Process Lock: Create a lockdir and handle any error'
  if [[ -n "${find_out[0]}" ]]; then

	# x solved x - Bug: $find_out will expand to mult filenames

    if mkdir -m 0700 "${process_lock_d:="${find_out[0]}"}" 2>/dev/null; then
      break
    else
      continue
    fi

  else
    {
      printf '\n\tCannot acquire process lock: <%s>.\n' "${process_lock_d}"
      printf 'Exiting.\n\n'
    } 1>&2
    #exit "${nL}"
  fi
done


: 'Process Lock: Search for existing lockdirs'

declare -p a_process_lock_dirs
_get_lockdirs

# Bug: loop var: the lower case L looks like the number 1

for l in "${lkdrs[@]}"; do

  # for dirs or syms
  if [[ -d "${l}" ]] \
    || [[ -L "${l}" ]]
  then

    if [[ -v rm_locks ]]; then

      # `rmdir` doesn't remove symlinks
      sudo rmdir -v -- "${l}"
    else
      printf '\n\t A process lock exists for this script. Exiting '
      printf 'now.\n\n'
      #exit "${nL}"
    fi
  fi
done; unset l # lkdrs # a_poss_proces_lock_dirs # lkdrs_count

# Note: rm_locks is an undocumented CLI option
if [[ -v rm_locks ]] \
  && [[ -n ${lkdrs[*]:0:16} ]];
then
  exit "${nL}"
fi

#exit "${nL}"
#_full_xtrace





# New section ==================================


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

### /dev/shm must exist
d=/dev/shm
if [[ ! -e "$d" ]]; then 
  sudo mkdir -m 1777 "$d" || _erx "${nL}"
else 
  [[ -d "$d" ]] ||  _erx "${nL}"
fi; unset d

### remove all previous lock files
#### Note: rm_locks is an undocumented CLI option
if [[ -v rm_locks ]]; then
  rm -frv --one-file-system --preserve-root=all -- "${d:?}"/* || 
    _erx "${nL}"
fi


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
l="/dev/shm/${scr_scr_repo_nm}"
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
    ps aux | grep -e "${scr_nm}"
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
exit "${nL}"











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
      if [[ -e "/dev/shm/${scr_scr_repo_nm}" ]]; then
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
if mkdir -m 0700 -- "/dev/shm/${scr_scr_repo_nm}" 2> /dev/null; then
  printf 'Creation of lockdir succeeded.\n'

  i="$( for f in "/dev/shm/${scr_scr_repo_nm}"/*; do 
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
  pushd "/dev/shm/${scr_scr_repo_nm}" ||
    "${Halt:?}"
  for f in "/dev/shm/${scr_scr_repo_nm}"/[0-9]*; do
    if [[ -e "$f" ]]; then
      printf 'Racing process exists; exiting.\n'
      head "/dev/shm/${scr_scr_repo_nm}"/*
      exit "${nL}"
    fi
  done
    exit 101
    sleep 60
  unset i f
  # benchmark this syntax
  i="$( for f in "/dev/shm/${scr_scr_repo_nm}"/*; do
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
  for f in "/dev/shm/${scr_scr_repo_nm}"/*; do
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
 mv -v "/dev/shm/${scr_scr_repo_nm}/$i" "/dev/shm/${scr_scr_repo_nm}/$((++i))";



  veri_lockfile="${f/\*/$((i))}"
  present_lock_count="$(basename "$veri_lockfile")";
  for f in "/dev/shm/${scr_scr_repo_nm}"/[0-9]*; do
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
    && veri_lockfile="/dev/shm/${scr_scr_repo_nm}/0"
  echo "$EPOCHSECONDS,$BASHPID,$PPID" > "/dev/shm/${scr_scr_repo_nm}/pidfile" \
    || _erx "${nL}"
  if mv -f "/dev/shm/${scr_scr_repo_nm}/pidfile" "$veri_lockfile"; then
    printf 'Writing data to process file.\n'
  else
    printf 'Racing process exists; exiting.\n'
    exit "${nL}"
  fi
elif [[ -e "/dev/shm/${scr_scr_repo_nm}" ]]; then
  if [[ -d "/dev/shm/${scr_scr_repo_nm}" ]]; then
    printf 'Creation of lockdir already occurred.\n'
    unset i f
    i="$( for f in "/dev/shm/${scr_scr_repo_nm}"/*; do
            if [[ -e "$f" ]]; then
              basename "$f";
            fi;
          done
    )" _mv_file;
    shopt -s nullglob
        prior_process_files=("/dev/shm/${scr_scr_repo_nm}"/[0-9]*)

    # wrong
    if [[ "${#prior_process_files[@]}" -eq 0 ]]; then


      rm -frv -- "/dev/shm/${scr_scr_repo_nm}"
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
        |& grep -e "${bashpid:='bash'}" -e "${ppid:="${scr_scr_repo_nm}"}" -e "${zero:='.sh'}" \
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
      rm -frv -- "/dev/shm/${scr_scr_repo_nm}"
      exit "${nL}"
    done
    shopt -u nullglob
  else
    _erx "Possible DOS; probable error. line: ${nL}"
  fi
else
  _erx "${nL}"
fi;
#declare -p f i; ls -a "/dev/shm/${scr_scr_repo_nm}/"; set -;
echo
stat "/dev/shm/${scr_scr_repo_nm}"/[0-9]*;
head "/dev/shm/${scr_scr_repo_nm}"/[0-9]*;
unset f i ps_o
exit 101




  # <> Obligatory debugging block
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  set -x




