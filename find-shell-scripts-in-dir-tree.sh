#!/bin/bash -x
# find-shell-scripts-in-dir-tree.sh
# Written for bash version 5.1


# Vars & directory for saving findings
# shellcheck disable=SC2184
unset [a-zA-Z] # expansion of single-letter variables is intended
m="${TEMPDIR:="$HOME"}" # default save directory, a <m>ountpoint
r='(binfmt_misc|bpf|cgroup2|configfs|debugfs|devpts|devtmpfs|efivarfs|fusectl|hugetlbfs|iso9660|mqueue|proc|pstore|rpc_pipefs|securityfs|selinuxfs|sysfs|tmpfs|tracefs)' # <r>egex of `mount` "fstype"s 
t="$( date '+%F_%H%M%S' )" # <t>ime

# Bug? is '/run/media' portable to other distros? 
mapfile -d '' -t save_dirs < <( 
  find /run/media -mindepth 2 -maxdepth 2 -type d \
    -exec df --sync -l --output=fstype,avail,source \
    --block-size=1 '{}' ';' | 
  grep -iv avail | 
  tr '\n' '\0' )


# filter out certain FS types by <r>egex by sorting the <o>utput of `df`
for o in "${!save_dirs[@]}"; do 

  if [[ "${save_dirs[$o]}" =~ ^(${r}) ]]; then 
    unset 'save_dirs[$o]'; 
  fi; 
done

if [[ -z "${save_dirs[*]:0:1}" ]]; then

  # take the de<v>ice with the most available space, and get its
  # <m>ountpoint
  v="$( printf '%s\n' "${save_dirs[@]}" | 
    sort -grk2 | 
    head -n 1 |
    awk '{ print $3 }' )"
  m="$( mount | 
    awk "\$1 ~ /${v##*/}/ "'{ print $3 }' )"
fi


# from the local root FS tree...
f='(png|jpeg|mp4|swp)' # filter for file <format>
L='(perl|awk|false|python)' # filter for NA scripting <l>anguages
unset relevant_search_dirs all_files shell_scripts;

# ...get a list of relevant files
mapfile -d '' -t relevant_search_dirs < <(
  find / -mindepth 1 -maxdepth 1 -type d \
    \( \! -name proc -a \! -name sys -a \! \
    -name git \) -print0 )

mapfile -d '' -t all_files < <( 
  find /usr/sbin -type f -print0 2> /dev/null ) # "${relevant_search_dirs[@]}"


# sort out the <s>hell scripts from the files, with index <j>
for j in "${!all_files[@]}"; do

  # use a <n>ameref
  n="${all_files[$j]}"

  # read the first two bytes of every file on disk, and 
  # look for any files beginning with a <c>runchbang
  if [[ "$( od -Ax0 _n@ -x "$n" |
    awk '{ print $2 }' )" != '2321' ]];
  then
    unset 'all_files[$j]'
    continue
  fi # xxd -l 2 -ps "$n" | strings -n 1

  # Bug? what are the succeed/fail ratios for these tests?
  # skip the photos and media files: png, jpeg, etc...
  # also, it must have a size -gt zero
  if [[ "$n" =~ \.${f}$ ]] || 
    [[ ! -s "$n" ]]; 
  then
    unset 'all_files[$j]'
    continue
  fi

  # look for any files beginning with a <c>runch-bang
  c="$( strings -n 1 "$n" | 
    head -n 1 | 
    head -c 32 )"; 

  if [[ "$c" =~ ^'#!' ]] && 
    ! [[ "$c" =~ ${L} ]]; 
  then 

    # open & append a list
    shell_scripts+=( "$n" ); 
    printf '%s \r\t\t\t\t%s \n' "$c" "$n" >> \
      "${m}/${t}_crunches" ; 
  fi; 
done


# with ShellCheck scan each <s>cript for <e>rrors, and use an <i>ndex
for i in "${!shell_scripts[@]}"; do 

  # also use, for <s>cripts, a nameref
  declare -n s="${shell_scripts[$i]}"

  e="$( shellcheck -S error "$s" | 
    grep -vFe 'shellcheck.net' | 
    grep -Eoe 'SC[0-9]{4}' | 
    sed -e 's,^[[:space:]]*,,g' \
      -e 's,[[:space:]]$,,g' | 
    sort -gr | 
    uniq -c )";

  if [[ -n "$e" ]]; then 
		
    # open & append some prioritized work lists with indices
    printf '%d  <%s>\n' "$i" "$s" >> \
      "${m}/${t}_found_scripts_with_indices" 
    printf '%s | %d\n' "$e" "$i" >> \
      "${m}/${t}_found_errors_with_indices"
  fi
done
