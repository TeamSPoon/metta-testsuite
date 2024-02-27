#!/bin/bash


DEBUG_WHY() {
   DEBUG "${GREEN}WHY: ${BOLD}${*}${NC}"
}


process_file() {
    #local file=$(find_override_file "$1")
    local file="$1"

    local absfile=$(readlink -f "$file")

    local extra_args="${@:2}"
    shift

    export file_html="${METTALOG_OUTPUT}/${file}.html"

    export HTML_OUT="${file}.html"

    DEBUG "==========================================================================="
    DEBUG "${BLUE}${BOLD}===========================================================================${NC}"
    DEBUG "${BOLD}"
    DEBUG ""
    DEBUG "Testing: $file"
    cd "$METTALOG_DIR"
    DEBUG "Output: $file_html"
    DEBUG ""
    DEBUG ""
    DEBUG "${BLUE}${BOLD}===========================================================================${NC}"
    DEBUG "==========================================================================="

    # Add unique absolute paths to PYTHONPATH
    pp1=$(realpath "$(dirname "${file}")")
    pp2=$(realpath "$(dirname "${pp1}")")
    for pp in $pp1 $pp2; do
        if [[ ":$PYTHONPATH:" != *":$pp:"* ]]; then
            export PYTHONPATH="${PYTHONPATH:+"$PYTHONPATH:"}$pp"
        fi
    done

    # Set OPENAI_API_KEY only if it's not already set
    if [ -z "$OPENAI_API_KEY" ]; then
        export OPENAI_API_KEY=freeve
    fi

    local take_test=0

    # Combined condition check
    if [[ "$fresh" -eq 1 ]] || [ ! -f "${file}.answers" ] || ([ "${file}" -nt "${file}.answers" ] && [ -s "${file}.answers" ]); then
        DEBUG_WHY "${YELLOW}Regenerating answers: $file.answers${NC}"
        IF_REALLY_DO cat /dev/null > "${file}.answers"
        IF_REALLY_DO rm -f "${file}.answers"

        set +e

        # Function to handle SIGINT
        handle_sigint() {
            do_DEBUG "${RED}SIGINT received, stopping metta but continuing script...${NC}"
            stty sane
        }

        # Trap SIGINT
        trap 'handle_sigint' SIGINT

        (cd "$(dirname "${file}")" || true

            set +x
            IF_REALLY_DO "timeout --foreground --kill-after=5 --signal=SIGINT $(($RUST_METTA_MAX_TIME + 1)) time metta '$absfile' 2>&1 | tee '${absfile}.answers'"
            TEST_EXIT_CODE=$?
            take_test=1
            #set +x
            if [ $TEST_EXIT_CODE -eq 124 ]; then
                DEBUG "${RED}Rust MeTTa Killed (definitely due to timeout) after $RUST_METTA_MAX_TIME seconds: ${TEST_CMD}${NC}"
                [ "$if_failures" -eq 1 ] && rm -f "$file_html"
            elif [ $TEST_EXIT_CODE -ne 0 ]; then
                DEBUG "${RED}Rust MeTTa Completed with error (EXITCODE=$TEST_EXIT_CODE) under $RUST_METTA_MAX_TIME seconds${NC}"
            else
                DEBUG "${GREEN}Rust MeTTa Completed successfully (EXITCODE=0) under $RUST_METTA_MAX_TIME seconds${NC}!"		
            fi	    

        ) || true
        stty sane
	DEBUG ""
        trap - SIGINT

        set -e

    else
        DEBUG "Comparing: $file.answers"
    fi

    if [ "$if_regressions" -eq 1 ]; then
        if [[ ! -f "$file_html" ]]; then
            DEBUG_WHY "Not taking test since HTML file does not exist."
            return
        fi

        failures_zero=$(grep -h -c "Failures: 0" "$file_html")
        if [ "$failures_zero" -eq 0 ]; then
            DEBUG_WHY "Not taking test since Failures not 0."
            return
        fi
        take_test=1
        DEBUG_WHY "Taking test since Failures: 0 and looking for regressions."
    elif [[ ! -f "$file_html" ]]; then
        take_test=1
        DEBUG_WHY "Taking test since HTML file does not exist."
    else
        if [ "$clean" -eq 1 ]; then
            take_test=1
            DEBUG_WHY "Taking test since --clean."
        elif [ "$if_failures" -eq 1 ]; then
            failures_not_zero=$(grep -h -c "Failures: [^0]" "$file_html")
            if [ "$failures_not_zero" -eq 0 ]; then
                success_missing=0

                if ! grep -q "Successes: " "$file_html"; then
                    success_missing=1
                fi

                if [ "$success_missing" -eq 1 ]; then
                    DEBUG_WHY "Retaking Test since the word 'Success' is missing from $file_html."
                    take_test=1
                else
                    DEBUG_WHY "The word 'Success' is present in $file_html."
                fi
            fi
            if [ "$failures_not_zero" -gt 0 ]; then
                take_test=1
                DEBUG_WHY "Retaking test since failures are present."
                IF_REALLY_DO rm -f "$file_html"
            else
                if [ "$take_test" -eq 0 ]; then
                    DEBUG_WHY "Not retaking since Failures: 0."
                fi
            fi
        else
            DEBUG_WHY "Results present, not taking test."
        fi
    fi

    set +e

    if [ "$take_test" -eq 1 ]; then
        sleep 0.1
        IF_REALLY_DO touch "$file_html"

        TEST_CMD="./MeTTa '--output=$METTALOG_OUTPUT' --timeout=$METTALOG_MAX_TIME --html --repl=false ${extra_args[@]} ${passed_along_to_mettalog[@]} \"$file\" --halt=true"
        do_DEBUG "${BOLD}$TEST_CMD${NC}"

     
        #IF_REALLY_DO 
	IF_REALLY_DO "time $TEST_CMD"
        TEST_EXIT_CODE=$?
        # set -e
        if [ $TEST_EXIT_CODE -eq 124 ]; then
            DEBUG "${RED}Killed (definitely due to timeout) after $METTALOG_MAX_TIME seconds: ${TEST_CMD}${NC}"
            IF_REALLY_DO [ "$if_failures" -eq 1 ] && rm -f "$file_html"
        elif [ $TEST_EXIT_CODE -ne 7 ]; then
            DEBUG "${YELLOW}Completed (EXITCODE=$TEST_EXIT_CODE) under $METTALOG_MAX_TIME seconds: ${TEST_CMD}${NC}"
        else
            DEBUG "${GREEN}Completed successfully (EXITCODE=0) under $METTALOG_MAX_TIME seconds: ${TEST_CMD}${NC}"
        fi
        #set -e
    fi
}

# This script performs various testing operations for MeTTaLog.
# It handles command-line arguments to customize its behavior.

# Check if the script is being sourced or run directly
IS_SOURCED=$( [[ "${BASH_SOURCE[0]}" != "${0}" ]] && echo 1 || echo 0)
# Save the directory one level above where this script resides
METTALOG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

passed_along_to_mettalog=()
METTALOG_MAX_TIME=75

SCRIPT_NAME=$(basename "$0")
run_tests_auto_reply=""
generate_report_auto_reply=""
METTALOG_OUTPUT="tests_output/testrun_$(date +%Y%m%d_%H%M%S)"
fresh=0
clean=0  # 0 means don't clean, 1 means do clean
if_failures=0
if_regressions=0
show_help=0
RUST_METTA_MAX_TIME=60
EXTRA_FIND_ARGS=" ! -path '*/.*' ! -path '*~*' "
EXTRA_GREP_ARGS=""
dry_run=0
debug_this_script=true


# Filters to exclude names starting with a dot, containing a tilde,
# starting with an underscore, and for files, excluding those not ending with 'metta'
DIR_FILTER=("^\." ".*~.*" "^_")
FILE_FILTER=("^\." ".*~.*" "^_" "!.*\.metta$")

# ANSI escape codes for colors
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
# ANSI escape code to reset color
NC='\033[0m' # No Color

do_DEBUG() {
    # Calculate the screen width and 74% of it
    local screen_width=$(tput cols)
    local threshold=$((screen_width * 95 / 100))

    # Construct the debug message
    local msg="; ${YELLOW}$SCRIPT_NAME${NC} $*"

    # Calculate the length of the debug message
    local msg_length=${#msg}

    if [ "$msg_length" -gt "$threshold" ]; then
      # If the message is longer than 74% of the screen width,
      # print a newline before and after the message
      echo >&2
      echo -e "$msg" >&2
      echo >&2
    else
      # If the message is not longer than 74% of the screen width, print it as usual
      echo -e "$msg" >&2
    fi
}

DEBUG() {
  if [ "$debug_this_script" == "true" ]; then
     do_DEBUG "$@"
  else 
     if [ "$dry_run" -eq 1 ]; then
        do_DEBUG "$@"
     fi
  fi
}

IF_REALLY_DO() {
    if [ "$dry_run" -eq 1 ]; then
        do_DEBUG "${BOLD}Dry Run:${NC} $*"
    else
        DEBUG "${GREEN}Doing:${NC} $*"
        eval "$@" 
	return $?
    fi
}

# Function to check if a file is in an array
file_in_array() {
    local file="$1"
    shift
    local arr=("$@")
    for elem in "${arr[@]}"; do
        [[ "$elem" == "$file" ]] && return 0
    done
    return 1
}
# Function to add an item to a list if it's not already present
add_to_list() {
    local item="$1"
    local -n list_ref="$2"
    if [[ ! " ${list_ref[*]} " =~ " $item " ]]; then
        list_ref+=("$item")
    fi
}

# Initialize arrays to hold the files to be tested, excluded, and containing '!'
declare -a files_to_test
declare -a excluded_files
declare -a excluded_dirs
declare -a files_with_exclamation

# Function to check if the filename matches the filter
matches_filter() {
    local filename="$(basename "$1")"
    local -n filter=$2
    for pattern in "${filter[@]}"; do
        if [[ "$pattern" == "!"* ]]; then
            pattern="${pattern#!}"  # Remove the '!' from the start
            if [[ "$filename" =~ $pattern ]]; then
                return 1  # File should be excluded
            fi
        else
            if [[ "$filename" =~ $pattern ]]; then
                return 0  # File matches the filter
            fi
        fi
    done
    return 1  # File does not match the filter
}

# More script functionality...

# Note: Instead of 'exporting' variables, just set them. Only export if necessary for subprocesses.

# Main function to handle files and directories based on patterns
find_test_masks() {
    shopt -s globstar nullglob  # Enable recursive glob patterns
    for pattern_or_path in "$@"; do  # Iterate over all arguments
        for file in $pattern_or_path; do
            if [ -f "$file" ]; then
                if matches_filter "$file" FILE_FILTER; then
                    excluded_files+=("$file")
                else
                    files_to_test+=("$file")
                    # Check if file contains lines starting with "!"
                    if grep -q '^!' "$file"; then
                        files_with_exclamation+=("$file")
                    fi
                fi
            elif [ -d "$file" ]; then
                if matches_filter "$(basename "$file")" DIR_FILTER; then
                    excluded_dirs+=("$file")
                else
                    DEBUG "Directory: $file"
		    while IFS= read -r -d $'\0' subfile; do
                        if [ -f "$subfile" ] && matches_filter "$(basename "$subfile")" FILE_FILTER; then
                            excluded_files+=("$subfile")
                        else
                            files_to_test+=("$subfile")
                            # Check if file contains lines starting with "!"
                            if grep -q '^!' "$subfile"; then
                                files_with_exclamation+=("$subfile")
                            fi
                        fi
                    done < <(find "$file" -type f -print0)		    
                fi
            fi
        done
    done
    shopt -u globstar nullglob  # Disable recursive glob patterns after use
}


# Function to run tests
function add_test_units_dir() {
    # Process test files
    local BASE_DIR="${1}"
    DEBUG "Running tests in $BASE_DIR"

      set +v
         DEBUG "Finding files with 'test' in their name and apply $EXTRA_FIND_ARGS ..."
         mapfile -t test_files < <(find "${BASE_DIR}" $EXTRA_FIND_ARGS -type f -iname "*test*.metta")
         DEBUG "'Test' files found: ${#test_files[@]}"

         DEBUG "Finding files containing 'assert' keyword and apply $MUST_HAVE ..."
         mapfile -t assert_files < <(find "${BASE_DIR}" $EXTRA_FIND_ARGS -type f -name '*.metta' -print0 | xargs -0 grep -rl 'assert' -- $GREP_ARGS)
         DEBUG "Assert<*> files found: ${#assert_files[@]} "

         DEBUG "Finding files containing execution directive (lines starting with '!') and apply $MUST_HAVE ..."
         mapfile -t has_tests < <(find "${BASE_DIR}" $EXTRA_FIND_ARGS -type f -name '*.metta' -print0 | xargs -0 grep -rl '^!\([^!]*\)$' -- $GREP_ARGS)
        DEBUG "Test directive files found: ${#has_tests[@]}"


      # Remove empty elements from arrays
      assert_files=("${assert_files[@]}" )
      test_files=("${test_files[@]}" )
      has_tests=("${has_tests[@]}" )

      # Function to filter out elements of array1 that are present in array2
      filter_arrays() {
          local -n array1=$1
          local -n array2=$2
          local temp_array=()
          local skip

          for item1 in "${array1[@]}"; do
              skip=0
              for item2 in "${array2[@]}"; do
                  if [[ "$item1" == "$item2" ]]; then
                      skip=1
                      break
                  fi
              done
              if [[ skip -eq 0 ]]; then
                  temp_array+=("$item1")
              fi
          done

          array1=("${temp_array[@]}")
      }

      # Filter out assert_files from has_tests
      filter_arrays has_tests assert_files
      # Filter out assert_files from test_files
      filter_arrays test_files assert_files
      # Filter out has_tests from test_files
      filter_arrays test_files has_tests
      # Remove empty elements from arrays
      assert_files=("${assert_files[@]}" )
      test_files=("${test_files[@]}" )
      has_tests=("${has_tests[@]}" )


    # Combine all files and make the collection unique
    all_files=( "${files_to_test[@]} ${assert_files[@]}" "${test_files[@]}" "${has_tests[@]}" )
    readarray -t unique_files < <(printf "%s\n" "${all_files[@]}" | sort -u)
    
    # add each unique file
    for file in "${unique_files[@]}"; do
        if [ -f "${file}" ]; then
          add_to_list "$file" files_to_test
        fi
    done
}



PreCommitReports() {
 return 0
}


# Function to delete .html files from the included_files list
delete_html_files() {
    for file in "${files_to_test[@]}"; do
        if [ -f "${METTALOG_OUTPUT}/${file}.html" ]; then
  	    IF_REALLY_DO rm -f "${METTALOG_OUTPUT}/${file}.html"
        fi
    done
}

# Function to check if a file is in an array
run_tests() {
    for file in "${files_to_test[@]}"; do
        if [ -f "${file}" ]; then
            process_file "$file"
        else
            do_DEBUG "${RED}File does not exist:${NC} $file"
        fi
    done
}




show_help() {
    # Help section with detailed usage instructions
    echo "Options:"
    echo "  -y|--yes                   Automatically choose 'y' for rerunning all tests"
    echo "  -n|--no                    Automatically choose 'n'"
    echo "  --fresh                    Clean up by deleting any .answers files under directory"
    echo "  --clean                    Clean up by deleting all .html files under directory"
    echo "  --continue                 Continue running tests (Generating any missing html files)"
    echo "  --failures                 Rerun unsuccessful tests only"
    echo "  --timeout=SECONDS          Specify a timeout value in seconds (current: $METTALOG_MAX_TIME)"
    echo "  --report=(Y/N)             Generate a report (if not supplied, will be asked at the end)"
    echo "  --output=DIR               Specify the output directory (current: $METTALOG_OUTPUT)"
    echo "  --[in|ex]clude=PATTERN     Include or exclude tests based on pattern"
    echo "  --dry-run                  Simulate the execution without actually running the tests"
    echo "  -h|--help                  Display this help message"
    echo ""
    echo "Arguments:"
    echo "  directory                   Directory to find .metta file tests (current: ${SCRIPT_DIR}/${UNITS_DIR})"
    echo "  extra args                  Optional command-line arguments passed to MeTTaLog"
    echo ""
    echo "Examples:"
    echo "  # Run under '${SCRIPT_DIR}/$METTALOG_OUTPUT/baseline_compat/hyperon-pln_metta/sumo' with a 60 second timeout per test"
    echo "  $0 $METTALOG_OUTPUT/ --include \"*sumo/\" --timeout=60"
    echo ""
    echo "  # Automatically (chooses 'y') cleans up and runs all tests in default '${SCRIPT_DIR}/examples' directory with a 180 second timeout per test"
    echo "  $0 -y --clean --timeout=180"
    echo ""
    echo "Note: Arguments can be in any order."
}


# Function to extract directories and their parents from the files_to_test array
# Function to extract all parent directories for each file
extract_all_parent_directories() {
    declare -A directory_map  # Use an associative array to avoid duplicate entries

    for filepath in "${files_to_test[@]}"; do
        # Extract the directory path of the current file
        current_dir=$(dirname "$filepath")

        # Traverse up the directory path until the root or predefined level
        while [[ "$current_dir" != "." && "$current_dir" != "/" && "$current_dir" != "tests" ]]; do  
	  # Change "/" to a different level if needed
            # Add the directory to the map
	    # DEBUG "CD $current_dir"
            directory_map["$current_dir"]=1
            # Move up to the parent directory
            current_dir=$(dirname "$current_dir")
        done
    done

    # Convert the associative array keys to an indexed array
    unique_directories=("${!directory_map[@]}")
}

# Function to sort directories by their depth
sort_directories_by_depth() {
    # Use array to store sorted directories
    IFS=$'\n' read -d '' -r -a sorted_directories1 < <(for dir in "${unique_directories[@]}"; do
        echo "$dir"
    done | sort )

    # Assign sorted directories back to unique_directories
    unique_directories=("${sorted_directories1[@]}")

    # Use array to store sorted directories
    IFS=$'\n' read -d '' -r -a sorted_directories2 < <(for dir in "${unique_directories[@]}"; do
        echo "$dir"
    done | awk -F'/' '{print NF-1, $0}' | sort -nr | cut -d' ' -f2-)

    # Assign sorted directories back to unique_directories
    unique_directories=("${sorted_directories2[@]}")
}




cd "$METTALOG_DIR"

# command-line argument parsing
while [ "$#" -gt 0 ]; do
    case "$1" in
        -y|--yes) run_tests_auto_reply="y" ;;
        -n|--no) run_tests_auto_reply="n" ;;
        --timeout=*) METTALOG_MAX_TIME="${1#*=}" ;;
	--output=*) METTALOG_OUTPUT="${1#*=}"  ;;
        --report=*) generate_report_auto_reply="${1#*=}" ;;
        --clean) clean=1; if_failures=0 ;;
        --regression*) clean=0; if_failures=0; if_regressions=1 ;;
        --continu*) clean=0; if_failures=0 ;;	
        --failure*) clean=0; if_failures=1 ;;
        --dry-run) dry_run=1 ;;
        --test) dry_run=0 ; add_to_list "$1" passed_along_to_mettalog ;;	    
        --fresh) fresh=1 ;;
        --exclude=*) EXTRA_FIND_ARGS+=" ! -path ${1#*=}"; CANT_HAVE="${1#*=}" ;;
        --include=*) EXTRA_FIND_ARGS+=" -path ${1#*=}"; MUST_HAVE="${1#*=}" ;;
        -h|--help) DEBUG "Usage: $0 [options] [directory] [extra args]"; show_help=1; dry_run=1 ;;
	-*) add_to_list "$1" passed_along_to_mettalog ;;
         *)
	    if [ -d "$1" ]; then
		add_test_units_dir "$1"
	    elif [ -f "$1" ]; then
		files_to_test+=("$1")
	    else
		find_test_masks "$1"
	    fi
            ;;
    esac
    shift
done


extract_all_parent_directories

sort_directories_by_depth

# Report excluded files and directories
DEBUG "Excluded files:"
printf '%s\n' "${excluded_files[@]}"

DEBUG "Excluded directories:"
printf '%s\n' "${excluded_dirs[@]}"

# DEBUG "All unique parent directories:"
for dir in "${unique_directories[@]}"; do
   IF_REALLY_DO mkdir -p "${METTALOG_OUTPUT}/$dir"
done

if [ $show_help -eq 1 ]; then
  show_help
fi

# Delete HTML files if the clean flag is set
if [ $clean -eq 1 ]; then
  delete_html_files
fi

# Prompt user to rerun all tests if run_tests_auto_reply is not set
if [ -z "$run_tests_auto_reply" ]; then
    read -p "Rerun all tests? (y/N): " -n 1 -r
    DEBUG ""
else
    REPLY=$run_tests_auto_reply
fi


# Run tests and generate MeTTaLog report
if [[ $REPLY =~ ^[Yy]$ ]]; then
   # run our selected tests
    run_tests
else
    DEBUG "Skipping test run."
fi

IF_REALLY_DO scripts/pass_fail_totals.sh $METTALOG_OUTPUT

# Prompt for code commit and unit report generation
if [ -z "$generate_report_auto_reply" ]; then
    read -p "Commit code and generate unit reports? (y/N): " -n 1 -r
    DEBUG ""
else
    REPLY=$generate_report_auto_reply
fi

if [[ $REPLY =~ ^[Yy]$ ]]; then
    IF_REALLY_DO PreCommitReports
else
    DEBUG "Skipping report generation."
fi

