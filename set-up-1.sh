#!/bin/bash -x
# set-up-OS_sudo-sh

# Bugs: 1. output all xtrace to file
#       2. needs a process lock on kill loop

## Notes
###   Online Git Pro book:
###     https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository

# Regular users only
if [[ "${UID}" == 0 ]]; then
  printf '\n\t Must be a regular user and use sudo. \n\n'
  exit 1
else
  sudo -v \
    || exit 1
fi

# Network & time
if ! sudo ping -c 1 -W 15 8.8.8.8; then
  printf '\n\tAttempting to connect...\n\n'
  sudo systemctl start NetworkManager.service
  wait -f
  sleep 15
  if ! sudo ping -c 1 -W 15 8.8.8.8; then 
    printf '\n\tGiving up; Exiting.\n\n'
    exit "${LINENO}"
  else
    printf '\n\tSuccess!\n\n'
  fi
fi
sudo timedatectl set-local-rtc 0
sudo timedatectl set-timezone America/Vancouver
sudo systemctl start chronyd.service
sudo chronyc makestep

# Bash
## .bashrc
umask 071
bashrc_str='EDITOR=/usr/bin/vim; BROWSER=/usr/bin/firefox;'

files=(/root/.bashrc /home/*/.bashrc)
for f in "${files[@]}"; do

  if ! sudo grep -q -- "${bashrc_str}" "${f}"; then
    sudo cp -a -- "${f}" "${f}~"
    echo "${bashrc_str}" \
      | sudo tee -a -- "${f}" > /dev/null
  fi
done
unset files f

# Vim
umask 177
tmpf="$(mktemp)"
cat << EOF > "${tmpf}"
" per google:
set number

" per https://stackoverflow.com/questions/234564/tab-key-4-spaces-and-auto-indent-after-curly-braces-in-vim
filetype plugin indent on
" show existing tab with 2 spaces width
set tabstop=2
" when indenting with '>', use 2 spaces width
set shiftwidth=2
" On pressing tab, insert 2 spaces
set expandtab
EOF
# shellcheck disable=SC2024
sudo tee /root/.vimrc < "${tmpf}" > /dev/null
rm -f -- "${tmpf}"
unset tmpf

## Copy root-user files to $USER
sudo rsync -ca /root/.vimrc "/home/${USER}"
sudo chown "${UID}:${UID}" "/home/${USER}/.vimrc"
chmod 0400 "/home/${USER}/.vimrc"

# Dnf
sudo dnf -y install git-fame \
  angband \
  git gh \
  ShellCheck kcov shfmt patch strace ltrace \
  info binutils parallel procmail \
  lynx libreoffice-calc chromium \
  debian-keyring
  #memstomp bpftrace gdb valgrind
sudo dnf -y upgrade bash
sudo dnf -y --security upgrade
#set -x
sleep 10
dnf_o="$(sudo dnf needs-restarting 2>/dev/null)"
[[ -n "${dnf_o}" ]] &&
  awk_o="$(awk '{ print $1 }' <<<"${dnf_o:?}")"

if [[ -n "${dnf_o}" ]] && [[ -n "${awk_o}" ]]; then 
  mapfile -t pids_nr <<<"${awk_o:?}"

  if [[ "${#pids_nr[@]}" -gt 1 ]]; then
    printf '\n\t PID-s, count: %d\n\n' "${#pids_nr[@]}"
    sleep 1
    printf '\t Backgrounding and disowning -kill- loops.\n\n'
    sleep 3
    {
      for s in HUP USR1 TERM; do

        for p in "${!pids_nr[@]}"; do
          q="${pids_nr[p]}"
          sleep 1
          printf '\t[script:] + sudo kill -s %s %d\n' "${s}" "${q}"
          if sudo kill -s "${s}" "${q}" > /dev/null 2>&1; then
            printf '\t[script:] + kill succeeded; forgetting PID\n' 
            unset 'pids_nr[p]'
          else
            printf '\t[script:] + kill failed\n' 
          fi
        done;
      done;
      printf '\n\n\tScript complete. [Press ENTER.]\n\n'
    } &
    disown
  elif [[ "${pids_nr[*]}" -eq 1 ]]; then 
    printf '\n\t The remaining "needs-restarting" process cannot be '
    printf 'restarted \n\t without rebooting the machine.\n'
    printf '\n\t %s \n\n' "${dnf_o}"
    printf '\n\n\tScript complete.\n\n'
  fi
fi;

