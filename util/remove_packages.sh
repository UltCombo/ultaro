#!/bin/bash

get_installed() {
  installed=""

  for package in "$@"; do
    pacman -Qi "$package" &> /dev/null && installed="$installed $package"
  done

  echo "$installed"
}

remove_packages() {
  installed="$(get_installed "$@")"
  [ -n "$installed" ] && sudo pacman -Rns --noconfirm $installed
}
