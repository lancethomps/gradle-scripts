#!/usr/bin/env bash
################################################################### SETUP ########################################################################
shopt -s expand_aliases
set -o errexit -o errtrace -o nounset
##################################################################################################################################################

function git_base_dir() {
  if command -v git-base-dir >/dev/null 2>&1; then
    git base-dir
  else
    git rev-parse --show-toplevel
  fi
}

function cd_to_git_base_dir_if_needed() {
  if test "${cd_to_git_base_dir-}" = "true"; then
    cd "$(git_base_dir)"
  fi

  return 0
}
