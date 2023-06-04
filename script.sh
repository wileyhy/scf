#!/bin/bash
  #!/usr/bin/env -iS bash -x
# Written in bash version 5.1 on Fedora 37 & 38

# Note: Keep your goal in mind.

# SECTION A

: '<> Debugging' 
# "<>" means, "This is a debugging section."

# FeatReq: for $random_n, use the most recent git commit hash ID

script_nm=script.sh
repo_nm=scf
random_n="${RANDOM}" 
unique_string="${repo_nm}.${$}.${random_n}"
proc_lk_d_nm="${unique_string}.lock.d"
mktemp_sfx="${unique_string}.xtr"
age_of_tmp_files='5 minutes ago'
xtr_t_file="/tmp/tmp.mtime_file.${mktemp_sfx}"
delta_sum_file="$(mktemp -p /tmp --suffix=."${mktemp_sfx}.E")"
unset Halt               # For signal-less exiting
declare -rx Halt         #  "   "           "
unset LD_LIBRARY_PATH       # For luck ;-p
declare -rx LD_LIBRARY_PATH #  "   "    "

_ctrl_C_trap(){
  set -x
  trap - INT
  for f in "${xtr_t_file}" "${setenv_prev}" "${setenv_now}" \
    "${setenv_delta}"
  do
    if [[ -f "$f" ]]; then
      rm --one-file-system --preserve-root=all  "$f" ||
        {
          echo rm failed -- "$f" -- line "${LINENO}"
          "${Halt:?}"
        }
    fi
  done
  kill -s INT "$$"
}
trap _ctrl_C_trap INT

: '<> Debug: Delete any left over xtrace files from -mktemp -p /tmp-'
# Note:   Using '/tmp' at this early stage because it's just easier
touch -d "${age_of_tmp_files}" "${xtr_t_file}"

mapfile -d '' -t xtrace_files < <(
  find /tmp -maxdepth 1 -type f \
    -name "tmp.[a-zA-Z0-9]*.${repo_nm}.[0-9]*.[0-9]*.xtr*" \
    '!' -newer "${xtr_t_file}" '!' -name "${xtr_t_file##*/}" -print0 
)

# ...if they're (inodes are for) files & not symlinks, & owned by the 
# same EUID.
for f in "${xtrace_files[@]}"; do
  if [[ -f "${f}" ]] \
    && [[ ! -L "${f}" ]] \
    && [[ -O "${f}" ]];
  then
    rm --one-file-system --preserve-root=all  "$f"
  fi
done && unset f

: '<> Debug: XTrace variables and functions'
funclvl=0
fence=' ++++++++++++++++++++++++++++++++++++++++++++ '

#   _xtrace_duck: If xtrace was previously on, then on first execution 
# of this function, turn xrtrace off, and on second execution, turn 
# xtrace back on and forget about this function's settings. If xtrace 
# was previously off, then leave it off.
_xtrace_duck() {
  : '_xtrace_duck BEGINS' "$((++funclvl))" "${fence}"
  # If xtrace is on...
  if [[ "$-" =~ x ]]; then
    # ...then record its state
    local -gx xtrace_prev
    # and turn xtrace off
    set -
  # but if xtrace is off...
  else
    # ...then if xtrace was previously on...
    : 'if prev'
    if [[ -n "${xtrace_prev}" ]]; then
      # ...then restore xtrace and unset the record of its state
      set -x
      unset xtrace_prev
    # but if xtrace is off and was previously off... (return).
    fi
  fi
  : '_xtrace_duck ENDS  ' "$((--funclvl))" "${fence}"
}

# A set of functions for printing changes in shell variables and para-
# meters between each execution of a command; for use when the DEBUG
# trap is enabled.
_mk_setenv_prev() {
  : '_mk_setenv_prev BEGINS' "$((++funclvl))" "${fence}"
  : 'if now'
  if [[ -n "${setenv_now}" ]]; then
    : 'if prev'
    if [[ -n "${setenv_prev}" ]]; then
      rm --one-file-system --preserve-root=all  -f -- "${setenv_prev}"
    fi
    setenv_prev="${setenv_now}"
  fi
  : '_mk_setenv_prev ENDS  ' "$((--funclvl))" "${fence}"
}
_mk_setenv_now() {
  : '_mk_setenv_now BEGINS' "$((++funclvl))" "${fence}"
  for i in "${!n[@]}"; do 
    caller "$i"
  done
  set -- "${!n[@]}"
  for i; do 
    : $'\t\t\t\t'"${i}"$'\t'"${BASH_LINENO[$i]}"$'\t'"${FUNCNAME[$i]}"$'\t'"${BASH_SOURCE[$i+1]} lineno-array-index"
  done
  ${Halt:?}

  setenv_now="$(mktemp -p /tmp --suffix=."${mktemp_sfx}")"
    # `{ set; env;} | tee`: env & set dont print in simple xtrace 
    set \
      |& tee -- "${setenv_now}" >/dev/null 
    env \
      |& tee -a -- "${setenv_now}" >/dev/null
  : '_mk_setenv_now ENDS  ' "$((--funclvl))" "${fence}"
}
_mk_setenv_delta() {
  : '_mk_setenv_delta BEGINS' "$((++funclvl))" "${fence}"
  : 'if now and prev'
  if [[ -n "${setenv_now}" ]] \
    && [[ -n "${setenv_prev}" ]]; 
  then
    : 'if delta'
    if [[ -n "${setenv_delta}" ]]; then
      tee -a "${delta_sum_file}" < "${setenv_delta}"
      rm --one-file-system --preserve-root=all  -f -- "${setenv_delta}"
      wait -f
    fi

		# syntax caused a weird bug?
		# 	with alsa-info.sh line ~465-466
		#	and then again 
        ## create a new delta file, each time
    #setenv_delta="$(mktemp -p /tmp --suffix=."${mktemp_sfx}")" #
    #{
      #diff -y --suppress-{common-lines,blank-empty} --color=never \
        #"${setenv_prev}" "${setenv_now}" \
        #|& grep -v setenv \
        #| grep --color=always -E '.*'
    #} \
      #|& tee -- "${setenv_delta}"
    #{
      #diff --suppress-{common-lines,blank-empty} --color=always \
        #--palette='ad=1;3;38;5;190:de=1;3;38;5;129' \
        #"${setenv_prev}" "${setenv_now}" \
        #| grep -ve BASH_LINENO -e BASH_COMMAND -e BASH_SOURCE \
          #-e setenv_ -Fe '---'
    #} \
      #|& tee -a "${setenv_delta}"

    # create a new delta file, each time
    setenv_delta="$(mktemp -p /tmp --suffix=."${mktemp_sfx}.A")" 
      #diff -y -W 500 --suppress-{common-lines,blank-empty} \
		    #--color=never "${setenv_prev}" "${setenv_now}" \
        #|& grep -v setenv \
        #| grep --color=always -E '.*' \
        #|& tee -- "${setenv_delta}"
      #wait -f
      diff --suppress-{common-lines,blank-empty} --color=always \
        --palette='ad=1;3;38;5;190:de=1;3;38;5;129' \
        "${setenv_prev}" "${setenv_now}" \
        |& tee -a "${setenv_delta}"
        #| grep -ve BASH_LINENO -e BASH_COMMAND -e BASH_SOURCE \
          #-e setenv_ -Fe '---' \
    # set colors for `wc` output
    export GREP_COLORS='mt=01;104'
    wc "${setenv_delta}" \
      | grep --color=always -E '.*'
    # reset colors for `grep` output
    export GREP_COLORS='mt=01;43'
  fi
  : '_mk_setenv_delta ENDS  ' "$((--funclvl))" "${fence}"
}
_mk_deltas() {
  : '_mk_deltas BEGINS' "$((++funclvl))" "${fence}"
  #_xtrace_duck
  _mk_setenv_prev
  _mk_setenv_now
  _mk_setenv_delta
  #_xtrace_duck
  : '_mk_deltas ENDS  ' "$((--funclvl))" "${fence}"
}
_debug_prompt() {
  : '_debug_prompt BEGINS' "$((++funclvl))" "${fence}"
  _mk_deltas
  : '~~~~~~~PROMPT~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
  read -rp " +[${BASH_SOURCE[0]}:${LINENO}] ${BASH_COMMAND[0]}?" _
  :
  : '_debug_prompt ENDS  ' "$((--funclvl))" "${fence}"
}
_full_xtrace() {
  : '_full_xtrace BEGINS' "$((++funclvl))" "${fence}"
  #set -o functrace
  trap '_debug_prompt "$_";' DEBUG
  set -x
  : '_full_xtrace ENDS  ' "$((--funclvl))" "${fence}"
}
#_full_xtrace


: 'ID and sudo'

if [[ "${UID}" == 0 ]]; then
  printf '\n\t Must be a regular user and use sudo. \n\n'
  exit 1
elif ! sudo -v; then
  printf '\n\tValidation failed of user\x27s \x60sudo\x60 timestamp; '
  printf 'exiting.\n\n'
  exit "${LINENO}"
fi


: 'Required programs' 

# Bug: innaccurate list for this script, 17 May

reqd_cmds=( 'awk' 'chmod' 'cp' 'cut' 'dirname' 'file' 
  'find' 'getconf' 'grep' 'ln' 'ls' 'mkdir' 'mktemp' 
  'od' 'rm' 'rmdir' 'stat' 'strings' 'sudo' 'tee' )
yn=(n)

# Requires a minimum of bash version 5
if [[ "${BASH_VERSION:0:1}" -lt 5 ]]; then
  echo Please install Bash version 5, thanks.
fi

# force PATH searches for these command names
hash -r
for c in "${reqd_cmds[@]}"; do  
  if type_P_o="$(type -P "${c}" 2>&1)"; then
    hash -p "${type_P_o}" "${c}"
  else
    yn+=("${c}")
  fi
done

# Print results as appropriate 
if [[ "${yn[*]}" == 'n' ]]; then 
  : 'No additional commands are required'
else 
  unset 'yn[0]'
  printf '\n\t Please install the following commands: \n'
  printf '\t   %s \n' "${yn[@]}"
  printf '\n'
  exit 1
fi; unset c yn reqd_cmds

#exit "${LINENO}"
#_full_xtrace
#set -x


: 'Traps'

fn_erx() {
  local loc_exit_code="${?}" # this assignment must be the first command
  : 'fn_erx BEGINS' "$((++funclvl))" "${fence}"
  # print an error message and exit with the correct exit code
  echo -e Error: "${@}"
  exit "${loc_exit_code}"
  : 'fn_erx ENDS  ' "$((--funclvl))" "${fence}"
}



: 'Locks'

unset i f
#rm -fv -- "/dev/shm/${repo_nm}"/[0-9]*;
#rm -frv -- "/dev/shm/${repo_nm}";
wait -f
#set -x; unset f i; declare -p f i; ls -a "/dev/shm/${repo_nm}/"; 
if [[ ! -e /dev/shm ]]; then 
  mkdir -m 1777 /dev/shm ||
   exit "${LINENO}"
fi 
wait -f
function _mv_file { 
  # Probably atomic operation ??
  mv -v "/dev/shm/${repo_nm}/$i" "/dev/shm/${repo_nm}/$((++i))" 2> /dev/null; 
}; 
# Almost certainly atomic operation on Linux ext4 ...but on tmpfs ?? 
set -x
if mkdir -m 0700 -- "/dev/shm/${repo_nm}" 2> /dev/null; then
  printf 'Creation of lockdir succeeded.\n'
  pushd "/dev/shm/${repo_nm}" ||
    "${Halt:?}"
  for f in "/dev/shm/${repo_nm}"/[0-9]*; do
    if [[ -e "$f" ]]; then 
      printf 'Racing process exists; exiting.\n'
      head "/dev/shm/${repo_nm}"/*
      exit "${LINENO}"
    fi
  done 
    sleep 60
  unset i f
  i="$( for f in "/dev/shm/${repo_nm}"/*; do 
          if [[ -e "$f" ]]; then 
            basename "$f"; 
          else 
            if touch "${f/\*/${i:=$((n))}}"; then 
              export creation_t="${EPOCHSECONDS}"
              printf 'Process file created.\n' 1>&2 
            else
              : 'touch failed'
            fi
          fi; 
        done
  )" _mv_file;
  veri_lockfile="${f/\*/$((i))}"
  present_lock_count="$(basename "$veri_lockfile")";
  for f in "/dev/shm/${repo_nm}"/[0-9]*; do
    if [[ -e "$f" ]]; then 
      if [[ $present_lock_count -ne 0 ]]; then
        printf 'Racing process exists; exiting.\n'
        exit "${LINENO}"
      fi
    else
      fn_erx "${LINENO}"
    fi; 
  done
  [[ -z "$veri_lockfile" ]] \
    && veri_lockfile="/dev/shm/${repo_nm}/0"
  echo "$EPOCHSECONDS,$BASHPID,$PPID" > "/dev/shm/${repo_nm}/pidfile" \
    || fn_erx "${LINENO}"
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
      # scan `ps` output for either (A) the previous BASHPID and PPID if 
      # their data remains, or (B) any bash process or any shell script 
      # or any string matching this script's repo's name... excluding...
      # the PID or PPID of the executing script.
      ps_o="$(ps aux \
        |& grep -e "${bashpid:='bash'}" -e "${ppid:="${repo_nm}"}" -e "${zero:='.sh'}" \
        |& grep -ve grep -e "${BASHPID}" -e "${PPID}")"
      
      #set -x
      case "$present_lock_count" in
        0)  if [[ -z "${ps_o}" ]]; then 
              if [[ -z "${creation_t}" ]]; then
                fn_erx "${LINENO}"
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
    fn_erx "Possible DOS; probable error. line: ${LINENO}"
  fi
else
  fn_erx "${LINENO}"
fi;
#declare -p f i; ls -a "/dev/shm/${repo_nm}/"; set -;
echo
stat "/dev/shm/${repo_nm}"/[0-9]*;
head "/dev/shm/${repo_nm}"/[0-9]*;
unset f i ps_o
exit 101


: 'Variables for Traps (and Process Locks)'

#declare -A A_process_lock_dirs
a_poss_proces_lock_dirs+=("/dev/shm/${repo_nm}" /var/lock \
  "${XDG_RUNTIME_DIR}" "${TMPDIR}" /var/lock "${HOME}" /tmp \
  /var/tmp)
#i=0 
pld="" # SC2155
timecode="$(builtin printf '%(%F_%H%M%S)T')"

_get_lockdirs(){
  _full_xtrace
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
  set -x
  : "EXIT trap BEGINS ++++++++++++++++++++++++++++++++++++++++++++++"
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
        || exit "${LINENO}"
    fi
  done && unset pld

    # <>
    #: "${Halt?}"

  kill -s INT "$$"
}


test(){
  shopt -s expand_aliases
  declare -n n=BASH_SOURCE
  declare -n e=LINENO
  declare -a l
  alias L_='declare -a "l[8-${#n[@]}]=$e"' 
  function M_ { m=("${l[@]}");}
  L_; 
  echo $?
  M_; 
  echo $?
  declare -p l m
  alias M_='m=("${l[@]}")';
}
history -a


x+=([32-3]=d)
y=("${x[@]}")
declare -p y
#declare -a y=([0]="d" [1]="c" [2]="b" [3]="a")



foo(){ 
  echo bar "$@";
}
L_; 
foo "$e"
declare -p l

trap _exit_trap EXIT TERM
#_full_xtrace

declare -a "l[8-${#n[@]}]=$LINENO"; exit "${l[8-${#n[@]}]}"

: "count, BASH_LINENO: ${#BASH_LINENO[@]}"
declare -p BASH_LINENO
: "count, BASH_SOURCE: ${#BASH_SOURCE[@]}"
declare -p BASH_SOURCE
: "count, FUNCNAME: ${#FUNCNAME[@]}"
declare -p FUNCNAME
"${Halt:?}"



: 'Variables'

: 'Vars: Environment'
unset LC_ALL 
#FUNCNEST=8
set -o functrace
GREP_COLORS='mt=01;43'
LC_COLLATE="C.UTF-8"     # for predictable sorting
LC_CTYPE="C.UTF-8"       #  "   "           "
LC_NUMERIC="en_US.UTF-8" # for commas in large numbers
getconf_o="$(/usr/bin/command -p getconf PATH)" \
  || "${Halt:?}"
PATH="${getconf_o}:/usr/bin:/usr/sbin:${PATH}"
PS4='+${BASH_SOURCE[0]}:${LINENO}:${FUNCNAME[0]}: '
export FUNCNEST GREP_COLORS LC_COLLATE LC_CTYPE LC_NUMERIC PATH PS4

: 'Vars: Implementation-dependent args for options parsable by ShellCheck'
sc_severity=error
SC_shells='(sh|bash|dash|ksh)'

: 'Vars more frequently subject to change'
protected_git_dir_1="${HOME}/MYPROJECTS"
protected_git_dir_2="${HOME}/OTHERSPROJECTS"
script_dirnm="${repo_nm}.d"
script_lic='Apache 2 license'
script_proper_nm='Script Finder'
script_version=1.0

: 'Vars re getopts'
if [[ $# -gt 0 ]]; then
  cli_input=("${@}")
fi
unsaf_ascii=(
  [0]="|" [1]="&" [2]=";" [3]="(" [4]=")" [5]="<"
  [6]=">" [8]=$'\t' [9]=$'\n' [10]="||" [11]="&&"
  [12]=";;" [13]=";&" [14]=";;&" [15]="|&" [16]="!" [17]="{"
  [18]="}" [19]="[" [20]="]" [21]="[[" [22]="]]" [23]="\$"
  [24]="="
)
unsaf_ascii_Pfn_erexstring="$(printf '%s' "${unsaf_ascii[@]}")"
bash_path_orig="${PATH}"
bash_path="${bash_path_orig}"
easter_egg="$(
  printf '%s%s%s' 'CgkiSSB3b3VsZCBoYXZlIG1hZGUgdGhpcyBzaG9y' \
    'dGVyLCBidXQgSSBkaWRuJ3QgaGF2ZSB0aGUg' \
    'dGltZS4iCgkJLS0gTWFyayBUd2FpbgoK' \
    | base64 -d
)"
find_exclude_optargs_default=(
  [0]='(' [1]='!' [2]='-name' [3]='proc' [4]='-a' [5]='!'
  [6]='-name' [7]='sys' [8]='-a' [9]='!' [10]='-iname'
  [11]="${script_dirnm}*" [12]='-a' [13]='!' [14]='-ipath'
  [15]="${protected_git_dir_1}" [16]='-a' [17]='!' [18]='-ipath'
  [19]="${protected_git_dir_2}" [20]='-a' [21]='!' [22]='-path'
  [23]='*/git/*' [24]=')'
)
find_exclude_optargs=()
IFS=':' read -ra find_path <<<"${bash_path}"
find_sym_opt_L='-L'
sc_sev_abrv="${sc_severity:0:1}"
#methods_recurse_n=no
methods_path=('as-is')
methods_prog_cv=bash_type_a
#methods_scan_excluded_by=yes
#methods_symlinks_l=logical
verify=(all)

# <>
_full_xtrace
exit "${LINENO}"

: 'Functions'

fn_bak() {
  : 'fn_bak BEGINS' "$((++funclvl))" "${fence}"
  # for each of multiple input files
  for loc_filename_a in "${@}"; do
    # test verifying existence of input
    if sudo /bin/test -f "${loc_filename_a}"; then

      # Bug: Why does this ^ test req sudo when this test \/ doesnt?
      # Requires use of fn_bak or fn_bak to debug this.
      # (~line 2000, 15 May)

      # if the destination (.bak) file already exists,
      # then age it first.
      if [[ -f "${loc_filename_a}.bak" ]]; then
        if [[ -s "${loc_filename_a}.bak" ]]; then
          return
        else
          sudo  rm --one-file-system --preserve-root=all -f -- \
            "${loc_filename_a}.bak"
        fi
      fi
      # write a new .bak file
      sudo  rsync -acq -- "${loc_filename_a}"{,.bak} \
        || fn_erx "${LINENO}"
    # if input file DNE, then print an error and exit
    else
      {
        echo WARNING: file DNE "${loc_filename_a}"
        return
      }
    fi
  done
  : 'fn_bak ENDS  ' "$((--funclvl))" "${fence}"
}

#fn_num() {
#  : 'fn_num BEGINS' "$((++funclvl))" "${fence}"
#  # Usage: fn_num [raw arrays names]
#  # for each of multiple input array names
#  for loc_unquotd_array_nm_a in "${@}"; do
#    # set a local name reference variable
#    local -n loc_nameref_a="${loc_unquotd_array_nm_a}"
#    # and use the nameref to print the number of indices in the
#    # input array
#    echo ${#loc_nameref_a[@]}
#  done
#  : 'fn_num ENDS  ' "$((--funclvl))" "${fence}"
#}

fn_usage() {
  # Print a usage message and exit with a pre-determined exit code
  # Usage:  fn_usage [exit-code]
  : 'fn_usage BEGINS' "$((++funclvl))" "${fence}"
  {
    cat <<-EOF
  ${repo_nm} - ${script_proper_nm}, version ${script_version}
    Find and scan shell scripts depending on severity level. 
    Options are parsed by bash's builtin "getopts".
  Usage:
    ./${script_nm} -H [b|p|l] -M [r|p|t] 
      -P [ac|as|bi|bo|ge|sb|pr|sy] -R [DIRECTORY] -S [e|i|s|w] 
      -V -X [r|p|t] -h -p [ba|cp|cv|fi|ty] -q [a|c|d|i|l|p|u] 
      -r [d|y|n] -s [s|y|n]

      l:  Follow symlinks                           
        [p]   physical                             
       *[l]   logical                                       
      d:  Path                                           
        [ac]  Actually all        h   Help message
        [al]  All                 p:  Progam and method
       *[as]  As-is                                    
        [bi]  /bin only                                         
        [bo]  Both /{,s}bin only                              
        [ge]  Getconf PATH only     [fi] "find" binary
        [sb]  /sbin only           *[ty] "bash" builtin "type -a"
        [pr]  Add /proc           q:  Validate information
        [sy]  Add /sys             *[a]   all
      a:  Path                                            
        [DIR]  Add search dir       [d]   add DACs
      c:  Severity level            [i]   add interpreters
       *[e]   error                 [l]   add ACLs
        [i]   info                  [p]   add PATH
        [s]   style                 [u]   unset all
        [w]   warning             r:  Recurse into dirs
      v   Version                   [d|y] Yes   *[n] No
      s:  Scan excluded dirs      *:  Help message
       *[s|y|b] Yes   [n] No       
EOF
  } | more -e
  : 'fn_usage ENDS  ' "$((--funclvl))" "${fence}"
  exit "${1}"
}

fn_write_arrays() {
  : 'fn_write_arrays BEGINS' "$((++funclvl))" "${fence}"
  # Write each array to a file on disk.
  # Usage: fn_write_arrays [arrays]
  loc_write_d_b="${curr_time_ssubd}arrays"
  if [[ ! -d "${loc_write_d_b}" ]]; then
    sudo  mkdir -p -- "${loc_write_d_b}" \
      || fn_erx "${LINENO}"
  fi
  # for each of multiple input array names
  for loc_unquotd_array_nm_b in "${@}"; do
    # create local variables, for use as both array and string
    local -n loc_nameref_b="${loc_unquotd_array_nm_b}"
    loc_array_nm="${loc_unquotd_array_nm_b}"
    loc_write_f_b="${loc_write_d_b}/_${sc_sev_abrv}"
    loc_write_f_b+="_${ABBREV_REL_SEARCH_DIRS}_${loc_array_nm}"

    # Bug? When array correctly is empty: 'declare -p ... > /dev/null ||' ?
    # requires use of fn_write_arrays or fn_write_arrays to debug this. 
    # (~line 2000, 15 May)

    # if the input array holds no data, then populate it
    if [[ ! -v loc_nameref_b[@] ]]; then
      loc_nameref_b=([0]='fn_write_arrays: Empty array')
    fi
    # then write a data file to disk
    declare -p "${loc_array_nm}" \
      | sudo  tee --output-error=exit  -- "${loc_write_f_b}" >/dev/null
    # write a backup of the new data file
    fn_bak "${loc_write_f_b}"
  done
  : 'fn_write_arrays ENDS  ' "$((--funclvl))" "${fence}"
}

#fn_write_vars() {
#  : 'fn_write_vars BEGINS' "$((++funclvl))" "${fence}"
#  # Usage: fn_write_vars [loc_script_section_nm] [raw variable names]
#  # first pos-parm is string used for differentiating filename
#  loc_script_section_nm="${1}"
#  loc_write_f_a="${curr_time_ssubd}/${loc_script_section_nm}_vars"
#  shift
#  # if the destination file already exists, then return from FN
#  [[ -e "${loc_write_f_a}" ]] \
#    && return
#  # write a new data file
#  declare -p "${@}" 2>/dev/null \
#    | sudo  tee --output-error=exit  -- "${loc_write_f_a}" >/dev/null
#  # and write a .bak file
#  fn_bak "${loc_write_f_a}"
#  : 'fn_write_vars ENDS  ' "$((--funclvl))" "${fence}"
#}



: 'Data dirs' 

# This section is super buggy.

# take each found dir and convert abs path [of sym, okay] to a string
# usable for directory names
unset index element calc
# for each dirname / directory in search path
#for index in "${!A_rsd[@]}";                                            # <
#do
  #element="${A_rsd["$index"]}"
  #calc="$(realpath -e "$element")"
  #calc="${calc//\//_}"
  #calc="${calc#_}"
  #printf 'element: %-12s index: %-12s calc: %s \n' \
    #"$element" "$index" "$calc"
  #if [[ "$index" != "$calc" ]]; then
    #echo wrong
    #exit
  #fi
#done

exit "${LINENO}"
_full_xtrace

# Bugs: Hardcoded $mountpoint -- use lock dir as main_d

: 'Assign varnames and paths for the data directories'
mountpoint=/run/media/root/29_Mar_2023
main_d="${mountpoint}/${script_dirnm}"
data_subd="${main_d}/latest_data"
curr_time_ssubd="${data_subd}/t_${timecode}/"
list_crunchbangs="${curr_time_ssubd}/crunchbangs"
: 'data files'
a_write_path_nms=("${list_crunchbangs:=crunchbangs}"
  "/tmp/${list_crunchbangs##*/}"
)
: 'make sure -data_subd- is a directory OR create the -data_subd- dir '
: 'if necessary'
[[ -d "${data_subd}" ]] \
  || mkdir "${data_subd}" # as liveuser
#set -x; :;: "<>"; sudo namei -xl  -- "${data_subd}"
: 'Label the current data as -latest.-'
mapfile -d '' -t a_previous_time_dirs < <(
  find "${data_subd}" -mindepth 1 -maxdepth 1 -type d -a \! -type l \
    -name 't_*' -print0
)
: 'if -prev_time_ssubd- is empty, delete it, otherwise -mv- it out'
: 'of the -latest- dir'
for prev_time_ssubd in "${a_previous_time_dirs[@]}"; do
  rmdir -v --ignore-fail-on-non-empty -- "${prev_time_ssubd}"
  : 'of previous prev_time_ssubd'
  if [[ -d "${prev_time_ssubd}" ]] \
    && [[ ! -L "${prev_time_ssubd}" ]]; then
    sudo mv -- "${a_previous_time_dirs[@]}" "${main_d}"
  else
    continue
  fi
done
: 'of curr_time_ssubd'
if [[ ! -d "${curr_time_ssubd}" ]]; then
  sudo  mkdir -p -- "${curr_time_ssubd}" \
    || fn_erx "${LINENO}"
fi
#set -x; :;: "<>"; sudo namei -xl  -- "${curr_time_ssubd}"

# <>
_full_xtrace
exit "${LINENO}"



# Section B

: 'Option parsing'

shopt -s nocasematch
while getopts "a:bc:d:hl:m:p:q:r:s:v" cli_input; do

  # Parse command line options
  case "${cli_input}" in

    # PATH (array) - Part 2 - options with args
    a)
      # Input validation, more thorough. Remove unprintable strings.
      OPTARG="$(strings -n1 <<<"${OPTARG}")"

      # Remove unsafe characters
      new_optarg="${OPTARG//["${unsaf_ascii_Pfn_erexstring[@]}"]/}"

      # If any ASCII characters were removed, print an error and exit
      if [[ "${new_optarg}" != "${OPTARG}" ]]; then
        printf '\n\tError: option -R: directory name includes '
        printf 'an illegal character\n\n'
      fi

      # Canonicalize path
      new_optarg="$(realpath -e "${new_optarg}")"

      # Amended value must be a directory
      if [[ ! -d "${new_optarg}" ]]; then
        "${arg_wrong__a:?}"
      fi

      # Append dirname to bash_path and reset find_path
      bash_path+=":${new_optarg}"
      IFS=":" read -ra find_path <<<"${bash_path}"

      # adjust tracking array
      new_optarg="${new_optarg//\//_}"
      methods_path+=("add_dir_${new_optarg}")
      ;;

    # Easter egg
    b)
      printf '%s' "${easter_egg}"
      exit 0
      ;;

    # ShellCheck's '-S' setting, ie, severity level. Default is error.
    c) case "${OPTARG:0:1}" in
      e*) sc_severity=error ;;
      i*) sc_severity=info ;;
      s*) sc_severity=style ;;
      w*) sc_severity=warning ;;
      *) "${arg_wrong__c:?}" ;;
    esac ;;

    # PATH (array) - Part 1 -
    #   These options with have no arguments. The default is 'as-is'.
    # '-P /usr/share' is an option with an argument. For scanning
    # '/proc' or '/sys', see also option 's'. Multiple abbreviations
    # are accepted. For consistency, find_path is always defined after
    # bash_path, regardless of which one is used. Clobbering settings
    # are: ac as bi bo ge sb. Additive PATH settings, but the Program
    # setting gets clobbered, are: pr sy.
    d) case "${OPTARG:0:2}" in

      ac* | aa*)
        bash_path='/'
        IFS=":" read -ra find_path <<<"${bash_path}"
        find_exclude_optargs=()
        methods_path=(actually_all) 
        methods_prog_cv=bin_find
        #methods_scan_excluded_by=yes
        ;;
      al* )
        bash_path='/'
        IFS=":" read -ra find_path <<<"${bash_path}"
        find_exclude_optargs=("${find_exclude_optargs_default[@]}")
        methods_path=(all) 
        methods_prog_cv=bin_find
        #methods_scan_excluded_by=no
        ;;
      as* | ai*)
        bash_path="${bash_path_orig}"
        IFS=":" read -ra find_path <<<"${bash_path}"
        methods_path=('as-is') 
        ;;
      bi* | b)
        bash_path='/usr/bin'
        IFS=":" read -ra find_path <<<"${bash_path}"
        methods_path=(bin_only) 
        ;;
      bo* | bs*)
        bash_path='/usr/bin:/usr/sbin'
        IFS=":" read -ra find_path <<<"${bash_path}"
        methods_path=(both_bin_sbin_only)
        ;;
      ge* | g)
        bash_path="${getconf_o}"
        IFS=":" read -ra find_path <<<"${bash_path}"
        methods_path=(getconf_PATH_only) 
        ;;
      sb* | so* | s)
        bash_path='/usr/sbin'
        IFS=":" read -ra find_path <<<"${bash_path}"
        methods_path=(sbin_only) 
        ;;
      pr* | p | pa*)
        bash_path+=':/proc'
        IFS=":" read -ra find_path <<<"${bash_path}"
        methods_path+=(add_proc) 
        methods_prog_cv=bin_find
        find_exclude_optargs=()
        #methods_scan_excluded_by=yes
        ;;
      sy* | sa*)
        bash_path+=':/sys'
        IFS=":" read -ra find_path <<<"${bash_path}"
        methods_path+=(add_sys) 
        methods_prog_cv=bin_find
        find_exclude_optargs=()
        #methods_scan_excluded_by=yes
        ;;
      *) "${arg_wrong__d:?}" ;;
    esac ;;

    # Help message
    h) fn_usage 0 ;;

    # Follow symlinks
    #   `bash` always follows symlinks, therefore to not follow any
    # symlinks requires `find` and is a clobbering setting, ie,
    # selecting either '-h P' or '-h L' will also select the use of
    # `find`. The 'P' and 'L' refer to `find`s first argument, which
    # by default is assumed (by `find`) to be '-P'. `find -H` is not
    # implemented in this script. Default is bash.
    #   Side effect: setting '-l p' also clobbers this variable. Side
    # effects such as these are marked below as "clobber."
    #   This parameter expansion, ':?', when a parameter is null or
    # unset, causes the shell to immediately halt, ignoring any trap
    # on EXIT.
    #   Mis-spellings beyond the first one or two letters are allowed.
    l)
      case "${OPTARG:0:1}" in
        l* ) # follow symlinks
          #methods_symlinks_l=logical
          find_sym_opt_L='-L' 

          case "${methods_prog_cv}" in
            *find)
              #methods_recurse_n=yes 
              find_exclude_optargs=("${find_exclude_optargs_default[@]}")
              #methods_scan_excluded_by=no 
              ;;
            *bash*)
              #methods_recurse_n=no 
              find_exclude_optargs=()
              #methods_scan_excluded_by=yes
              ;;
            *) "${arg_wrong__l:?}" 
              ;;
          esac
          ;;
        p* ) # never follow symlinks
          methods_prog_cv=bin_find
          #methods_symlinks_l=physical 
          find_sym_opt_L='-P' 
          #methods_recurse_n=yes 
          find_exclude_optargs=("${find_exclude_optargs_default[@]}")
          #methods_scan_excluded_by=no 
          ;;
        *) "${arg_wrong__l:?}" ;;
      esac ;;

    ## Whether and how to save data. Default is temp files.
    #m) case "${OPTARG:0:1}" in
      #p*) memory_usage=persistent_storage ;;
      #r*) memory_usage=RAsudo namei -xl only ;;
      #t*) memory_usage=temp_files ;;
      #*) "${arg_wrong__m:?}" ;;
    #esac ;;

    # Program to search with. All settings clobber; bash is default
    p) case "${OPTARG:0:2}" in
      [b]*)
        methods_prog_cv=bash_type_a
        #methods_recurse_n=no 
        #methods_symlinks_l=logical
        find_exclude_optargs=()
        #methods_scan_excluded_by=yes
        ;;
      f*) 
        methods_prog_cv=bin_find 
        #methods_recurse_n=yes 
        find_exclude_optargs=("${find_exclude_optargs_default[@]}")
        #methods_scan_excluded_by=no 
        ;;
      *) 
        "${arg_wrong__p:?}" 
        ;;
    esac ;;

    # What information to verify. The default is all.
    q) case "${OPTARG:0:2}" in
      l | al*) verify=(all) ;;
      u | un*) unset verify ;;
      *) [[ "${verify[*]}" =~ all ]] \
        && unset verify ;;&
      a | ac*) verify+=(acls) ;;
      d | da*) verify+=(dacs) ;;
      i | in*) verify+=(interpreters) ;;
      p | pa*) verify+=(path) ;;
      *) "${arg_wrong__q:?}" ;;
    esac ;;

    # Descend into dirs (recurse)
    #   `bash`s path search cannot descend into dirs; for `find` the
    # default is to 'do descend' into dirs. For this script, the default
    # for descending follows `bash`, and changing this setting to 'yes',
    # 'recurse' or 'descend' switches the search program to `find`.
    # `find`s '-mindepth' and '-maxdepth' are not used.
    #unset bash_path # why unset it? the setting '-r' could be
    # reversed later on the same command line
    #unset find_path # again, why unset it?
    r) case "${OPTARG:0:1}" in
      r | d | y) 
        methods_prog_cv=bin_find 
        #methods_recurse_n=yes 
        find_exclude_optargs=("${find_exclude_optargs_default[@]}")
        #methods_scan_excluded_by=no 
        ;;
      n) 
        #methods_recurse_n=no 
        
        if [[ "${methods_prog_cv}" =~ find ]]; then
          methods_prog_cv=bash_type_a
        fi
            
        find_exclude_optargs=()
        #methods_scan_excluded_by=yes
        #methods_symlinks_l=logical                                      # <
        find_sym_opt_L='-L' 
        ;;
      *) 
        "${arg_wrong__r:?}" 
        ;;
    esac ;;

    # Scan excluded dirs
    #   By default, this script assumes for `find` a set of automatic-
    # ally excluded search directories that often prove to be somewhat
    # problematic: '/proc', '/sys', and anything with a find '-path'
    # of either '*/git/*' or this script's repo's name. With a default
    # PATH setting, `bash` usually also skips these directories. The 
    # default is bash, so disabling this option indicates the wish to 
    # use `find`, and so clobbers `bash`. To explicitly add '/proc' or 
    # '/sys' to your search path, see option 'd', 'add_proc' and 'add_sys'.
    s) case "${OPTARG:0:1}" in
        s | y | b) 
          find_exclude_optargs=() 
          #methods_scan_excluded_by=yes 
          ;;

        n) 
          #methods_recurse_n=yes                                         # <
          methods_prog_cv=bin_find
          find_exclude_optargs=("${find_exclude_optargs_default[@]}")
          #methods_scan_excluded_by=no                                   # <
         
          # if /proc or /sys have been added to the list of dirs to 
          # be searched, then remove each of them from each of the
          # variables they've been added to. Then reassign find_path.

          # if /proc or /sys...
          for x in /proc /sys; do

            # (loop in case ':/proc' or ':/sys' have been added multiple 
            # times)
            while :; do
              
              # ...have been added to the list of dirs to be searched...
              if [[ "${bash_path}" =~ ${x} ]]; then

                # then remove them, first from $bash_path...
                bash_path="${bash_path//:"${x}"}"
              
              # (finish the loop when there aren'r any more ':/proc's or 
              # ':/sys's in bash_path)
              else
                break
              fi
            done

            # ...then remove them from methods_path.
            if [[ "${methods_path[*]}" =~ ${x#/} ]]; then
            
              # (iterate through each index)
              for i in "${!methods_path[@]}"; do
              
                if [[ "${methods_path[i]}" =~ ${x#/} ]]; then
                  unset 'methods_path[i]'
                fi  
              done
            fi

            # and then re-assign find_path
            IFS=":" read -ra find_path <<<"${bash_path}"
          done && unset x
          ;;
        *) 
          "${arg_wrong__s:?}" 
          ;;
      esac ;;

    v) printf '\n\t%s, version %s. %s.\n\n' "${script_proper_nm}" \
      "${script_version}" "${script_lic}" ;;

    *) fn_usage 1 ;;
  esac
done
shopt -u nocasematch

#declare -p  methods_symlinks_l methods_recurse_n methods_prog_cv \
  #methods_scan_excluded_by find_sym_opt_L find_exclude_optargs \
  #bash_path find_path PATH methods_path

# <>
_full_xtrace
exit "${LINENO}"



: 'Verify PATH'

_verify_path(){
  : '_verify_path BEGINS'  "$((++funclvl))" "${fence}"
  #_full_xtrace
  
  # ...before running `type` / `command` or they'll print dups
  # Note: var $PATH is always processed
  local loc_var_nm
  local -n loc_nameref
  loc_var_nm="${1}"
  loc_nameref="${1}"

  # var $bash_path is only processed when the CLI optargs say so
  if [[ "${loc_var_nm}" == bash_path ]] \
    && [[ "${verify[*]}" != *+(all|path)* ]]
  then
    return
  fi

  # Get constituent dirs from $1
  local loc_path_{1,2} p
  IFS=':' read -ra loc_path_1 <<< "${loc_nameref}"

  # get the cannonicalized paths of each such dir, replacing the 
  # existing array element with the corrected value. no result
  # from `realpath` sets an empty ('') array value.
  for p in "${!loc_path_1[@]}"; do
    loc_path_1[p]="$(realpath -e "${loc_path_1[p]}" 2>/dev/null)"
    
    # if the resulting index value is empty, then unset it
    if [[ -z "${loc_path_1[p]}" ]]; then
      unset 'loc_path_1[p]'
    fi
  done && unset p

  # if the loc_path_1 is now empty, then exit
  if [[ "${#loc_path_1[@]}" -eq 0 ]]; then
    fn_erx _verify_path "${loc_nameref}"
  fi

  # remove any duplicates while preserving order of dirs
  for p in "${!loc_path_1[@]}"; do
    if [[ "${loc_path_2[*]}" =~ ${loc_path_1[p]} ]]; then
      unset 'loc_path_1[p]'
    else
      loc_path_2+=("${loc_path_1[p]}")
    fi
  done && unset p

  # reset indices of loc_path_2
  loc_path_2=("${loc_path_2[@]}")

  # reset path vars
  builtin printf -v "${loc_var_nm}" '%s' "$(
    printf '%s' "${loc_path_2[0]}";
    unset 'loc_path_2[0]';
    [[ -n "${loc_path_2[*]}" ]] \
      && printf ':%s' "${loc_path_2[@]}"
  )"

  # if the path var is bash_path, then reset find_path
  if [[ "${loc_var_nm}" = bash_path ]]; then 
    IFS=":" read -ra find_path <<<"${bash_path}"
  fi
  : '_verify_path ENDS  '  "$((--funclvl))" "${fence}"
}

_verify_path PATH
_verify_path bash_path

exit "${LINENO}"
_full_xtrace



: 'Verify DACs'

# Bug: var path_2 is now loc_path_2 

namei_o="$(
  for d in "${bash_path[@]}"; do
    namei -xl "$(
      realpath -e "$d" 2>/dev/null
    )"
  done \
    | grep -v ^'f:' \
    | gawk --lint '$2 !~ /root/ || $3 !~ /root/ { print }'
)"
if [[ -n "${namei_o}" ]]; then
  echo 'A directory in PATH is not fully owned by root (DAC).'
  echo "${namei_o}"
  exit "${LINENO}"
fi



: 'Verify ACLs'

# Variables, this section
unset end_dirname full_dir_list ext_array dir sub_dir num_sub_dirs N n \
  extglob_pattern ext_first ext_last getfacl_o grep_o
end_dirname=/
declare -A full_dir_list
ext_array=()

# for each actual directory in bash_path
for dir in "${bash_path[@]}"; do

  # limit the number of loops to the number of constituent directory
  # inodes. safely split each directory into its constituent directory
  # names, ie, by using NULL's in place of '/'s
  unset sub_dir
  num_sub_dirs="$(tr '/' '\0' <<< "$dir" \
    | gawk --lint -F'\0' '{ print NF }')"
  N=$((num_sub_dirs - 1))

  # read the ACLs of each dir and sub_dir
  for ((n = N; n >= 0; --n)); do

    # Assign a value to $sub_dir as necessary
    : "${sub_dir:="${dir}"}"

    # <> quote ${extglob_pattern or not? - SC-2053=w
    [[ "${sub_dir}" = "${extglob_pattern}" ]]
    echo $?
    #[[ "${sub_dir}" = ${extglob_pattern} ]] ; echo $?
    "${Halt:?}"

    # If the sub_dir is already listed in the extglob_pattern, then
    # move on to the next small loop
    if [[ "${sub_dir}" = "${extglob_pattern}" ]]; then
      sub_dir="$(dirname "${sub_dir:="${dir}"}")"

      # If the sub_dir is '/', then move on to the next big loop
      if [[ "${sub_dir}" = "${end_dirname}" ]]; then
        break
      fi
      continue
    fi

    # Use an Associative array to filter out duplicate entries.
    # (With associative arrays, duplicate assignments are indempotent.)
    full_dir_list["${sub_dir}"]+="${n},"

    # create a list of directories and subdirectories that have been
    # tested so far. This section concatenates directories as strings
    # into a variable that the shell will later interpret as an
    # extglob.
    ext_array=("${!full_dir_list[@]}")
    ext_first="${ext_array[0]}"
    [[ -n "${ext_first}" ]] \
      && unset 'ext_array[0]'

    _full_xtrace
    :;: "<>"
    declare -p  ext_array

    ext_last="${ext_array[*]: -1:1}" # [@] or [*] ? SC-2124=w

    _full_xtrace
    :;: "<>"
    declare -p  ext_last
    exit "${LINENO}"

    [[ -n "${ext_last}" ]] \
      && unset "ext_array[${#ext_array[@]}]"
    # index math can be a little weird

    # create the exglob_pattern
    if [[ -n "${ext_first}" ]]; then
      extglob_pattern="$(printf '@(%s' "${ext_first}")"
      [[ "${#ext_array[@]}" -gt 0 ]] \
        && extglob_pattern+="$(printf '|%s' "${ext_array[@]}")"
      if [[ -n "${ext_last}" ]]; then
        extglob_pattern+="$(printf '|%s)' "${ext_last}")"
      else
        extglob_pattern+="$(printf ')')"
      fi
    fi

    # look for any ACL's on the directory
    getfacl_o="$(getfacl -enp -- "${sub_dir}" 2>/dev/null)"
    grep_o="$(grep -ve '^#' -e ^'user::' -e ^'group::' -e ^'other::' \
      <<<"${getfacl_o}")"

    # If found, exit the script and inform the user
    if [[ -n "${grep_o}" ]]; then
      printf '\n%s: ACL defined for this directory:\n\t%s\n\n' \
        "${script_nm}" "${sub_dir}"
      echo "${getfacl_o}"
      printf '\n\tThis command will remove all ACL\x27s from the '
      printf 'specified directory:\n\n\t\tsetfacl -b %s\n\n' "${sub_dir}"
      exit 1

    # otherwise, move on to the next big loop
    else
      if [[ "${sub_dir}" = "${end_dirname}" ]]; then
        break
      fi
    fi

    sub_dir="$(dirname "${sub_dir:="${dir}"}")"
  done
done
unset end_dirname full_dir_list ext_array dir sub_dir num_sub_dirs \
  N n extglob_pattern ext_first ext_last getfacl_o grep_o

# <>
_full_xtrace
exit "${LINENO}"



# SECTION C

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
#timecode="$(builtin printf '%(%F_%H%M%S)T')"

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
  : $'\t' "/tmp/.${repo_nm}.${$}.${random_n}.lock.d"
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

# An associative array, in case TMPDIR duplicates another array value
for v in "${a_poss_proces_lock_dirs[@]}"; do
  if [[ -d "${v}" ]]; then
    v="$(realpath -e "${v}")"
    A_process_lock_dirs+=( ["${v}/${proc_lk_d_nm}"]=$((i++)) )
  fi
done && unset i v 

for i in "${!A_process_lock_dirs[@]}"; do 
  a_process_lock_dirs+=( ["${A_process_lock_dirs[$i]}"]="$i" ); 
done && unset A_process_lock_dirs i

#_full_xtrace
#exit "${LINENO}"

if [[ "$*" =~ delete_locks ]]; then 
  delete_locks='y'
fi


# Bug: race condition btw defining and `mkdir`?

: 'Process Lock: Define & create the lockdir'

#target_fso=d

for poss_lk_d in "${a_process_lock_dirs[@]}"; do 
  
  #case "${target_fso}" in
    #d)
      if 
        #sudo find "${poss_lk_d%/*}" -maxdepth 0 '(' \
        #-type d -a '!' -type l ')' -writable -readable -executable \
        #-true -exec 
                
        sudo mkdir -vm 0700 "${poss_lk_d}" ';'; 
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
  ${Halt:?}

for poss_lk_d in "${a_process_lock_dirs[@]}"; do
  # use the first one that fulfills certain requirements
  find_out="$( find "${poss_lk_d}" -maxdepth 0 '(' \
    -type d -a '!' -type l ')' -writable -readable -executable \
    -exec mkdir -m 0700 '()' ';'
  )"
  
  : 'Process Lock: Create a lockdir and handle any error'
  if [[ -n "${find_out}" ]]; then

	# Bug: $find_out will expand to mult filenames

    if mkdir -m 0700 "${process_lock_d:="${find_out}"}" 2>/dev/null; then
      break
    else
      continue
    fi
  
  else
    {
      printf '\n\tCannot acquire process lock: <%s>.\n' "${process_lock_d}"
      printf 'Exiting.\n\n'
    } 1>&2
    exit "${LINENO}"
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
    
    if [[ -v delete_locks ]]; then
      
      # `rmdir` doesn't remove symlinks 
      sudo rmdir -v -- "${l}"
    else
      printf '\n\t A process lock exists for this script. Exiting '
      printf 'now.\n\n'
      exit "${LINENO}"
    fi
  fi
done && unset l # lkdrs # a_poss_proces_lock_dirs # lkdrs_count 

# Note: delete_locks is an undocumented CLI option
if [[ -v delete_locks ]] \
  && [[ -n ${lkdrs[*]:0:16} ]]; 
then
  exit "${LINENO}"
fi

#exit "${LINENO}"
_full_xtrace




# DOS vs atomicity ...really is a more complicated problem than I 
# wish to solve in this script.

: 'Rewrite of Process Lock section'

: 'Define one consistent lockdir name'

filesystem/repo_nm/lockdir

: 'Exec -mkdir- '

  # mkdir exits 0 -- with a template that includes some randomization, 
  # this mkdir call should nearly always exit 0
  : 'if success'

    : 'look for files matching template in all poss dirs'

      : 'based on number of files found'

      : 'based on names of files' 

        : 'use data from other dirnames to...'

          : 'see whether a different process exists'

          : 'see that process-s commandline'

          : 'see what files that process has open'

          : 'determine whether any such process is actually a duplicate of current script'


    : 'create symlinks in the rest of the dirs'

  # attacker has created a false lockdir
  : 'if fail, then'
    
    # attacker doesn't know some info
    #   verify that the lockdir is attached to some actual process vs 
    # is a dead lock
    #   use PID... for sure ...and PPID
    #     ...and what else? memory addresses?  hashes of ...some info?
    #     UID and PWD and script name
    #   info from `ps`
    #     ...PGID... SID..
    #   info from `lsof` 
    #     [liveuser@localhost-live scf]$ time lsof 2> /dev/null \
    #       |& awk '$2 == "1315609" { print $9 }'
    #     /home/liveuser/MYPROJECTS/scf
    #     /
    #     /usr/bin/bash
    #     /usr/lib/locale/locale-archive
    #     /usr/lib64/libc.so.6
    #     /usr/lib64/libtinfo.so.6.4
    #     /usr/lib64/gconv/gconv-modules.cache
    #     /usr/lib64/ld-linux-x86-64.so.2
    #     /dev/pts/4
    #     /dev/pts/4
    #     /dev/pts/4
    #     /home/liveuser/MYPROJECTS/scf/find-and-scan-shell-scripts-sh~
    #     
    #     real	0m6.177s
    #     user	0m2.615s
    #     sys	0m3.366s
    #   
    #   Stop trying to re-invent the wheel?
    #   
    : 'Test for check-digit random string in xattr' 

      : 'If fail, then print alert and exit'

    : 'print error and exit'
: ''
: ''
: ''
: ''
: ''
: ''


exit "${LINENO}"
_full_xtrace



: 'Search for scripts using either -bash- or -find-' 

: 'BASH'

# Bug: greps. parse full outputs of type and command

# define STRING
STRING='export'

# remove all variable and nameref name collisions
dec_o="$(declare -p "${STRING}")"
if [[ -n "${dec_o}" ]]; then
  unset -v "${STRING}"
  unset -n "${STRING}"
fi

# type -t
while true; do
  tt_o="$(type -t "${STRING}")"
  case "${tt_o}" in
  
    # remove builtin
    builtin) 
      enable -n "${STRING}" 
      ;;
  
    # remove functions
    function) 
      unset -f "${STRING}" 
      ;;
  
    # remove alias
    alias) unalias "${STRING}" 
      ;;
  
    # Bug: why is '/bin/export' absent from this list?
    
    file)
      mapfile -d '' -t type_a_files < <(
        type -a "${STRING}" \
          | awk -F"${STRING} is " \
            "/^${STRING} is \//"' { printf "%s\0", $2 }' 
      )
      declare -p type_a_files

      for f in "${type_a_files[@]}"; do 
        rpm_Vf_o="$(rpm -Vf "${f}" 2>&1)"; 
      
        if [[ -n "${rpm_Vf_o}" ]]; then 
          printf 'rpm: %s\n' "${rpm_Vf_o}"; 
      
          # parse output of `rpm`:
            # [root@localhost-live ~]# type -a export
            # export is a shell builtin
            # export is /usr/bin/export
            # export is /bin/export
            #
            # [root@localhost-live ~]# rpm -Vf /usr/bin/export
            # file /usr/bin/export is not owned by any package    # <
            #
    
          if grep -q 'is not owned by any package' <<< "${rpm_Vf_o}"; then 
            echo rm --one-file-system --preserve-root=all -f "${f}"
            continue 1
          fi
        fi; 
      done && unset f rpm_Vf_o
      unset type_a_files
    
      # And... what if it's "owned" by a package from some other package 
      # manager (PM)?
      #
      # each distro has a "primary" package manager, through which any 
      # "secondary" package managers would be installed. The distro - 
      # primary PM associations... is a conf file. 
      #   So, (a) which distro is this script running on, then
      #       (b) query the primary PM
      #
      #   (Partial) List:
      #   0install chocolatey cpan cran dnf docker dpkg emerge flatpak 
      # guix homebrew ipkg maven nix npm opkg pacman petget pip portage 
      # rpm rubygems scoop slapt-get snap apk-tools zypper
      #
      # see also: https://metacpan.org/release/Alien-Packages
      ;;

    keyword) 
      true
    
      # testing: shadow a string that is a keyword and that doesn't
      #   also fall into any other category defined by `type -a`
      #
      # [root@localhost-live ~]# compgen -k
      # if then else elif fi case esac for select while until do done in
      # function time { } ! [[ ]] coproc
      ;;
  esac
done && unset tt_o

# remove hash table
# lookup file and force a PATH search with type -P
# type -a

# dnf provides FILE
# rpm -V RPM
# dnf -y --allowerasing reinstall RPM



##  Thoughts
#   
#   Remove variables and parameters. 
#   
#   with bash, use `type -t` and case to ID how the shell would call 
# a command name, and take appropriarte action from there by removing 
# anything that isn't a file, ie, an alias, function, etc.  
#
#   Then use `type -a` and parse the output of that also, removing 
# non-files (ie, syms) as necc.
#     - `type -a` ignores dangling symlinks
#   
#   Then use `hash -r; type -P` to get the list of matches within PATH
#   
#   compare the results against `rpm -V`
#     do any rpm reinstallations as necc
#
#   if there are (God forbid) any files w/o rpms, either 
#     print an error and exit, or
#     offer option to remove the file. 
#

exit "${LINENO}"
_full_xtrace


# Bug: this section /\ and this section \/ need to be merged.

: 'Get all the commands: bash'

# get list of actual top level directories
mapfile -t real_dirs < <(
  sudo find / -maxdepth 1 -mindepth 1 -type d \! -empty \
    | sort
)
re="$(
  printf '(%s' "${real_dirs[0]#/}"
  unset 'real_dirs[0]'
  printf '|%s' "${real_dirs[@]#/}"
  printf ')\n'
)"

# get completion strings with `compgen`, and ID commands with `type -a`
if [[ "${methods_prog_cv}" = bash_type_a ]]
then

  # create a single array of all commands found by each kind of search.
  # to do this...
  unset allchr char i all_commands real_dirs re tempd

  # Workaround: `compgen -c "*"` was picking up executable shell
  # scripts from the CWD
  tempd="$(mktemp -d --suffix=."${mktemp_sfx/%.xtr/.d}")"
  cd "${tempd}" \
    || fn_erx cd
  
  # create a dictionary list of each possible initial character, and
  # include commands with odd yet permitted-by-Linux initial
  # characters, such as \n \t \c or \l, etc
    #for i in 33 42 46 47 58; do
    #for i in 91 95; do
    #for i in {97..127}; do
  for i in 8 9 10 11 12 13 {32..127}; do
    allchr+=(["$i"]="$(printf '%b' "\\$(printf %03o "$i")")")
  done
  allchr[10]=$'\n'
  unset i
  
    # <>
    _full_xtrace
    set -x

  # for each possible ascii character or value
  for i in "${!allchr[@]}"; do
  
    # get a per-character (sub-)list of possible command completions
    mapfile -t per_idx_commands < <(
      compgen -A command "${allchr[i]}"
    )
  
      # <>
      #declare -p per_idx_commands

    # One difficulty is that a completion string can be any of
    # actual binary command, function, alias, shell keyword,
    # shell builtin and/or directory

    # for each possible completion string found by `compgen`
    for n in "${!per_idx_commands[@]}"; do
     
        # <> A sort of progress meter
        printf '%s\n' "${per_idx_commands[n]}"

      # ...why? ...debugging... was the original idea. fewer commands, 
      # easier to run and catch bugs quickly...

      # Bug: command shadowing nightmare

      # Search for commands based on the 
        
      # For anywhere in PATH: bash_type_a
      # use `type` to get the shell's definition(s) of `compgen`s 
      # completion string, then use `grep` to filter out full 
      # function definitions.
      mapfile -t shell_builtin_o < <(
        builtin type -a "${per_idx_commands[n]}" \
          |& grep -F "${per_idx_commands[n]}"' is '"${re}"
          #|& grep -F "${per_idx_commands[n]} is "
      )
      
      # if `type -a` has no knowledge of the completion string, 
      if [[ -z "${shell_builtin_o[*]}" ]]; then
        
        # then unset the completion string and start with the next one
        unset_per_idx_commands_n=yes
      fi

      # for each line of output from `type -a`
      for line in "${!shell_builtin_o[@]}"; do
      
        # if any result (ie, index) of `type -a`s output refers to an
        # alias, function or shell keyword, then unset that index
        if grep -qE ' is a(liased| function| shell (builtin|keyword))' \
            <<< "${shell_builtin_o[line]}"; 
          then
            unset 'shell_builtin_o[line]'
        
        # if any result refers to a file...
        elif grep -qE ' is /' <<< "${shell_builtin_o[line]}"; then 
         
          command_basename="${shell_builtin_o[line]##*/}" \
            command_fullpath="${shell_builtin_o[line]##* }" 
          
              # <>
              #declare -p all_commands per_idx_commands \
                #shell_builtin_o line command_basename \
                #prev_per_idx_cmds

          # ...and if that file is not already included in either the 
          # larger all_commands list or the per-ascii-character
          # prev_per_idx_cmds list...
          if ! [[ "${all_commands[*]}" =~ ${command_basename} ]] \
            && ! grep -qE "$( printf '\%s' "${command_basename}" )" \
              2> /dev/null <<< "${prev_per_idx_cmds[@]}"
          then

            # ...then record the command's basename in the 
            # prev_per_idx_cmds list, unset the type-a output index
            # and start with the next line of type-a output
            prev_per_idx_cmds+=("${command_basename}")
            unset 'shell_builtin_o[line]'
            continue
        
          else
            unset 'shell_builtin_o[line]'
          fi
        fi; 

        # if all lines of `type -a`s output have been deleted, then 
        # begin with the next completion string
        if [[ "${#shell_builtin_o[@]}" -eq 0 ]]; then
          unset_per_idx_commands_n=yes
        fi
      done
    
      # Bug: save to an array the canonicalized pathname of each command.
    
      # remove any directories from the (sub-)list
      if [[ -z "${unset_per_idx_commands_n}" ]]; then
        realpath_e_o1="$(realpath -e "${per_idx_commands[n]}" 2>/dev/null)"
        realpath_e_o2="$(realpath -e "${command_basename}" 2>/dev/null)"
        realpath_e_o3="$(realpath -e "${command_fullpath}" 2>/dev/null)" #<
      
        if [[ -d "${realpath_e_o1}" ]] \
          || [[ -d "${realpath_e_o2}" ]] \
          || [[ -d "${realpath_e_o3}" ]];
        then 
          unset_per_idx_commands_n=yes
        fi; unset line shell_builtin_o realpath_e_o{1..3} \
          command_basename command_fullpath
      fi
      
      if [[ "${unset_per_idx_commands_n}" == yes ]]; then 
        unset 'per_idx_commands[n]'
      fi; unset unset_per_idx_commands_n 
    done && unset n prev_per_idx_cmds
    
    # add the (sub-)list to the full list, being careful of index numbers
    mapfile -O $((i * 1000)) -t all_commands < <(
      for x in "${per_idx_commands[@]}"; do
        printf '%s\n' "${x}"
      done && unset x per_idx_commands
    )
  done && unset i
  
    # <>
    echo 'all_commands, count:' "${#all_commands[@]}"
    exit "${LINENO}"
    _full_xtrace
 
  cd - \
    || fn_erx cd
  rmdir -v "${tempd}"; unset tempd

elif [[ "${methods_prog_cv}" = *bin_find ]]; then
  hash find 2>/dev/null \
    || exit "${LINENO}"

else
  echo error
fi

# <>
_full_xtrace
exit "${LINENO}"



: 'FIND'

: 'Gather filenames from local attached disk storage'

if [[ "${ABBREV_REL_SEARCH_DIRS}" == all ]]; then

  : 'set a value for a_relevant_search_dirs and..'
  mapfile -d '' -t a_relevant_search_dirs < <(
    sudo  find "${find_sym_opt_L}" "${find_path[@]}" -mindepth 1 \
      -maxdepth 1 -type d \! -empty \
      "${find_exclude_optargs[@]}" -print0 2>/dev/null
  )

  for sd in "${a_relevant_search_dirs[@]}"; do

    # assign
    echo "${sd}"
  done

fi

: 'Find all files within the search area. Even the empty ones.'
mapfile -d '' -t a_all_files < <(
  sudo  find "${a_relevant_search_dirs[@]}" -mindepth 1 -type f \
    -print0 2>/dev/null
)

: 'Sort the original array and test it.'
mapfile -d '' -t a_all_files_sorted < <(
  printf '%s\0' "${a_all_files[@]}" \
    | sort -z
)

_full_xtrace
exit "${LINENO}"




# SECTION D

# Bug? Can more indices and fewer files be used?

: 'Sort out the scripts, ie, any file beginning with a crashbang from'
: 'the rest of the files'

: 'Get the total number of found files, for the progress indicator'
total_count="$(printf "%'d" "${#a_all_files_sorted[@]}")"
unset IFS


# Bug: the search dirs must be the same, as well as the dnf tx number
# Bug: Use of /tmp/crunchbangs as yn on do loop q. Sb a set of file lists
#.   difftd by search dir / search type / etc. See file "priority"


for all_files_index in "${!a_all_files_sorted[@]}"; do

  : 'Loop'

  loop_idx="$(printf "%'d" $((all_files_index + 1)))"
  printf '%s of %s files\r' "${loop_idx}" "${total_count}"

  : 'file must exist'
  each_sorted_f="${a_all_files_sorted[all_files_index]}"

  if [[ ! -e "${each_sorted_f}" ]]; then
    a_file_DNE+=([all_files_index]="${each_sorted_f}")
    continue
  fi

  : 'list of empties'
  if [[ ! -s "${each_sorted_f}" ]]; then
    a_empty_files+=([all_files_index]="${each_sorted_f}")
    continue
  fi

  : '-file- magic'
  printf '+ %-8d: ' "${all_files_index}" \
    | sudo  tee -a -- "${curr_time_ssubd}file_out" >/dev/null

  file_o="$(sudo  file -pk -- "${each_sorted_f}" 2>&1)" # Bug: needs erx
  file_o="${file_o%%64-bit LSB *}"
  a_bin_file_output+=([all_files_index]="${file_o}")

  # Bug? Needs tracking index? One array or file, one line per fso,
  #. use symbols or csv to indicate test results, w common indices
  # Bug: [[ -n sb right after exec file

  if [[ -n "${file_o}" ]]; then
    sudo  tee -a -- "${curr_time_ssubd}file_out" <<<"${file_o}" \
      >/dev/null
  else
    err_msg="WARNING: -file- produced 0 output:  <${each_sorted_f}>"
    sudo  tee -a -- "${curr_time_ssubd}file_out" <<<"${err_msg}" \
      >/dev/null
  fi

  # Bug: keep `od` output in an array
  # Bug: avoid as many disk writes as possible.
  #  Write out only stats?
  # Bug: use indices to reference each type? Store array diffs btw
  # loop? Time loss to disk io? Run file in parallel? Read each file
  # once and use var for both od and file?

  : 'two bytes each'

  #set -x; :;: "<>"

  # fix?: mapfile -d '' -t -O "${all_files_index}" a_od_output

  od_o="$(
    sudo  od -j 0 -N 2 -t x1z -v -- "${each_sorted_f}" \
      | tr -s ' ' \
      | gawk --lint '{ print $2, $3, $4 }' \
      | tr -d '\n' \
      || fn_erx "P:${PIPESTATUS[*]} I:${all_files_index} ${each_sorted_f}"
  )"

  [[ -n "${od_o}" ]] \
    || fn_erx "I:${all_files_index} ${each_sorted_f}"

  a_bin_od_output+=([all_files_index]="${od_o}")

  read -r byte_0 byte_1 printable_chars <<<"${od_o}"

  export printable_chars # SC-2034

  : '-od_o- non-zero'
  if [[ -z "${byte_0}" ]]; then
    fn_erx "I:${all_files_index} <${each_sorted_f}>" \
      '*unreachable code*'
  elif [[ "${byte_0}" == @(23|21) ]]; then
    : 'compare hexadecimals'

    : 'endianness'
    # https://unix.stackexchange.com/questions/55770/does-hexdump-respect-the-endianness-of-its-system
    # Also:  `lscpu | awk '/Endian/ { print $3 }`
    if [[ "${byte_0}${byte_1}" == 2123 ]]; then
      a_incorrect_endianness+=([all_files_index]="${each_sorted_f}")

    else

      : 'Crunchbangs'

      # q, does strings recognize unicode? Color codes? Cr's? Etc
      # test dd vs strings

      strings_o="$(strings -n1 <"${each_sorted_f}" \
        | head -n1 \
        | cut -b -$((2 ** 14)) \
        || fn_erx "P:${PIPESTATUS[*]} I:${all_files_index} \
          ${each_sorted_f}")"

      IFS= read -r first_line_printable <<<"${strings_o}" \
        || fn_erx "I:${all_files_index} ${each_sorted_f}"

      : '-#!comment-'
      if [[ "${first_line_printable}" =~ ^'#!comment' ]]; then
        a_crunches_with_hashbang_comments+=(
          [all_files_index]="${each_sorted_f}")
        continue
      fi

      #   Note: with only /bin/sbin, this if-fi block doesn't execute

      # FR: sort also per-rpm, awk script, probably

      : 'outside of rpm'
      if ! rpm -qf "${each_sorted_f}" 2>/dev/null 1>&2; then

        : 'user or system'
        if [[ "${each_sorted_f}" = /@(root|home|run/media)/* ]]; then
          a_non_rpm_user_crunches+=(
            [all_files_index]="${each_sorted_f}"
          )
          continue
        else
          a_non_rpm_system_crunches+=(
            [all_files_index]="${each_sorted_f}"
          )
          continue
        fi
      fi
    fi

    #set -x; :;: "<>"

    # scan non-shell scripts for shell escapes ie sys-bin calls
    # https://www.sans.org/blog/escaping-restricted-linux-shells/

    # Bug, "shell scripts" incls python perl etc

    # how to make IRT lists for each interpreter?

    : 'Make an array of the relevant filenames and their crashbangs.'
    a_shell_scripts+=([all_files_index]="$(printf \
      "%'-12d %%=%%=%%=%% %-50s %%=%%=%%=%% %s\n" \
      "${all_files_index}" "${first_line_printable}" \
      "${each_sorted_f}")"
    )

  else

    : 'all others'
    a_all_other_files+=([all_files_index]="$(printf \
      "%'-12d %%=%%=%%=%% %s\n" "${all_files_index}" \
      "${each_sorted_f}")"
    )
  fi
done

# Note, you want to see the full crunchbangs in printed ASCII form

: 'Open a timestamped file and append into it the list of filenames'
: 'and their crashbangs.'

: 'Exporting is necessary of the array names from the above scan'
a_arrays=(a_all_files a_all_files_sorted a_file_DNE a_empty_files
  a_bin_file_output a_bin_od_output a_incorrect_endianness
  a_crunches_with_hashbang_comments a_non_rpm_user_crunches
  a_non_rpm_system_crunches a_shell_scripts a_all_other_files
  a_write_path_nms)
export "${a_arrays[@]}"

fn_write_arrays "${a_arrays[@]}"
fn_bak "${curr_time_ssubd}/file_out"
#exit "${LINENO}";

: 'create the original list_crunchbangs'
sudo  touch -- "${a_write_path_nms[@]}"

: 'write a file header'
{
  printf '# crunchbangs -- %s\n' "${timecode%-*}"
  printf '# %s\n' "$(declare -p a_relevant_search_dirs)"
} | sudo  tee --output-error=exit  -- "${a_write_path_nms[@]}" >/dev/null

: 'printing contents of a_shell_scripts array, with backup'
printf '%s\n' "${a_shell_scripts[@]}" \
  | sudo  tee --output-error=exit  -a -- \
    "${a_write_path_nms[@]}" >/dev/null
fn_bak "${a_write_path_nms[@]}"

_full_xtrace
exit "${LINENO}"

# <> ?
fn_write_arrays a_write_path_nms

#set -x; :;: "<>";

sudo  head -- "/tmp/${list_crunchbangs##*/}"
#exit "${LINENO}";

: 'Verify interpreters'

: 'Get the list of interpreters from the list of crunchbangs.'
#   Note: new indices starting from 0
# use the contrived delimiter to capture entire shebang string
# remove leading whitespace
# sort and print unique
# remove leading ^'#!' from each interpreter
# Note: in `awk` cmd, %=%=%=% may need to be double quoted
mapfile -t a_interpreters < <(
  sudo gawk --lint 'BEGIN { FS = "%=%=%=%" } ; /#!/ { print $2 }' -- \
    "/tmp/${list_crunchbangs##*/}" \
    | gawk --lint 'BEGIN { FS = " -" } ; { print $1 }' \
    | sed 's, *,,g' \
    | sort -u \
    | cut -b3- \
    || fn_erx "P:${PIPESTATUS[*]}"
)

_full_xtrace
exit "${LINENO}"

# <>
:;: "<>"
#exit "${LINENO}"

# Duplicate with post-getopts section ?

: 'Ways to find an interpreter if it-s available on disk:'

# Bug: `realpath -e` and `type -a` are redundant?
# Answer: no. `command` is limited to PATH; realpath is limited by
# FS permissions.

# `find` can produce symlinks or actual files
#   # find /usr/sbin -type l | grep resolvconf
#       /usr/sbin/resolvconf
# `command` can produce symlinks
#   # type -a resolvconf
#       resolvconf is /usr/sbin/resolvconf
# `realpath` produces physical paths
#   # realpath -e /usr/sbin/resolvconf
#       /usr/bin/resolvectl

# Bug: parse output of type -a

for program in "${a_interpreters[@]}"; do
  : 'type -a'
  command_o="$(type -a "${program}" 2>&1)"

  if [[ -n "${command_o}" ]]; then
    realpath_o="$(realpath -e "${command_o}" 2>/dev/null)"

    if [[ -f "${realpath_o}" ]]; then
      a_interps_rps+=("${realpath_o}")
      on_disk="exists on disk"
      break
    fi
  fi
done

# Bug: add "-d ''" to mapfile

# Canonicalize interpreters paths, sort and list each unique binary.
#   Note: new indices starting from 0
mapfile -t a_interps_rps < <(
  sudo realpath -e -- "${a_interpreters[@]}" \
    | sort -u
)

_full_xtrace
exit "${LINENO}"

# <>
exit "${LINENO}"

# for each interpreter, print it in the 1st 32 bits of a line.

{
  for b in "${!a_interps_rps[@]}"; do

    printf '%-32s' "${a_interps_rps[b]}"

    # Bug: use `type -a`; parse its output

    # use a shell builtin to test for each interpreter's presence on
    # disk, and write to a variable the test's result

    if type -a "${a_interps_rps[b]}" >/dev/null; then
      on_disk="exists on disk"
    else
      on_disk="DNE on disk"
    fi

    # create a new array of structured data: index, interpreter and
    # test result
    a_interps_disk_repo+=([b]="${b} : ${a_interps_rps[b]} : ${on_disk}")

    # into the next 8 bits of a line, print the test result
    printf '%-8s' "${on_disk}"

    # identify the originating rpm for each interpreter.
    # binary need not be installed.
    # filter for rpm name by CPU type in its filename
    # sort rpms and print each unique
    dnf_po="$(
      sudo  dnf provides -- "${a_interps_rps[b]}" \
        | gawk --lint '/x86_64|i686/ { print $1 }' \
        | sort -u
    )"

    # based on whether there was any output,
    # save a result message to variable
    if [[ -n "$dnf_po" ]]; then
      in_repos="exists in repos"
    else
      in_repos="DNE in repos"
    fi

    # in the same array, in a different range of indices,
    # save the index, interpretet name and rpm test result
    a_interps_disk_repo+=([b + 100]="${b} : ${a_interps_rps[b]} : ${in_repos}")

    # print rpm test result to end of line; include a newline
    printf '\t\t\t\t%s\n' "${in_repos}"

    # if any data exists, print the list of originating rpms
    printf '%s\n' "$dnf_po"
    unset dnf_po on_disk in_repos

  done
} | sudo  tee --output-error=exit  -a -- \
    "${curr_time_ssubd}a_interpreters" >/dev/null
unset b

# <>
#set -x; :;: "<>";
fn_write_arrays a_write_path_nms a_interpreters a_interps_rps \
  a_interps_disk_repo
exit "${LINENO}"

_full_xtrace
exit "${LINENO}"

# SECTION E

: 'CENTRAL TASK, 1 OF 2: Filter the list of crashbangs with the list'
: 'of shells.'

# print one file header

{
  printf '# SC-scrpts-list -- %s\n' "${timecode%-*}"
  printf '# %s\n' "$(declare -p  a_relevant_search_dirs)"
} | sudo  tee --output-error=exit  -- \
    "${list_crunchbangs}_SC-scrpts-list" >/dev/null

# filter out interpreters not compatible with shellcheck.
# file $list_crunchbangs is located in $time_dir.
sudo  grep -E -- '/bin/'"${SC_shells}"'.*%=%=%=%' "${list_crunchbangs}" \
  | sudo  tee -a -- "${list_crunchbangs}_SC-scrpts-list" \
  || fn_erx "${LINENO}"

# Copy list to /tmp
sudo  rsync -ca -- "${list_crunchbangs}_SC-scrpts-list" /tmp \
  || fn_erx "${LINENO}"

# Backup both lists
fn_bak "${list_crunchbangs}_SC-scrpts-list" /tmp/*_SC-scrpts-list

# <>
_full_xtrace
:;: "<>"
fn_write_arrays timecode list_crunchbangs SC_shells
exit "${LINENO}"

_full_xtrace
exit "${LINENO}"

: 'CENTRAL TASK, 2 of 2: with ShellCheck scan each script for errors'

# TODO: keep "$all_files_index" tracked with content all the way through
#   into the "_found_scripts" file

# Bug? line 1 of script could contain percent symbols

: 'A hell world of pipelines'
#   Q: how to translate the correct newlines into nulls to separate the
#   filenames when reading from a file?  awk? files _can_ contain \n-s

# for every line beginning with a crashbang...
grep_o="$(sudo  grep ^'#!' -- "${list_crunchbangs}_SC-scrpts-list")"

# get the filename
cut_o="$(cut -d '%' -f5- <<<"${grep_o}")"

# collect the filenames in a single list
mapfile -t a_each_abspath_scriptnm <<<"${cut_o}"

# remove leading whitespace
a_each_abspath_scriptnm=("${a_each_abspath_scriptnm[@]##* }")

# Wk: awk , multi-char delim, remv lead+trail wspc - redef $0 ?, printf

#   grep -Eo | tr

# Bug: rename variable "$c" below
# Bug: why sort by line count? More text, more Bugs? How to prior mult
#   factors?

# count number of newlines in each script
wc_o="$(sudo  wc -l -- "${a_each_abspath_scriptnm[@]}")"

# remove 'totals' line
wc_o="${wc_o%$'\n*'}"

# sort script lengths descending
sort_o="$(sort -gr <<<"${wc_o}")"

# print script names
awko="$(gawk --lint '{ print $2 }' <<<"${sort_o}")"

# create a list of script names sorted by line count descending
mapfile -t a_each_script_list_sorted_by_linect \
  <<<"${awko}"

# define file name, including severity and path symbols (target file)
found_scrpts_f="${list_crunchbangs}_found_scripts"
found_scrpts_f+="_${sc_sev_abrv}_${ABBREV_REL_SEARCH_DIRS}"
i=0

# Bug? 1st grep extra?

{

  # for each sorted script
  for sorted_script in "${!a_each_script_list_sorted_by_linect[@]}"; do

    # run shellcheck with selected/default severity
    # remove URL's
    # capture SC error codes with their descriptions
    # truncate descriptions to 64 bytes
    # sort numerically
    # count the number of unique errors
    # sort by the third column: severity
    # collect output in an array
    # on any non-zero exit status, print an error, incuding PIPEFAIL
    # array, and exit the script when filters, etc completes, print
    # a NULL to start a new mapfile index
    mapfile -d '' -t a_each_script_SC_results < <(
      shellcheck -S "${sc_severity}" \
        "${a_each_script_list_sorted_by_linect[sorted_script]}" \
        | grep -Fv 'shellcheck.net' \
        | grep -Eo "SC[0-9]{4}.*" \
        | cut -b -64 \
        | sort -g \
        | uniq -c \
        | sort -k3 \
        || fn_erx "P:${PIPESTATUS[*]} I: S:" # index and script name
      # end of pipe intended
      printf '\0'
    )

    # if there's any output from shellcheck
    if [[ -n "${a_each_script_SC_results[*]:0:1}" ]]; then

      # Bug: iterator sb $sorted_script ? sorted_script should have

      # print a line header. (as-is:) including a new index number
      # for each script
      printf '\n%-4d%s\n' $((i++)) \
        "${a_each_script_list_sorted_by_linect[sorted_script]}"
      # print all massaged SC results for each script
      printf '%s' "${a_each_script_SC_results[@]}"
    fi
  done
  unset i

  # append each text group to a findings file
} | sudo  tee -a -- "${found_scrpts_f}" >/dev/null

: 'Write semi-permanent archives'

# backup the findings file
fn_bak "${found_scrpts_f}"

# make copies of the findings file and backup those copies
for d in /tmp "${main_d}"; do
  sudo  rsync -ca -- "${found_scrpts_f}" "${d}" \
    || fn_erx "${LINENO}"
  fn_bak "${d}/${found_scrpts_f##*/}"
done
unset d

# <> Print some variables for interactive use
z=0
for d in "${curr_time_ssubd}" "${main_d}" /tmp; do
  printf '\n\t data_d_%d=%s\n' $((z++)) "${d}"
done
unset d z

trap - EXIT
exit 00

# TODO: 
#   - grep output of `rpm -qi` for URL's, ie, github. which can I 
#       repair without adding a new login?
#   - grep scripts for 'todo's
#   - grep for 'shellcheck disable'
#   - grep for 'bash -c' and 'sh -c'
#   - grep for '(source|\.) .?.?/'
