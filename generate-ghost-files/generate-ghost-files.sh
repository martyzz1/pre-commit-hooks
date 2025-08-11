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

# Logging functions
log_info() {
    echo "[INFO] $1" >&2
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

# Global array to collect all created/updated ghost files
UPDATED_GHOSTS=()

# Function to process a directory for ghost files
process_directory_for_ghosts() {
    local dir="$1"
    local description="$2"
    
    log_info "Processing $description directory: $dir"
    
    # Find all subdirectories in this directory
    local subdirs=$(find "$dir" -type d)
    log_info "Found subdirectories: $subdirs"
    
    echo "$subdirs" | while read -r subdir; do
        # Skip the root directory itself
        if [ "$subdir" = "$dir" ]; then
            log_info "Skipping root directory: $subdir"
            continue
        fi
        
        log_info "Processing subdirectory: $subdir"
        
        # Look for files with version patterns in this subdirectory
        log_info "Looking for versioned files in: $subdir"
        local base_files=$(find "$subdir" -maxdepth 1 -type f -name "*-*.json" -o -name "*-*.ts" | head -1)
        log_info "Found base files: $base_files"
        
        if [ -n "$base_files" ]; then
            log_info "Processing versioned files in: $subdir"
            # Get the base name without version and extension
            local first_file=$(echo "$base_files" | head -n 1)
            local filename=$(basename "$first_file")
            local extension="${filename##*.}"
            # Extract base name by removing version pattern and extension
            local base_name=$(echo "$filename" | sed -E 's/-[0-9]+\.[0-9]+(\.[0-9]+)?\.[a-zA-Z]+$//')
            log_info "Extracted base name: $base_name, extension: $extension"
            
            # Find the latest version
            local latest_file=$(find_latest_version "$subdir" "$base_name" "$extension")
            log_info "Latest version file: $latest_file"
            
            if [ -n "$latest_file" ]; then
                local ghost_file="${subdir}/${base_name}.${extension}${GHOST_SUFFIX}"
                local latest_version=$(extract_version "$(basename "$latest_file")" "$base_name" "$extension")
                
                # Check if ghost file exists and if the latest version has changed
                local should_update=false
                if [ ! -f "$ghost_file" ]; then
                    should_update=true
                    log_info "Ghost file does not exist, creating: $ghost_file"
                else
                    # Check if this is the first run by seeing if the ghost file is tracked in git
                    if ! git ls-files --error-unmatch "$ghost_file" >/dev/null 2>&1; then
                        # Ghost file exists but isn't tracked in git - this is likely a first run
                        should_update=true
                        log_info "Ghost file exists but not tracked in git, updating: $ghost_file"
                    elif ! cmp -s "$latest_file" "$ghost_file"; then
                        # Compare content to see if latest version has changed
                        should_update=true
                        log_info "Latest version has changed, updating ghost file: $ghost_file"
                    else
                        log_info "Ghost file is up to date: $ghost_file"
                    fi
                fi
                
                if [ "$should_update" = true ]; then
                    log_info "Found latest version: $latest_file (v$latest_version)"
                    log_info "Generating/updating ghost file: $ghost_file"
                    
                    # Copy the latest version to the ghost file
                    cp "$latest_file" "$ghost_file"
                    
                    log_info "Ghost file created/updated: $ghost_file"
                    
                    # Add to the global collection instead of failing immediately
                    UPDATED_GHOSTS+=("$ghost_file")
                fi
            fi
        fi
    done
}

# Function to check if staged versioned files have ghost files
check_staged_versioned_files() {
    local missing_ghosts=()
    
    # Get all staged files
    local staged_files=$(git diff --cached --name-only)
    
    for staged_file in $staged_files; do
        # Check if this is a versioned file
        if [[ "$staged_file" =~ -[0-9]+\.[0-9]+(\.[0-9]+)?\.[a-zA-Z]+$ ]]; then
            # Extract base name and extension
            local base_name=$(echo "$staged_file" | sed -E 's/-[0-9]+\.[0-9]+(\.[0-9]+)?\.[a-zA-Z]+$//')
            local extension=$(echo "$staged_file" | sed -E 's/.*\.([a-zA-Z]+)$/\1/')
            local dir=$(dirname "$staged_file")
            local ghost_file="${dir}/${base_name}.${extension}${GHOST_SUFFIX}"
            
            # Check if ghost file exists and is up to date
            if [ ! -f "$ghost_file" ]; then
                missing_ghosts+=("$ghost_file")
            else
                # Check if ghost file is out of sync with the staged version
                local staged_content=$(git show ":$staged_file")
                if ! echo "$staged_content" | cmp -s "$ghost_file" -; then
                    missing_ghosts+=("$ghost_file (out of sync)")
                fi
            fi
        fi
    done
    
    # If any ghost files are missing or out of sync, fail with helpful message
    if [ ${#missing_ghosts[@]} -gt 0 ]; then
        log_error "Error: The following ghost files are missing or out of sync for staged versioned files:"
        for ghost in "${missing_ghosts[@]}"; do
            log_error "  $ghost"
        done
        log_error ""
        log_error "Please run: git add ${missing_ghosts[*]% (*}"
        log_error "Then commit again."
        exit 1
    fi
}

# Main execution
main() {
    log_info "Starting ghost file generation for versioned files"
    
    # Parse arguments - only take the first two, ignore any additional args from pre-commit
    if [ $# -lt 2 ]; then
        log_error "Usage: $0 <ghost_suffix> <directories>"
        log_error "Example: $0 .ghost src/libs/schemas:src/workers"
        exit 1
    fi
    
    # First argument is the ghost suffix, second is the colon-separated directories
    GHOST_SUFFIX="$1"
    DIRS_STRING="$2"
    
    log_info "Ghost suffix: $GHOST_SUFFIX"
    log_info "Directories to scan: $DIRS_STRING"
    
    # Parse the colon-separated directories string and filter out any non-directory paths
    IFS=':' read -ra DIRS <<< "$DIRS_STRING"
    local valid_dirs=()
    for dir in "${DIRS[@]}"; do
        if [ -d "$dir" ]; then
            valid_dirs+=("$dir")
        else
            log_warn "Skipping non-directory path: $dir"
        fi
    done
    DIRS=("${valid_dirs[@]}")
    
    if [ ${#DIRS[@]} -eq 0 ]; then
        log_error "No valid directories found to scan"
        exit 1
    fi
    
    # Process all directories to generate/update ghost files
    for dir in "${DIRS[@]}"; do
        if [ -n "$dir" ]; then
            # Pass the updated_ghosts array to collect results
            process_directory_for_ghosts "$dir" "versioned files"
        fi
    done
    
    # Now check if staged versioned files have ghost files
    check_staged_versioned_files
    
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

