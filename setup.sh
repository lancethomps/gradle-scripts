#!/usr/bin/env bash
################################################################### SETUP ########################################################################
S="${BASH_SOURCE[0]}" && while [ -h "$S" ]; do D="$(cd -P "$(dirname "$S")" && pwd)" && S="$(readlink "$S")" && [[ $S != /* ]] && S="$D/$S"; done || true && _SCRIPT_DIR="$(cd -P "$(dirname "$S")" && pwd)" && unset S D
# shellcheck source=./dotfiles/bin/.common_copy.sh
source "${_SCRIPT_DIR}/dotfiles/bin/.common_copy.sh" || exit 1
##################################################################################################################################################

function install_brew() {
  local BREW_FORMULAS=(
    coreutils
    fzf
    gawk
    gnu-sed
    gradle-completion
    pcre
    realpath
  )

  if ! command -v jq >/dev/null 2>&1; then
    BREW_FORMULAS+=(jq)
  fi

  echo "Installing required Homebrew formulas..."
  log_and_run brew install "${BREW_FORMULAS[@]}"
}

function finish_setup() {
  echo "To finish setup, add the dotfiles/bin directory to your PATH. You will most likely want to put that in your .bash_profile."
  echo "export PATH=\"\${PATH}:${_SCRIPT_DIR}/dotfiles/bin\""
}

function main() {
  install_brew
  finish_setup
}

main "$@"
