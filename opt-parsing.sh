# Option parsing
# shellcheck shell=bash


  # <> Obligatory debugging block
  _post_src "${nL}" "$@"
  #_full_xtrace
  : "${nBS[0]}:${nL} ${nBS[1]}:${nBL[0]}"
  #exit "${nL}"
  #set -x


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
unsaf_ascii_Pfn_erexstring="$(printf '%s' "${unsaf_ascii[@]}" 2>&1)"
bash_path_orig="${PATH}"
bash_path="${bash_path_orig}"
easter_egg="$(
  {
    printf '%s%s%s' 'CgkiSSB3b3VsZCBoYXZlIG1hZGUgdGhpcyBzaG9y' \
      'dGVyLCBidXQgSSBkaWRuJ3QgaGF2ZSB0aGUg' \
      'dGltZS4iCgkJLS0gTWFyayBUd2FpbgoK' | 
    base64 -d
  } 2>&1
)"
find_exclude_optargs_default=(
  [0]='(' [1]='!' [2]='-name' [3]='proc' [4]='-a' [5]='!'
  [6]='-name' [7]='sys' [8]='-a' [9]='!' [10]='-iname'
  [11]="${scr_dirnm}*" [12]='-a' [13]='!' [14]='-ipath'
  [15]="${scr_protected_git_dir_1}" [16]='-a' [17]='!' [18]='-ipath'
  [19]="${scr_protected_git_dir_2}" [20]='-a' [21]='!' [22]='-path'
  [23]='*/git/*' [24]=')'
)
find_exclude_optargs=()
IFS=':' read -ra find_path <<< "${bash_path}"
find_sym_opt_L='-L'
sc_sev_abrv="${SC_sevr:0:1}"
#methods_recurse_n=no
methods_path=('as-is')
methods_prog_cv=bash_type_a
#methods_scan_excluded_by=yes
#methods_symlinks_l=logical
verify=(all)

# <>
#_full_xtrace
#exit "${nL}"

# TODO: review options & fix this function
fn_usage() {
  # Print a usage message and exit with a pre-determined exit code
  # Usage:  fn_usage [exit-code]
  : 'fn_usage BEGINS' "${fn_bndry}" "${fn_lvl}>$((++fn_lvl))"
  {
    cat <<-EOF
    ${scr_repo_nm} - ${scr_proper_nm}, version ${scr_version}
      Find and scan shell scripts depending on severity level.
      Options are parsed by bash's builtin "getopts".
    Usage:
      ./${scr_nm} -H [b|p|l] -M [r|p|t]
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
  } 2>&1 |
    more -e
  : 'fn_usage ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
  exit "$1"
}

: 'Option parsing'

shopt -s nocasematch
while getopts "a:bc:d:hl:m:p:q:r:s:v" cli_input; do

  # Parse command line options
  case "${cli_input}" in

    # Bug: what does '-a' mean?

    # PATH (array) - Part 2 - options with args
    a)
      # Input validation, more thorough. Remove unprintable strings.
      OPTARG="$(strings -n1 <<< "${OPTARG}" 2>&1)"

      # Remove unsafe characters
      new_optarg="${OPTARG//["${unsaf_ascii_Pfn_erexstring[@]}"]/}"

      # Bug: printf cmd: '-R'

      # If any ASCII characters were removed, print an error and exit
      if [[ "${new_optarg}" != "${OPTARG}" ]]; then
        printf '\n\tError: option -R: directory name includes '
        printf 'an illegal character\n\n'
      fi

      # Canonicalize path
      new_optarg="$(realpath -e "${new_optarg}" 2>&1)"

      # Amended value must be a directory
      if [[ ! -d "${new_optarg}" ]]; then
        "${arg_wrong__a:?}"
      fi

      # Append dirname to bash_path and reset find_path
      bash_path+=":${new_optarg}"
      IFS=":" read -ra find_path <<< "${bash_path}"

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
      e*) SC_sevr=error ;;
      i*) SC_sevr=info ;;
      s*) SC_sevr=style ;;
      w*) SC_sevr=warning ;;
      *) "${arg_wrong__c:?}" ;;
    esac ;;

    # Bug: rewrite this comment
    # TODO: clobbering settings sb in upper case

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
        IFS=":" read -ra find_path <<< "${bash_path}"
        find_exclude_optargs=()
        methods_path=(actually_all)
        methods_prog_cv=bin_find
        #methods_scan_excluded_by=yes
        ;;
      al* )
        bash_path='/'
        IFS=":" read -ra find_path <<< "${bash_path}"
        find_exclude_optargs=("${find_exclude_optargs_default[@]}")
        methods_path=(all)
        methods_prog_cv=bin_find
        #methods_scan_excluded_by=no
        ;;
      as* | ai*)
        bash_path="${bash_path_orig}"
        IFS=":" read -ra find_path <<< "${bash_path}"
        methods_path=('as-is')
        ;;
      bi* | b)
        bash_path='/usr/bin'
        IFS=":" read -ra find_path <<< "${bash_path}"
        methods_path=(bin_only)
        ;;
      bo* | bs*)
        bash_path='/usr/bin:/usr/sbin'
        IFS=":" read -ra find_path <<< "${bash_path}"
        methods_path=(both_bin_sbin_only)
        ;;
      ge* | g)
        bash_path="${PATH_getconf}"
        IFS=":" read -ra find_path <<< "${bash_path}"
        methods_path=(getconf_PATH_only)
        ;;
      sb* | so* | s)
        bash_path='/usr/sbin'
        IFS=":" read -ra find_path <<< "${bash_path}"
        methods_path=(sbin_only)
        ;;
      pr* | p | pa*)
        bash_path+=':/proc'
        IFS=":" read -ra find_path <<< "${bash_path}"
        methods_path+=(add_proc)
        methods_prog_cv=bin_find
        find_exclude_optargs=()
        #methods_scan_excluded_by=yes
        ;;
        
        # TODO: spaces around all redir operators
        
      sy* | sa*)
        bash_path+=':/sys'
        IFS=":" read -ra find_path <<< "${bash_path}"
        methods_path+=(add_sys)
        methods_prog_cv=bin_find
        find_exclude_optargs=()
        #methods_scan_excluded_by=yes
        ;;
      *) "${arg_wrong__d:?}" ;;
    esac ;;

    # Help message
    h) fn_usage 0 ;;

    # Bug: is it only GNU find w '-P' & '-L'?

    # Follow symlinks
    #   `bash` always follows symlinks, therefore to not follow any
    # symlinks requires `find` and is a clobbering setting, ie,
    # selecting either '-h P' or '-h L' will also select the use of
    # `find`. The 'P' and 'L' refer to `find`s first argument, which
    # by default is assumed (by `find`) to be '-P'. `find -H` is not
    # implemented in this script. Default is bash.
    #   Side effect: setting '-l p' also clobbers this variable. Side
    # effects such as these are marked below as "clobber."
    
    # TODO: some "production" level solution other than :?
    #   This parameter expansion, ':?', when a parameter is null or
    # unset, causes the shell to immediately halt, ignoring any trap
    # on EXIT.
    
    # TODO: move this comment into usage function
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
      #r*) memory_usage=sudo namei -xl only ;; # ?? sed error?
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
      a | al*) verify=(all) ;;
      u | un*) unset verify ;;
      *) [[ "${verify[*]}" =~ all ]] \
        && unset verify ;;&
      l | ac*) verify+=(acls) ;;
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
      n | b)
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
        s | y | b) # Q: what do these letters stand for?
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
            IFS=":" read -ra find_path <<< "${bash_path}"
          done; unset x
          ;;
        *)
          "${arg_wrong__s:?}"
          ;;
      esac ;;

    v) printf '\n\t%s, version %s. %s.\n\n' "${scr_proper_nm}" \
      "${scr_version}" "${scr_lic}" ;;

    *) fn_usage 1 ;;
  esac
done
shopt -u nocasematch

# TODO? resolve use of nocasematch vs use of upper to denote clobbering setting?


#declare -p  methods_symlinks_l methods_recurse_n methods_prog_cv \
  #methods_scan_excluded_by find_sym_opt_L find_exclude_optargs \
  #bash_path find_path PATH methods_path

# <>
#_full_xtrace
#exit "${nL}"


