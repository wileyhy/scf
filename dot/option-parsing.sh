# Option parsing

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
sc_sev_abrv="${sc_sevr:0:1}"
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
  : 'fn_usage ENDS  ' "${fn_bndry}" "${fn_lvl}>$((--fn_lvl))"
  exit "${1}"
}


