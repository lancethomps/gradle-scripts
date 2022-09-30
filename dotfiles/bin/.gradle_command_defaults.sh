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

##################################################################################################################################################
################################################################### COMMON COPY ##################################################################
##################################################################################################################################################

function is_arg_present() {
  local expected_arg arg

  expected_arg="$1"
  shift

  for arg in "$@"; do
    if test "${arg}" = "${expected_arg}"; then
      return 0
    fi
  done

  return 1
}
function repeat_char() {
  head -c "$2" </dev/zero | tr '\0' "$1"
}
function get_sep_cols() {
  local sep_cols=160 term_cols
  if command -v get_terminal_columns >/dev/null 2>&1; then
    term_cols="$(get_terminal_columns)"
    if test -n "$term_cols"; then
      sep_cols="$term_cols"
    fi
  fi
  if test -n "${1-}"; then
    sep_cols="$((sep_cols / $1))"
  fi
  echo -n "$sep_cols"
}
# shellcheck disable=SC2120
function log_sep() {
  if test -n "${1-}"; then
    repeat_char "${1}" "$(get_sep_cols 2)"
    echo
    return 0
  fi

  if test -z "${TERMINAL_SEP-}"; then
    local rep_count
    rep_count="$(get_sep_cols 2)"
    TERMINAL_SEP="$(repeat_char '-' "$rep_count")"
    export TERMINAL_SEP
  fi
  echo "$TERMINAL_SEP"
}
function log_with_title_sep() {
  echo
  log_with_title_sep_no_leading_blank_line "$@"
}
function log_with_title_sep_no_leading_blank_line() {
  echo "$@"
  log_sep
}
function log_and_run() {
  log_with_title_sep_no_leading_blank_line "$*" >&2
  "$@"
}
function log_and_run_spaced() {
  log_with_title_sep "$*" >&2
  "$@"
}
function join_by() {
  local delim="${1//\&/\\&}"
  shift

  echo -n "$1"
  shift
  printf "%s" "${@/#/$delim}"
}
function join_by_newline() {
  join_by $'\n' "$@"
}
function join_by_newline_with_end() {
  join_by_newline "$@"
  echo
}
function join_by_regex_or() {
  echo "($(join_by '|' "$@"))"
}
function exit_fatal() {
  local exit_code="${1-}"
  if test "$#" -le 1; then
    exit_code=1
  else
    shift
  fi
  echo "FATAL $*"
  exit "$exit_code"
}
function return_fatal() {
  local exit_code="${1-}"
  if test "$#" -le 1; then
    exit_code=1
  else
    shift
  fi
  echo "FATAL $*"
  return "$exit_code"
}
function exit_fatal_with_usage() {
  if command -v _usage >/dev/null 2>&1; then
    _usage
  fi
  exit_fatal "$@"
}
function check_true() {
  if test -z "${1-}"; then
    return 1
  fi
  local val="${1,,}"
  test "${val}" = "true" && return 0 || test "${val}" = "1" && return 0 || test "${val}" = "yes" && return 0 || test "${val}" = "y" && return 0 || return 1
}
