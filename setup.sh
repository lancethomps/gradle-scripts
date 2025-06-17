#!/usr/bin/env bash
################################################################### SETUP ########################################################################
S="${BASH_SOURCE[0]}" && while [ -h "$S" ]; do D="$(cd -P "$(dirname "$S")" && pwd)" && S="$(readlink "$S")" && [[ $S != /* ]] && S="$D/$S"; done || true && _SCRIPT_DIR="$(cd -P "$(dirname "$S")" && pwd)" && unset S D
export _SCRIPT_DIR
# shellcheck source=./dotfiles/bin/.common_copy.sh
source "${_SCRIPT_DIR}/dotfiles/bin/.common_copy.sh" || exit 1
##################################################################################################################################################

REQUIRES_SCRIPTS_FILE="${_SCRIPT_DIR}/requires.txt"
REQUIRES_PIP_FILE="${_SCRIPT_DIR}/requires-pip.txt"
REQUIRES_PIP_EDITABLE_FILE="${_SCRIPT_DIR}/requires-pip-editable.txt"

function install_brew() {
  echo "Installing required Homebrew formulas from Brewfile..."
  log_and_run_if_not_debug brew bundle install --file="${_SCRIPT_DIR}/Brewfile"
}

function install_pip() {
  local required_scripts requires_file="$1"
  shift

  if ! test -e "${requires_file}"; then
    return 0
  fi

  mapfile -t required_scripts < <(envsubst <"${requires_file}")
  log_and_run_if_not_debug pip install "$@" "${required_scripts[@]}"
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
  install_pip "$REQUIRES_PIP_FILE"
  install_pip "$REQUIRES_PIP_EDITABLE_FILE" --editable
  finish_setup
  recommend_other_scripts
}

main "$@"
