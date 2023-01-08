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

if test -n "${_CUSTOM_GRADLE_FUNCS-}"; then
  _GRADLE_FUNCS+=("${_CUSTOM_GRADLE_FUNCS[@]}")
fi

mapfile -t -O "${#_GRADLE_FUNCS[@]}" _GRADLE_FUNCS < <(git -C "${_SCRIPT_DIR}/../bin" ls-files -- ':(glob)**/g_*')

if test -e "$GRADLE_FUNCTIONS_FILE" && command -v pcregrep >/dev/null 2>&1; then
  mapfile -t _PARSED_GRADLE_FUNCS < <(pcregrep -o2 -o3 '^(function\s+(.*?)[\s\(\{]|([a-zA-Z0-9_]+)\s*\(\s*\)\s*(\{|$))' "$GRADLE_FUNCTIONS_FILE")
  _GRADLE_FUNCS+=("${_PARSED_GRADLE_FUNCS[@]}")
fi

mapfile -t _GRADLE_ALLOPT_SCRIPTS < <(git --no-pager -C "${_SCRIPT_DIR}/../bin" grep --color=never --name-only '(function _usage|^\.g_simple_task)' -- ':(glob)**/g_*' | xargs basename)

if test -n "${_CUSTOM_GRADLE_ALLOPT_SCRIPTS-}"; then
  _GRADLE_ALLOPT_SCRIPTS+=("${_CUSTOM_GRADLE_ALLOPT_SCRIPTS[@]}")
fi

_default_completion -F _gradle "${_GRADLE_FUNCS[@]}"
if test "${#_GRADLE_ALLOPT_SCRIPTS[@]}" -ne 0; then
  _default_completion -F _gradle_allopt "${_GRADLE_ALLOPT_SCRIPTS[@]}"
fi

unset _GRADLE_FUNCS _CUSTOM_GRADLE_FUNCS _PARSED_GRADLE_FUNCS _GRADLE_ALLOPT_SCRIPTS _SCRIPT_DIR GRADLE_FUNCTIONS_FILE

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
    gradle_tasks_output="$("$gradle_cmd" -b "$gradle_build_file" --console=plain --daemon -q tasks --all)"
  else
    gradle_tasks_output="$("$gradle_cmd" -b "$gradle_build_file" --console=plain --no-daemon -q tasks --all)"
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

__gradle-long-options() {
  local cur
  _get_comp_words_by_ref -n : cur

  local args="--build-cache           - Enables the Gradle build cache
--build-file            - Specifies the build file
--configuration-cache   - Enables the configuration cache. Gradle will try to reuse the build configuration from previous builds. [incubating]
--configuration-cache-problems - Configures how the configuration cache handles problems (fail or warn). Defaults to fail. [incubating]
--configure-on-demand   - Only relevant projects are configured
--console               - Type of console output to generate (plain auto rich verbose)
--continue              - Continues task execution after a task failure
--continuous            - Continuous mode. Automatically re-run build after changes
--daemon                - Use the Gradle Daemon
--debug                 - Log at the debug level
--dry-run               - Runs the build with all task actions disabled
--exclude-task          - Specify a task to be excluded
--full-stacktrace       - Print out the full (very verbose) stacktrace
--gradle-user-home      - Specifies the Gradle user home directory
--gui                   - Launches the Gradle GUI app (Deprecated)
--help                  - Shows a help message
--include-build         - Run the build as a composite, including the specified build
--info                  - Set log level to INFO
--init-script           - Specifies an initialization script
--max-workers           - Set the maximum number of workers that Gradle may use
--no-build-cache        - Do not use the Gradle build cache
--no-configuration-cache  - Disables the configuration cache. [incubating]
--no-configure-on-demand  - Disables configuration on demand
--no-daemon             - Do not use the Gradle Daemon
--no-parallel           - Disables parallel execution to build projects
--no-rebuild            - Do not rebuild project dependencies
--no-scan               - Do not create a build scan
--no-search-upwards     - Do not search parent directories for a settings.gradle (removed)
--no-watch-fs           - Do not watch the filesystem for changes
--offline               - Build without accessing network resources
--parallel              - Build projects in parallel
--profile               - Profile build time and create report
--priority              - Set priority for Gradle worker processes (low normal)
--project-cache-dir     - Specifies the project-specific cache directory
--project-dir           - Specifies the start directory for Gradle
--project-prop          - Sets a project property of the root project
--quiet                 - Log errors only
--recompile-scripts     - Forces scripts to be recompiled, bypassing caching
--refresh-dependencies  - Refresh the state of dependencies
--rerun                 - Rerun the specific tasks specified
--rerun-tasks           - Specifies that any task optimization is ignored
--scan                  - Create a build scan
--settings-file         - Specifies the settings file
--stacktrace            - Print out the stacktrace also for user exceptions
--status                - Print Gradle Daemon status
--stop                  - Stop all Gradle Daemons
--system-prop           - Set a system property
--update-locks          - Perform a partial update of the dependency lock
--version               - Prints Gradle version info
--warn                  - Log warnings and errors only
--warning-mode          - Set types of warnings to log (all summary none)
--watch-fs              - Gradle watches filesystem for incremental builds
--write-locks           - Persists dependency resolution for locked configurations
--fail-fast             - CUSTOM Stop tests after first failure
--tests                 - CUSTOM define tests
--depth                 - CUSTOM option for taskTree
--repeat                - CUSTOM option for taskTree
--with-inputs           - CUSTOM option for taskTree
--with-outputs          - CUSTOM option for taskTree
"

  COMPREPLY=($(compgen -W "$args" -- "$cur"))
}

__gradle-short-options() {
  local cur
  _get_comp_words_by_ref -n : cur

  local args="-?                      - Shows a help message
-a                      - Do not rebuild project dependencies
-b                      - Specifies the build file
-c                      - Specifies the settings file
-d                      - Log at the debug level
-g                      - Specifies the Gradle user home directory
-h                      - Shows a help message
-i                      - Set log level to INFO
-m                      - Runs the build with all task actions disabled
-p                      - Specifies the start directory for Gradle
-q                      - Log errors only
-s                      - Print out the stacktrace also for user exceptions
-t                      - Continuous mode. Automatically re-run build after changes
-u                      - Do not search parent directories for a settings.gradle
-v                      - Prints Gradle version info
-w                      - Log warnings and errors only
-x                      - Specify a task to be excluded
-D                      - Set a system property
-I                      - Specifies an initialization script
-P                      - Sets a project property of the root project
-S                      - Print out the full (very verbose) stacktrace
-Prerun"
  COMPREPLY=($(compgen -W "$args" -- "$cur"))
}
