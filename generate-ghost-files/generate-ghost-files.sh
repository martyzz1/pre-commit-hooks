#!/usr/bin/env bash

# Pre-commit hook to generate ghost files for versioned files
# This ensures that pull requests show diffs between versions

set -e

# Configuration comes from pre-commit args
# First argument is the ghost file suffix
GHOST_SUFFIX="${1:-.ghost}"

# Configuration: ghost suffix and colon-separated directories
if [ $# -lt 2 ]; then
    log_error "Usage: $0 <ghost_suffix> <colon_separated_directories>"
    log_error "Example: $0 .ghost src/libs/schemas:src/workers"
    exit 1
fi

# First argument is the ghost suffix, second is colon-separated directories
GHOST_SUFFIX="$1"
DIRS_STRING="$2"

# Split the directories string by colons
IFS=':' DIRS=($DIRS_STRING)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Global array to collect all created/updated ghost files
UPDATED_GHOSTS=()

# Verbose flag - set to true if --verbose is passed
VERBOSE=false

# Logging functions
log_info() {
    if [ "$VERBOSE" = true ]; then
        echo "[INFO] $1" >&2
    fi
}

log_warn() {
    echo "[WARN] $1" >&2
}

log_error() {
    echo "[ERROR] $1" >&2
}

# Function to find the latest version of a file in a directory
find_latest_version() {
    local dir="$1"
    local base_name="$2"
    local extension="$3"
    
    # Find all files matching the pattern and sort by version
    find "$dir" -name "${base_name}-*.${extension}" -type f | \
    sort -V | tail -n 1
}

# Function to extract version from filename
extract_version() {
    local filename="$1"
    local base_name="$2"
    local extension="$3"
    
    # Remove base name and extension, extract version
    local version_part=$(echo "$filename" | sed "s/^${base_name}-//" | sed "s/\.${extension}$//")
    echo "$version_part"
}

# Function to check if a file is within the configured directories
is_file_in_configured_dirs() {
    local file="$1"
    local dirs_string="$2"
    
    # Parse the colon-separated directories
    IFS=':' read -ra CONFIGURED_DIRS <<< "$dirs_string"
    
    for dir in "${CONFIGURED_DIRS[@]}"; do
        if [[ "$file" == "$dir"/* ]]; then
            return 0  # File is within this configured directory
        fi
    done
    
    return 1  # File is not within any configured directory
}

# Global array to collect all created/updated ghost files
UPDATED_GHOSTS=()

# Function to process a single file for ghost file requirements
process_file_for_ghost() {
    local file="$1"
    local configured_dirs="$2"
    
    # First check if this file is within the configured directories
    if ! is_file_in_configured_dirs "$file" "$configured_dirs"; then
        log_info "Skipping file outside configured directories: $file"
        return 0
    fi
    
    # Check if this is a versioned file
    if [[ "$file" =~ -[0-9]+\.[0-9]+(\.[0-9]+)?\.[a-zA-Z]+$ ]]; then
        log_info "Processing versioned file: $file"
        
        # Extract base name and extension
        local base_name=$(echo "$file" | sed -E 's/-[0-9]+\.[0-9]+(\.[0-9]+)?\.[a-zA-Z]+$//')
        local extension=$(echo "$file" | sed -E 's/.*\.([a-zA-Z]+)$/\1/')
        local dir=$(dirname "$file")
        local ghost_file="${dir}/${base_name}.${extension}${GHOST_SUFFIX}"
        
        log_info "Extracted base name: $base_name, extension: $extension"
        log_info "Directory: $dir"
        log_info "Ghost file path: $ghost_file"
        
        # Check if ghost file exists and if it needs updating
        local should_update=false
        if [ ! -f "$ghost_file" ]; then
            should_update=true
            log_info "Ghost file does not exist, will create: $ghost_file"
        else
            # Check if this is the first run by seeing if the ghost file is tracked in git
            if ! git ls-files --error-unmatch "$ghost_file" >/dev/null 2>&1; then
                # Ghost file exists but isn't tracked in git - this is likely a first run
                should_update=true
                log_info "Ghost file exists but not tracked in git, will update: $ghost_file"
            elif ! cmp -s "$file" "$ghost_file"; then
                # Compare content to see if the file has changed
                should_update=true
                log_info "File content has changed, will update ghost file: $ghost_file"
            else
                log_info "Ghost file is up to date: $ghost_file"
            fi
        fi
        
        if [ "$should_update" = true ]; then
            log_info "Will create/update ghost file from: $file"
            log_info "Source file exists: $([ -f "$file" ] && echo "YES" || echo "NO")"
            log_info "Target directory exists: $([ -d "$dir" ] && echo "YES" || echo "NO")"
            
            # Copy the file to the ghost file
            cp "$file" "$ghost_file"
            
            log_info "Ghost file created/updated: $ghost_file"
            
            # Add to the global collection
            UPDATED_GHOSTS+=("$ghost_file")
            log_info "Added to UPDATED_GHOSTS array. Current count: ${#UPDATED_GHOSTS[@]}"
        fi
    else
        log_info "Skipping non-versioned file: $file"
    fi
}

# Main execution
main() {
    # Check if pre-commit is running in verbose mode
    if [ "$PRE_COMMIT_VERBOSE" = "1" ]; then
        VERBOSE=true
        log_info "Verbose mode enabled (detected from pre-commit)"
    fi
    
    log_info "Starting ghost file generation for versioned files"
    
    # Parse arguments - first is ghost suffix, second is configured directories, rest are files to process
    if [ $# -lt 3 ]; then
        log_error "Usage: $0 <ghost_suffix> <configured_directories> <file1> [file2] [file3] ..."
        log_error "Example: $0 .ghost src/libs/schemas:src/workers src/libs/schemas/order-status-event/order-status-event-1.0.0.json"
        exit 1
    fi
    
    # First argument is the ghost suffix, second is the configured directories
    GHOST_SUFFIX="$1"
    CONFIGURED_DIRS="$2"
    shift 2  # Remove the first two arguments (ghost suffix and configured directories)
    
    log_info "Ghost suffix: $GHOST_SUFFIX"
    log_info "Configured directories: $CONFIGURED_DIRS"
    log_info "Files to process: $*"
    
    # Process each file individually
    for file in "$@"; do
        if [ -n "$file" ]; then
            process_file_for_ghost "$file" "$CONFIGURED_DIRS"
        fi
    done
    
    log_info "Finished processing all files. UPDATED_GHOSTS array contains ${#UPDATED_GHOSTS[@]} items: ${UPDATED_GHOSTS[*]}"
    
    # If any ghost files were created/updated, fail with comprehensive message
    if [ ${#UPDATED_GHOSTS[@]} -gt 0 ]; then
        log_error "The following ghost files were created/updated and need to be added to your commit:"
        for ghost in "${UPDATED_GHOSTS[@]}"; do
            log_error "  $ghost"
        done
        log_error ""
        log_error "Please run: git add ${UPDATED_GHOSTS[*]}"
        log_error "Then commit again."
        exit 1
    fi
    
    log_info "Ghost file generation completed successfully"
}

# Run main function
main "$@"

