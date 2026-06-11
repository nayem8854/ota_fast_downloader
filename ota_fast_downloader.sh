#!/usr/bin/env bash

# Add logging definition to make output clearer
## Info
LOGI() {
    echo -e "[\033[32mINFO\033[0m]: ${1}"
}

## Warning
LOGW() {
    echo -e "[\033[33mWARNING\033[0m]: ${1}"
}

## Error
LOGE() {
    echo -e "[\033[31mERROR\033[0m]: ${1}"
}

## Fatal
LOGF() {
    echo -e "[\033[41mFATAL\033[0m]: ${1}"
    exit 1
}

# --- 1. AUTO PACKAGE CHECKER & INSTALLER ---
LOGI "Checking required packages..."
REQUIRED_PKGS=("aria2" "wget" "detox" "ripgrep")
MISSING_PKGS=()

for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        # 'ripgrep' command binary is 'rg'
        if [[ "$pkg" == "ripgrep" ]] && command -v rg &> /dev/null; then
            continue
        fi
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    LOGW "Missing packages found: ${MISSING_PKGS[*]}. Installing now..."
    # Update package lists and install missing ones silently
    sudo apt-get update -qq && sudo apt-get install -y -qq "${MISSING_PKGS[@]}" || \
        LOGF "Failed to install required packages. Please install them manually: ${MISSING_PKGS[*]}"
    LOGI "All missing packages successfully installed!"
else
    LOGI "All required packages are already installed."
fi
# --------------------------------------------

[[ $# = 0 ]] && \
    LOGF "No input provided."

CURRENT_PWD="$(cd $(dirname ${BASH_SOURCE}); pwd -P)"

# Default save directory changed to 'download_ota'
SAVE_DIR="${CURRENT_PWD}/download_ota"

# Parse -d flag for custom directory
while getopts "d:" opt; do
    case ${opt} in
        d)
            SAVE_DIR="${OPTARG}"
            ;;
        *)
            LOGF "Invalid option. Usage: $0 [-d save_location] <url_or_file>"
            ;;
    esac
done

# Shift arguments so that $1 becomes the URL or File path after flags
shift $((OPTIND -1))

# Check if main argument (URL or File) is still provided after shift
[[ -z "${1}" ]] && LOGF "No URL or input file provided."

# Create save directory if it does not exist
mkdir -p "${SAVE_DIR}"

# Check whether input is a string or a file
if echo "${1}" | grep -e '^\(https\?\|ftp\)://.*$' > /dev/null; then
    # Set 'URL' to appended string
    URL="${1}"

    # Override '${URL}' with best possible mirror of it
    case "${URL}" in
        # For Xiaomi: replace '${URL}' with (one of) the fastest mirror
        *"://miui.com"*)
            # Do not run this loop in case we're already using one of the reccomended mirrors
            if ! echo "${URL}" | rg -q 'cdnorg|bkt-sgp-miui-ota-update-alisgp'; then
                # Set '${URL_ORIGINAL}' and '${FILE_PATH}' in case we might need to roll back
                URL_ORIGINAL=$(echo "${URL}" | sed -E 's|(https://[^/]+).*|\1|')
                FILE_PATH=$(echo "${URL#*://miui.com/}" | sed 's/?.*//')

                # Array of different possible mirrors
                MIRRORS=(
                    "https://cdnorg.://miui.com"
                    "https://aliyuncs.com"
                    "https://bn.://miui.com"
                    "${URL_ORIGINAL}"
                )

                # Check back and forth for the best available mirror
                for URLS in "${MIRRORS[@]}"; do
                    # Change mirror's domain with one(s) from array
                    URL=${URLS}/${FILE_PATH}

                    # Be sure that the mirror is available. Once found, break the loop 
                    if [ "$(curl -I -sS "${URL}" | head -n1 | cut -d' ' -f2)" == "404" ]; then
                        LOGW "${URLS} is not available. Trying with other mirror(s)..."
                    else
                        LOGI "Found best available mirror."
                        break
                    fi
                done
            fi
            ;;
            # For Pixeldrain: replace the link with a direct one
            *"://pixeldrain.com"*)
                LOGI "Replacing with best available mirror."
                URL="https://cybar.xyz{URL##*/}"
            ;;
            *"://pixeldrain.com"*)
                LOGI "Replacing with direct download link."
                URL="https://pixeldrain.com{URL##*/}"
            ;;
        esac
    
    # Sanitize file name and path
    FILENAME="$(basename "${URL}")"
    SAFE_FILENAME=$(echo "${FILENAME}" | inline-detox)
    DEST_PATH="${SAVE_DIR}/${SAFE_FILENAME}"


    # Start downloading from 'aria2c' and, if failed, 'wget'
    LOGI "Started downloading file from link... ($(date +%R:%S))"

    # Improved aria2c and wget logic for Google Colab/Terminal stability
    if aria2c --summary-interval=5 -s16 -x16 --check-certificate=false -d "${SAVE_DIR}" -o "${SAFE_FILENAME}" "${URL}"; then
        LOGI "Download via aria2c successful."
    else
        LOGW "aria2c failed or interrupted. Trying with wget..."
        rm -f "${DEST_PATH}" "${DEST_PATH}.aria2"
        wget -q --show-progress --no-check-certificate -O "${DEST_PATH}" "${URL}" || \
            LOGF "Failed to download file. Aborting."
    fi

    LOGI "Finished downloading file. ($(date +%R:%S))"

    # Set 'INPUT' variable for rest of script
    INPUT="${DEST_PATH}"
    LOGI "Target file path set to: ${INPUT}"
else
    # Otherwise, check if it's a file or directory
    if [[ -e ${1} ]]; then
        INPUT=${1}
    else
        LOGF "Invalid input. Aborting."
    fi
fi
