#!/usr/bin/env bash

# Script info
declare -r SCRIPT_NAME="checkupdates-aurman"
declare -r SCRIPT_VERSION="1.0.0"

# Settings
SETTING_SHOW_HELP=0
SETTING_ORIGIN=0
SETTING_TABLE=0
SETTING_COLOR=0

# Output formatting
FORMATTED_OUTPUT=""
NAME_COL_WIDTH=0
VER_COL_WIDTH=0

# Associative array used to hold new versions
declare -A NEW_VERSIONS

# Initialize colors as empty strings
GREEN=""
YELLOW=""
BLUE=""
MAGENTA=""
CYAN=""
WHITE=""
BOLD=""
NORMAL=""

# Enables colors using tput
enable_colors() {
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    WHITE=$(tput setaf 7)
    BOLD=$(tput bold)
    NORMAL=$(tput sgr0)
}

# Print help section
print_help() {
	printf '%s\n' "${BOLD}${BLUE}${SCRIPT_NAME}${NORMAL} @ ${BOLD}${YELLOW}v${SCRIPT_VERSION}${NORMAL}"
	printf '\n'
	printf '%s\n' "Print a list of available updates from both ${GREEN}official repositories${NORMAL} and the ${BLUE}AUR${NORMAL}."
	printf '%s\n' "${BOLD}Requires aurman and jq.${NORMAL}"
	printf '\n'
	printf '%s\n' "${BOLD}Usage:${NORMAL}"
	printf '    %s\n' "${SCRIPT_NAME} [...options]"
	printf '\n'
	printf '%s\n' "${BOLD}Options:${NORMAL}"
	printf '    %-20s %s \n' "  -h, --help" "Show this screen."
	printf '    %-20s %s \n' "  -c, --color" "Print list in ${BOLD}${GREEN}c${BLUE}o${YELLOW}l${CYAN}o${MAGENTA}r${NORMAL}."
	printf '    %-20s %s \n' "  -t, --table" "Print list in the form of a table."
	printf '    %-20s %s \n' "  -o, --origin" "Add a tag for each update, indicating the origin of the package."
	printf '\n'
	printf '    %-20s %s \n' " " "Possible origin tags:"
	printf '    %-20s %s \n' " " "${BOLD}${GREEN}[REP]${NORMAL} - Official repository packages (REPO_PACKAGE)"
	printf '    %-20s %s \n' " " "${BOLD}${BLUE}[AUR]${NORMAL} - AUR packages (AUR_PACKAGE)"
	printf '    %-20s %s \n' " " "${BOLD}${CYAN}[DEV]${NORMAL} - Development packages (DEVEL_PACKAGE)"
	printf '    %-20s %s \n' " " "${BOLD}${YELLOW}[EXT]${NORMAL} - External packages (PACKAGE_NOT_REPO_NOT_AUR)"
	printf '    %-20s %s \n' " " "${BOLD}${WHITE}[UNK]${NORMAL} - Unknown packages with missing type_of value"
	printf '\n'
}

# Compares length of package name and version
# Stores the longest lengths
update_col_widths() {
    name_length=${#1}
    version_length=${#2}

    if [ "${name_length}" -gt "${NAME_COL_WIDTH}" ]; then
        NAME_COL_WIDTH=${name_length}
    fi

    if [ "${version_length}" -gt "${VER_COL_WIDTH}" ]; then
        VER_COL_WIDTH=${version_length}
    fi
}

# Formats the origin tag based on the packages type_of value
format_origin() {
    case $1 in
        "REPO_PACKAGE")
          printf "${BOLD}${GREEN}%s${NORMAL}" "[REP]"
          ;;
        "AUR_PACKAGE")
          printf "${BOLD}${BLUE}%s${NORMAL}" "[AUR]"
          ;;
        "DEVEL_PACKAGE")
          printf "${BOLD}${CYAN}%s${NORMAL}" "[DEV]"
          ;;
        "PACKAGE_NOT_REPO_NOT_AUR")
          printf "${BOLD}${YELLOW}%s${NORMAL}" "[EXT]"
          ;;
        *)
          printf "${BOLD}${WHITE}%s${NORMAL}" "[UNK]"
          ;;
    esac
}

# Formats new version string, highlighting differences compared to current version
format_new_version() {
    curr_index=0
    diff_index=-1

    while [ ${diff_index} -eq -1 ]; do
        if [ "${1:${curr_index}:1}" != "${2:${curr_index}:1}" ]
        then
            diff_index=${curr_index}
        else
            curr_index=$(( curr_index+1 ))
        fi
    done

    unchanged_part=${2:0:${diff_index}}
    changed_part=${2:${diff_index}}
    printf "%s" "${unchanged_part}${GREEN}${changed_part}${NORMAL}"
}

# Formats package values into readable lines
format_update() {
    name_str="${BOLD}${1}${NORMAL}"
    curr_version_str="${2}"
    new_version_str="${NEW_VERSIONS[${1}]}"

    if [ ${SETTING_COLOR} = 1 ]; then
        new_version_str="$(format_new_version ${2} ${new_version_str})"
    fi

    default_values="${name_str} ${curr_version_str} ${BOLD}${MAGENTA}->${NORMAL} ${new_version_str}"

    if [ "$SETTING_ORIGIN" -eq 1 ]; then
        FORMATTED_OUTPUT="${FORMATTED_OUTPUT} $(format_origin ${3}) ${default_values}"
    else
        FORMATTED_OUTPUT="${FORMATTED_OUTPUT} ${default_values}"
    fi

    if [ "$SETTING_TABLE" -eq 1 ]; then
        update_col_widths ${name_str} ${curr_version_str}
    fi
}

check_and_print_updates() {
    # Fetch list of available packages using aurmansolver, parsing the JSON with jq
    solver_result=$(aurmansolver -Su);
    new_updates=$(jq -r '.[0] | .[0] | .[] | [.name, .version] | "\(.[0]) \(.[1])"' <<< ${solver_result})
    current_packages=$(jq -r '.[1] | .[0] | .[1] | .[] | [.name, .version, .type_of] | "\(.[0]) \(.[1]) \(.[2])"' <<< ${solver_result})

    # Exit if no updates are available
    if [ -z "${new_updates}" ]; then
        exit 0
    fi

    # Loop through updates and store available versions for later
    while IFS="=" read -r update; do
        set -- ${update} # set package name and version as arguments 1 and 2
        NEW_VERSIONS["${1}"]="${2}"
    done <<< ${new_updates}

    # Format each update
    while IFS="=" read -r update_info; do
        format_update ${update_info}
    done <<< ${current_packages}

    # Set table formatting based on longest strings if table setting is enabled
    if [ "$SETTING_TABLE" -eq 1 ]; then
        print_formatting="%-$(( NAME_COL_WIDTH+2 ))s %-$(( VER_COL_WIDTH+2 ))s %s %s\n"
    else
        print_formatting="%s %s %s %s\n"
    fi

    # Print lines with origin tag if setting is enabled, otherwise without
    if [ "$SETTING_ORIGIN" -eq 1 ]; then
        printf "%s ${print_formatting}" ${FORMATTED_OUTPUT}
    else
        printf "${print_formatting}" ${FORMATTED_OUTPUT}
    fi
}

# Parse arguments
while [ "$1" != "" ]; do
    case $1 in
        -h | --help )
            SETTING_SHOW_HELP=1
            ;;
        -c | --color )
            SETTING_COLOR=1
            enable_colors
            ;;
        -t | --table )
            SETTING_TABLE=1
            ;;
        -o | --origin )
            SETTING_ORIGIN=1
            ;;
        * )
            printf '%s\n' "Error: Invalid option (${1})"
            exit 1
    esac
    shift
done

# Print help if requested
if [ "$SETTING_SHOW_HELP" -eq 1 ]; then
    print_help
else
    check_and_print_updates
fi

exit 0