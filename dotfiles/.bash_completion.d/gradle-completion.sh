#!/usr/bin/env bash
# shellcheck disable=all
S="${BASH_SOURCE[0]}" && while [ -h "$S" ]; do D="$(cd -P "$(dirname "$S")" && pwd)" && S="$(readlink "$S")" && [[ $S != /* ]] && S="$D/$S"; done || true && _SCRIPT_DIR="$(cd -P "$(dirname "$S")" && pwd)" && unset S D
GRADLE_FUNCTIONS_FILE="${_SCRIPT_DIR}/../.dotfiles/gradle_functions.sh"

if ! command -v _default_completion >/dev/null 2>&1; then
  alias _default_completion='complete -o bashdefault -o default'
fi

function _gradle_allopt() {
  _gradle "$@"
  if command -v _allopt >/dev/null 2>&1; then
    _allopt "$@"
  else
    return 0
  fi
}

_GRADLE_FUNCS=(
  g
)

if test -n "${_CUSTOM_GRADLE_FUNDS-}"; then
  _GRADLE_FUNCS+=("${_CUSTOM_GRADLE_FUNDS[@]}")
fi

mapfile -t -O "${#_GRADLE_FUNCS[@]}" _GRADLE_FUNCS < <(git -C "${_SCRIPT_DIR}/../bin" ls-files -- ':(glob)**/g_*')
mapfile -t _GRADLE_ALLOPT_SCRIPTS < <(git --no-pager -C "${_SCRIPT_DIR}/../bin" grep --color=never --name-only '(function _usage|^\.g_simple_task)' -- ':(glob)**/g_*' | xargs basename)

if test -e "$GRADLE_FUNCTIONS_FILE" && command -v pcregrep >/dev/null 2>&1; then
  mapfile -t _PARSED_GRADLE_FUNCS < <(pcregrep -o2 -o3 '^(function\s+(.*?)[\s\(\{]|([a-zA-Z0-9_]+)\s*\(\s*\)\s*(\{|$))' "$GRADLE_FUNCTIONS_FILE")
  _GRADLE_FUNCS+=("${_PARSED_GRADLE_FUNCS[@]}")
fi

_default_completion -F _gradle "${_GRADLE_FUNCS[@]}"
if test "${#_GRADLE_ALLOPT_SCRIPTS[@]}" -ne 0; then
  _default_completion -F _gradle_allopt "${_GRADLE_ALLOPT_SCRIPTS[@]}"
fi

unset _GRADLE_FUNCS _CUSTOM_GRADLE_FUNDS _PARSED_GRADLE_FUNCS _GRADLE_ALLOPT_SCRIPTS _SCRIPT_DIR GRADLE_FUNCTIONS_FILE

##################################################################################################################################################
################################################################### gradle-completion fixes ######################################################
##################################################################################################################################################
export GRADLE_COMPLETION_UNQUALIFIED_TASKS=true
# NB: modified from https://github.com/gradle/gradle-completion

__gradle-set-build-file() {
  __gradle-set-settings-file
  # In order of precedence: --build-file=filename, rootProject.buildFileName, build.gradle, build.gradle.kts

  local default_gradle_build_file_name="build.gradle"
  if [[ -f $gradle_settings_file ]]; then
    local build_file_name=$(grep "^rootProject\.buildFileName" $gradle_settings_file |
      sed -n -e "s/rootProject\.buildFileName = [\'\"]\(.*\)[\'\"]/\1/p")
    default_gradle_build_file_name="${build_file_name:-build.gradle}"
  fi

  gradle_build_file="$project_root_dir/$default_gradle_build_file_name"
  if [[ ! -f $gradle_build_file ]]; then
    gradle_build_file="$project_root_dir/build.gradle.kts"
  fi
  if ! test -f "${gradle_build_file}" && test -f "${gradle_settings_file}"; then
    gradle_build_file="${gradle_settings_file}"
  fi
  return 0
}

__gradle-generate-tasks-cache() {
  __gradle-set-files-checksum

  # Use Gradle wrapper when it exists.
  local gradle_cmd="gradle"
  if [[ -x "$project_root_dir/gradlew" ]]; then
    gradle_cmd="$project_root_dir/gradlew"
  fi

  # Run gradle to retrieve possible tasks and cache.
  # Reuse Gradle Daemon if IDLE but don't start a new one.
  local gradle_tasks_output
  if [[ -n "$("$gradle_cmd" --status 2>/dev/null | grep IDLE)" ]]; then
    gradle_tasks_output="$("$gradle_cmd" --console=plain --daemon -q tasks --all)"
  else
    gradle_tasks_output="$("$gradle_cmd" --console=plain --no-daemon -q tasks --all)"
  fi
  local output_line
  local task_description
  local -a gradle_all_tasks=()
  local -a root_tasks=()
  local -a subproject_tasks=()
  for output_line in ${gradle_tasks_output}; do
    if [[ $output_line =~ ^([[:lower:]][[:alnum:][:punct:]]*)([[:space:]]-[[:space:]]([[:print:]]*))? ]]; then
      task_name="${BASH_REMATCH[1]}"
      task_description="${BASH_REMATCH[3]}"
      gradle_all_tasks+=("$task_name  - $task_description")
      # Completion for subproject tasks with ':' prefix
      if [[ $task_name =~ ^([[:alnum:][:punct:]]+):([[:alnum:]]+) ]]; then
        gradle_all_tasks+=(":$task_name  - $task_description")
        subproject_tasks+=("${BASH_REMATCH[2]}")
      else
        root_tasks+=("$task_name")
      fi
    fi
  done

  # subproject tasks can be referenced implicitly from root project
  if [[ $GRADLE_COMPLETION_UNQUALIFIED_TASKS == "true" ]]; then
    local -a implicit_tasks=()
    implicit_tasks=($(comm -23 <(printf "%s\n" "${subproject_tasks[@]}" | sort) <(printf "%s\n" "${root_tasks[@]}" | sort)))
    for task in $(printf "%s\n" "${implicit_tasks[@]}"); do
      gradle_all_tasks+=("$task")
    done
  fi

  printf "%s\n" "${gradle_all_tasks[@]}" >|"$cache_dir/$gradle_files_checksum"
  echo "$gradle_files_checksum" >|"$cache_dir/$cache_name.md5"
}
