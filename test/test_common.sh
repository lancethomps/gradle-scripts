#!/usr/bin/env bash
################################################################### SETUP ########################################################################
S="${BASH_SOURCE[0]}" && while [ -h "$S" ]; do D="$(cd -P "$(dirname "$S")" && pwd)" && S="$(readlink "$S")" && [[ $S != /* ]] && S="$D/$S"; done || true && _SCRIPT_DIR="$(cd -P "$(dirname "$S")" && pwd)" && unset S D
export PATH="${_SCRIPT_DIR}/../dotfiles/bin:${PATH}"
# shellcheck disable=SC1090
source "${_SCRIPT_DIR}/../dotfiles/bin/.common_copy.sh"
##################################################################################################################################################

function test_failed() {
  export exit_val=1
  local test_name="$1"
  shift
  log_with_title_sep "FAILED $test_name"
  echo "$*"
}

function test_passed() {
  echo "PASSED $*"
}

function get_test_resource_file_contents() {
  local file_path
  file_path="${_SCRIPT_DIR}/resources/$1"
  if ! test -e "$file_path"; then
    return_fatal "test resources file does not exist: $file_path"
  fi
  cat "$file_path"
}

function assert_equal() {
  local expected="$1" actual="$2"
  shift 2

  if test "$expected" != "$actual"; then
    test_failed "$@" "expected=${expected}" "actual=${actual}"
  else
    test_passed "$@"
  fi
}
