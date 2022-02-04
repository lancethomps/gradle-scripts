#!/usr/bin/env bash
################################################################### SETUP ########################################################################
S="${BASH_SOURCE[0]}" && while [ -h "$S" ]; do D="$(cd -P "$(dirname "$S")" && pwd)" && S="$(readlink "$S")" && [[ $S != /* ]] && S="$D/$S"; done || true && _SCRIPT_DIR="$(cd -P "$(dirname "$S")" && pwd)" && unset S D
##################################################################################################################################################

BREW_FORMULAS=(
  coreutils
  fzf
  gawk
  gnu-sed
  gradle-completion
  pcre
)

if ! command -v jq >/dev/null 2>&1; then
  BREW_FORMULAS+=(jq)
fi

echo "Installing required Homebrew formulas: ${BREW_FORMULAS[*]}"
brew install "${BREW_FORMULAS[@]}"

echo "To finish setup, add the dotfiles/bin directory to your PATH. You will most likely want to put that in your .bash_profile."
echo "export PATH=\"\${PATH}:${_SCRIPT_DIR}/dotfiles/bin\""
