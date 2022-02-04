#!/usr/bin/env bash
alias gcb='g clean build'
alias g_clean_assemble='g clean assemble'
alias g_clean_build='g clean build'
alias g_comp_cache='__gradle-completion-init'

function g_tasks() {
  g -q tasks --all "$@"
}

function g_tasktree() {
  if test -z "${1-}"; then
    echo "You must pass a task to this command"
    return 1
  fi
  g -q taskTree "$@"
}

function g_help_task() {
  if test -z "${1-}"; then
    echo "You must pass a task to this command"
    return 1
  fi
  g -q help --task "$@"
}

function g_deps_updates() {
  g -q dependencyUpdates "$@"
}

function g_deps_build_src() {
  local out_dir="build/reports"
  local out_file="${out_dir}/deps.buildSrc.txt"
  if ! test -d "$out_dir"; then
    mkdir -p "$out_dir"
  fi

  local g_args=(-q)

  if test "$(basename "$(pwd)")" != "buildSrc"; then
    g_args+=(-p buildSrc)
  fi

  g "${g_args[@]}" dependencies "$@" | tee "${out_file}"
}

function g_projects_names() {
  g -q projects | pcregrep -o1 "Project ':(.*?)'"
}

function g_props() {
  g -q properties "$@"
}
