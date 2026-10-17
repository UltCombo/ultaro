#!/bin/bash

# Prints, one per line, every installed package matching the arguments.
# Each argument may be a package name or a package group (e.g. gnome).
get_installed() {
  local item
  for item in "$@"; do
    pacman -Qq  -- "$item" 2>/dev/null   # installed package with this name
    pacman -Qgq -- "$item" 2>/dev/null   # installed members of a group with this name
  done | sort -u
}

# Drops anything listed in $KEEP_PACKAGES (space-separated) from stdin.
filter_keep() {
  if [ -n "${KEEP_PACKAGES:-}" ]; then
    grep -vxF -f <(printf '%s\n' $KEEP_PACKAGES)
  else
    cat
  fi
}

remove_packages() {
  local installed
  mapfile -t installed < <(get_installed "$@" | filter_keep)

  if [ "${#installed[@]}" -gt 0 ]; then
    if [ -n "${DRY_RUN:-}" ]; then
      pacman -Rs --print "${installed[@]}"
    else
      sudo pacman -Rns --noconfirm "${installed[@]}"
    fi
  fi
}
