# Locks
# shellcheck shell=bash


  # <> Obligatory debugging block
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  post_src "${nBS[0]}" "${nL}" "$@"
  #x_trace
  #: "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


# TODO: resolve approaches, prior w lockdirs and current w lockfiles
#   Prev: "use lock dir as main_d"

### Transfers from ./fndsc

a_poss_proces_lock_dirs+=( "/dev/shm/${scr_repo_nm}" /var/lock
  "${XDG_RUNTIME_DIR}" "${TMPDIR}" /var/lock "${HOME}" /tmp
  /var/tmp )
lkdrs=() export lkdrs

get_lockdirs(){ :
  : "get_lockdirs BEGINS ${fn_bndry} ${fn_lvl}>$(( ++fn_lvl ))"
  #x_trace
  local -I lkdrs

  mapfile -d '' -t lkdrs < <(
    sudo find "${a_poss_proces_lock_dirs[@]}" \
      -mindepth 1 -maxdepth 1 \( \
      -type d -o -type l \) \( \
      -name '*lock*' -a -name '*scf*' \) \
      -print0 2>&1
  )
  : "get_lockdirs ENDS ${fn_bndry} ${fn_lvl}>$(( ++fn_lvl ))"
}

exit_trap(){ :

    # <>
    #set -x

  : "EXIT trap BEGINS ${fn_bndry} ${fn_lvl}>$(( ++fn_lvl ))"
  trap - DEBUG
  trap - EXIT

  local pld

  # If no such array exists yet, then search for possible lockdirs
  if [[ "${#lkdrs[@]}" -eq 0 ]]
  then
    : 'lkdrs DNE'
    get_lockdirs
    declare -p lkdrs
  else
    : 'lkdrs exists'
  fi

  # Delete all possible existing process _lock_directories_.
  for pld in "${lkdrs[@]}"
  do

    # test and delete lock directories.
    if [[ -d "${pld}" ]] && [[ ! -L "${pld}" ]]
    then
      echo sudo rm --one-file-system --preserve-root=all -rfv -- \
          "${pld}" ||
        exit "${nL}"
    fi
  done
  unset pld

    # <>
    #: "${Halt?}"

  command -p kill -s INT "$$"
}

trap exit_trap EXIT TERM

  # <>
  #x_trace
  #exit "$nL"

: 'Process Lock'

#   So, what's the critical section?  For now, its the main `find`
# command. The script can take so much time to execute, running
# more than one process at once is wasteful of system resources.


: 'Variables for Traps and Process Locks'

declare -A A_process_lock_dirs
i=0

  #a_poss_proces_lock_dirs+=("${XDG_RUNTIME_DIR}" "${TMPDIR}" /var/lock
  #  "${HOME}" /tmp /var/tmp)
  #pld="" # SC2155
  #scr_tcode="$(builtin printf '%(%F_%H%M%S)T' 2>&1)"

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
  : $'\t' "/tmp/.${scr_repo_nm}.${$}.${rand_i}.lock.d"

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
unset ii vv

for vv in "${a_poss_proces_lock_dirs[@]}"
do
  if [[ -d "${vv}" ]]
  then
    vv="$(\
      realpath -e "${vv}" 2>&1
    )"
    A_process_lock_dirs+=( ["${vv}/${rand_lock_nm}"]=$((ii++)) )
  fi
done
unset ii vv

for ii in "${!A_process_lock_dirs[@]}"
do
  a_process_lock_dirs+=( ["${A_process_lock_dirs[$ii]}"]="$ii" )
done
unset A_process_lock_dirs i

  # <>
  #x_trace
  #exit "${nL}"

# Bug: race condition btw defining and mkdir?

: 'Process Lock: Define and create the lockdir'

#target_fso=d

unset poss_lk_d process_lock_d

for poss_lk_d in "${a_process_lock_dirs[@]}"
do

  #case "${target_fso}" in
    #d)
        #sudo find "${poss_lk_d%/*}" -maxdepth 0 '(' \
        #-type d -a '!' -type l ')' -writable -readable -executable \
        #-true -exec

      if
        sudo mkdir -vm 0700 "${poss_lk_d}"
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

  # <>
  #shopt -o functrace
  #"${Halt:?}"

unset poss_lk_d

for poss_lk_d in "${a_process_lock_dirs[@]}"
do

  # use the first one that fulfills certain requirements
   mapfile -d '' -t find_out < <(
    find "${poss_lk_d}" -maxdepth 0 '(' \
      -type d -a '!' -type l ')' -writable -readable -executable \
      -exec mkdir -m 0700 '()' ';' -print0
  )

  : 'Process Lock: Create a lockdir and handle any error'
  if [[ -n "${find_out[0]}" ]]
  then

	# x solved x - Bug: $find_out will expand to mult filenames

    if mkdir -m 0700 "${process_lock_d:="${find_out[0]}"}"
    then
      break
    else
      continue
    fi

  else
    {
      printf '\n\tCannot acquire process lock: <%s>.\n' "${process_lock_d}"
      printf 'Exiting.\n\n'
    } >&2

      # <>
      #exit "${nL}"

  fi
done


: 'Process Lock: Search for existing lockdirs'

declare -p a_process_lock_dirs
get_lockdirs

# Bug: loop var: the lower case L looks like the number 1

for ll in "${lkdrs[@]}"
do

  # for dirs or syms
  if [[ -d "${ll}" ]] ||
    [[ -L "${ll}" ]]
  then

    if [[ -v rm_locks ]]
    then

      # `rmdir` doesn't remove symlinks
      sudo rmdir -v -- "${ll}"
    else
      printf '\n\t A process lock exists for this script. Exiting '
      printf 'now.\n\n'

        # <>
        #exit "${nL}"

    fi
  fi
done
unset l # lkdrs # a_poss_proces_lock_dirs # lkdrs_count

# Note: rm_locks is an undocumented CLI option
if [[ -v rm_locks ]] &&
  [[ -n ${lkdrs[*]:0:16} ]]
then
  exit "${nL}"
fi

  # <>
  #exit "${nL}"
  #x_trace

# New section ==================================

  # <> Obligatory debugging block
  #x_trace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  set -x


# Non-critical

## Vars & Functions

POSIXLY_CORRECT=O              # remember to unset
#LC_ALL=C                       # clobbers values from findscan # why??
export POSIXLY_CORRECT LC_ALL
unset IFS

lk_cmds_reqd=(  pathchk
                mv
                link
                unlink
                nice
                sync
                timeout
                stdbuf
                nohup
                ps
              )                                             export lk_cmds_reqd
lk_cmds_opt=(   fuser
                pgrep
              )                                             export lk_cmds_opt

## <> Reset the FS during debugging

### /dev/shm must exist
d=/dev/shm
if [[ ! -e "$d" ]]
then
  sudo mkdir -m 1777 "$d" ||
    er_x "${nL}"
else
  [[ -d "$d" ]] ||
    er_x "${nL}"
fi
unset d

### remove all previous lock files
#### Note: rm_locks is an undocumented CLI option
if [[ -v rm_locks ]]
then
  rm -frv --one-file-system --preserve-root=all -- "${d:?}"/* ||
    er_x "${nL}"
fi


## Commands

### Required: if any of these are missing, print an error and exit
hash -r
unset cc

for cc in "${lk_cmds_reqd[@]}"
do
  lk_cmd_abspth="$(\
    type -P "$cc" 2>&1
  )"

  if [[ -z "${lk_cmd_abspth}" ]]
  then
    er_x "line: ${nL}, command ${cc} is not available."
  fi
done

### Optional: if any of these are missing, print an info message and continue
for cc in "${lk_cmds_opt[@]}"
do
  lk_cmd_abspth="$(\
    type -P "${cc}" 2>&1
  )"                                                        export lk_cmds_abspth

  if [[ -z "$lk_cmd_abspth" ]]
  then
    echo "INFO: line: ${nL}, command ${cc} is not available." >&2
  else
    export "${cc}"="${cc}"
  fi
done
unset cc lk_cmd_abspth

# Trying

## Verify file names -- using POSIX 2017 functionality
f="/dev/shm/$$_${rand_i}.f"
l="/dev/shm/${scr_repo_nm}"
set -C

for xx in "${f}" "${l}"
do
  pathchk -p "${xx}" ||
    echo "INFO: line: ${nL}, command pathchk failed." >&2
  pathchk -P "${x}" ||
    echo "INFO: line: ${nL}, command pathchk failed." >&2
done
unset xx

set --  'dollar:'           "$$" \
        'BASH:'             "$BASH"
        'BASH_ARGV0:'       "$BASH_ARGV0" \
        'BASH_SOURCE[@]:'   "${BASH_SOURCE[@]}" \
        'EPOCHREALTIME:'    "$EPOCHREALTIME" \
        'EUID:'             "$EUID" \
        'HOME:'             "$HOME" \
        'PATH:'             "$PATH" \
        'PPID:'             "$PPID" \
        'PWD:'              "$PWD" \
        'SECONDS:'          "$SECONDS" \
        'SHELL:'            "$SHELL" \
        'SHLVL:'            "$SHLVL" \
        'TMPDIR:'           "$TMPDIR" \
        'UID:'              "$UID"

# printf cmd syntax, POSIX 2017 ...and yet sometimes POSIX spec syntax is wrong!  ...???
printf "%b\n" "$*" > "${f}" ||
  "${Halt:?}"
set --

if pathchk "${l}"
then

  if link -- "${f}" "${l}"
  then
    printf 'Creation of lockfile succeeded.\n'

    if [[ "$f" -ef "$l" ]]
    then
      unlink -- "${f}" ||
        "${Halt:?}"
    fi

  else
    printf 'A lock already exists:\n'
    ls -alhFi "${l}"
    pgrep "${scr_nm#./}"
  fi
fi
unset f l

  # <> Obligatory debugging block
  #x_trace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
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

exit # necc sections are commented out below: see 'for f in "/dev/shm'
printf 'Wait for the lock to be freed? [Y/n]\n'
read -r ans
case "$ans" in
  [Yy])
    while true
    do
      sleep 60
      if [[ -e "/dev/shm/${scr_repo_nm}" ]]
      then
        continue
      else
        break
      fi
    done
    ;;
esac
unset POSIXLY_CORRECT

# lhunath: "mkdir is not defined to be an atomic operation and as
#+ such that "side-effect" is an implementation detail of the file
#+ system"
if mkdir -m 0700 -- "/dev/shm/${scr_repo_nm}"
then
  printf 'Creation of lockdir succeeded.\n'

  ## probably deleting this chunck
  #: "${i:=$((n))}"
  #export creation_t="${EPOCHSECONDS}"
  #i="$(\
    #for f in "/dev/shm/${scr_repo_nm}"/*
    #do
          #if [[ -e "$f" ]]
          #then
            #basename "$f"
          #else
            #if : > "${f/\*/$i}"
            #then
              #declare -Ig creation_t="${EPOCHSECONDS}"
              #printf 'Process file created.\n' >&2
            #else
              #: 'touch failed'
            #fi
          #fi
                  #done
    #)" _mv_file

  # for use of `lsof`
  pushd "/dev/shm/${scr_repo_nm}" ||
    "${Halt:?}"
  for f in "/dev/shm/${scr_repo_nm}"/[0-9]*
  do

    if [[ -e "$f" ]]
    then
      printf 'Racing process exists; exiting.\n'
      head "/dev/shm/${scr_repo_nm}"/*
      exit "${nL}"
    fi
  done
    exit 101
    sleep 60
  unset i f

  ## benchmark this syntax
  #i="$(\
    #for f in "/dev/shm/${scr_repo_nm}"/*
    #do
          #if [[ -e "$f" ]]
          #then
            #basename "$f"
          #else
            ## SC2030 (info): Modification of i is local (to subshell caused by $(..) expansion).
            ##+ SC2030 (info): Modification of creation_t is local (to subshell caused by $(..) expansion).
            #if : > "${f/\*/${i:=$((n))}}"
            #then
              #export creation_t="${EPOCHSECONDS}"
              #printf 'Process file created.\n' >&2
            #else
              #: 'touch failed'
            #fi
          #fi
        #done
    #)" _mv_file

  # benchmark this syntax
  for f in "/dev/shm/${scr_repo_nm}"/*
  do
    if [[ -e "$f" ]]
    then
      i="${f##*/}"

    # trying `: >` vs `touch`
    elif : > "${f/\*/${i:=$((n))}}"
    then
      creation_t="${EPOCHSECONDS}" export creation_t
      printf 'Process file created.\n' >&2
    else
      : 'touch failed'
    fi
  done

  mv -v "/dev/shm/${scr_repo_nm}/$i" "/dev/shm/${scr_repo_nm}/$((++i))"

  veri_lockfile="${f/\*/$((i))}"
  present_lock_count="${veri_lockfile##*/}"

  for f in "/dev/shm/${scr_repo_nm}"/[0-9]*
  do

    if [[ -e "$f" ]]
    then

      if [[ $present_lock_count -ne 0 ]]
      then
        printf 'Racing process exists; exiting.\n'
        exit "${nL}"
      fi

    else
      er_x "${nL}"
    fi
  done

  [[ -z "$veri_lockfile" ]] &&
    veri_lockfile="/dev/shm/${scr_repo_nm}/0"
  echo "$EPOCHSECONDS,$BASHPID,$PPID" > \
      "/dev/shm/${scr_repo_nm}/pidfile" ||
    er_x "${nL}"

  if mv -f "/dev/shm/${scr_repo_nm}/pidfile" "$veri_lockfile"
  then
    printf 'Writing data to process file.\n'
  else
    printf 'Racing process exists; exiting.\n'
    exit "${nL}"
  fi

elif [[ -e "/dev/shm/${scr_repo_nm}" ]]
then

  if [[ -d "/dev/shm/${scr_repo_nm}" ]]
  then
    printf 'Creation of lockdir already occurred.\n'
    unset i f
    i="$(\
      for f in "/dev/shm/${scr_repo_nm}"/*
      do
        if [[ -e "$f" ]]
        then
          f=${f##*/}
        fi
      done
    )" _mv_file

      # <>
      #shopt -s nullglob

    prior_process_files=("/dev/shm/${scr_repo_nm}"/[0-9]*)

    # wrong
    if [[ "${#prior_process_files[@]}" -eq 0 ]]
    then

      rm -frv -- "/dev/shm/${scr_repo_nm}"
      printf 'A prior process failed to clean up properly; exiting.\n'
      exit "${nL}"
    fi

    for f in "${prior_process_files[@]}"
    do
      if [[ -e "$f" ]]
      then
        present_lock_count="${f##*/}"
      fi
      if [[ -s "$f" ]]
      then

          # <>
          #cat $f

        IFS=',' read -r _ bashpid ppid < "$f"

          # <>
          #declare -p epochseconds bashpid ppid

      fi
      zero="${0#./}"
      #set -

      # shellcheck disable=SC2009
      ps_o="$(\
        ps aux |&
          grep -e "${bashpid:=bash}" -e "${ppid:="${scr_repo_nm}"}" \
            -e "${zero:=\.sh}" |&
          grep -ve grep -e "${BASHPID}" -e "${PPID}" 2>&1
      )"

        # <>
        #set -x

      case "$present_lock_count" in
        0)
          if [[ -z "${ps_o}" ]]
          then

            if [[ -z "${creation_t}" ]]
            then
              er_x "${nL}"
            fi

            printf 'Lockdir left over from previous process.\n'
          else
            printf 'Possible previous process.\n'
            set -
            printf '\t%s\n' "$ps_o"

              # <>
              #set -x
          fi

          exit "${nL}"
          ;;
        *)
          printf 'Likely previous process.\n'

          if [[ -n "${ps_o:0:32}" ]]
          then
            set -
            printf '\t%s\n' "$ps_o"
            #set -x
          else
            printf 'No processes other than this one found.\n'
          fi
          ;;
      esac

      printf 'Removing lockdir and exiting.\n'
      rm -frv -- "/dev/shm/${scr_repo_nm}"
      exit "${nL}"
    done

    shopt -u nullglob

  else
    er_x "Possible DOS; probable error. line: ${nL}"
  fi

else
  er_x "${nL}"
fi

  # <>
  #declare -p f i
  #ls -a "/dev/shm/${scr_repo_nm}/"
  #set -

echo
stat "/dev/shm/${scr_repo_nm}"/[0-9]*
head "/dev/shm/${scr_repo_nm}"/[0-9]*
unset f i ps_o

unset POSIXLY_CORRECT

  # <> Obligatory debugging block
  #x_trace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  set -x

exit 101

