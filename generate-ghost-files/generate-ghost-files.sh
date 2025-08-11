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

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
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

# Function to generate ghost file for a directory
generate_ghost_for_dir() {
    local dir="$1"
    local file_type="$2"
    
    if [ ! -d "$dir" ]; then
        log_warn "Directory $dir does not exist, skipping"
        return 0
    fi
    
    log_info "Processing $file_type directory: $dir"
    
    # Find all subdirectories that contain versioned files
    log_info "Searching for subdirectories in: $dir"
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
                    
                    # Add the ghost file to git staging if it's not already staged
                    if ! git diff --cached --name-only | grep -q "^$(git rev-parse --show-prefix)$ghost_file$"; then
                        git add "$ghost_file"
                        log_info "Added ghost file to git staging: $ghost_file"
                    else
                        log_info "Ghost file already staged: $ghost_file"
                    fi
                fi
            fi
        fi
    done
}

# Main execution
main() {
    log_info "Starting ghost file generation for versioned files"
    log_info "Received directories string: '$DIRS_STRING'"
    log_info "Parsed directories array: ${DIRS[*]}"
    log_info "Number of directories: ${#DIRS[@]}"
    log_info "Directories to scan: ${DIRS[*]}"
    log_info "Ghost suffix: $GHOST_SUFFIX"
    
    # Process all directories
    for dir in "${DIRS[@]}"; do
        if [ -n "$dir" ]; then
            generate_ghost_for_dir "$dir" "versioned files"
        fi
    done
    
    log_info "Ghost file generation completed successfully"
}

# Run main function
main "$@"

