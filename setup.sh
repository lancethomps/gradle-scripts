#!/usr/bin/env bash
################################################################### SETUP ########################################################################
S="${BASH_SOURCE[0]}" && while [ -h "$S" ]; do D="$(cd -P "$(dirname "$S")" && pwd)" && S="$(readlink "$S")" && [[ $S != /* ]] && S="$D/$S"; done || true && _SCRIPT_DIR="$(cd -P "$(dirname "$S")" && pwd)" && unset S D
# shellcheck source=./dotfiles/bin/.common_copy.sh
source "${_SCRIPT_DIR}/dotfiles/bin/.common_copy.sh" || exit 1
##################################################################################################################################################

REQUIRES_SCRIPTS_FILE="${_SCRIPT_DIR}/requires.txt"

function install_brew() {
  echo "Installing required Homebrew formulas from Brewfile..."
  log_and_run brew bundle install --file="${_SCRIPT_DIR}/Brewfile"
}

function install_pip() {
  log_and_run pip install ltpylib
}

function finish_setup() {
  echo "To finish setup, add the dotfiles/bin directory to your PATH. You will most likely want to put that in your .bash_profile."
  echo "export PATH=\"\${PATH}:${_SCRIPT_DIR}/dotfiles/bin\""
}

function recommend_other_scripts() {
  local required_scripts required_script

  if ! test -e "${REQUIRES_SCRIPTS_FILE}"; then
    return 0
  fi

  mapfile -t required_scripts <"$REQUIRES_SCRIPTS_FILE"
  for required_script in "${required_scripts[@]}"; do
    if ! test -e "${_SCRIPT_DIR}/../${required_script}"; then
      echo "It is highly recommended to also setup https://github.com/lancethomps/${required_script}."
    fi
  done

  return 0
}

function main() {
  install_brew
  install_pip
  finish_setup
  recommend_other_scripts
}

main "$@"
