# Generate Ghost Files Pre-commit Hook

This pre-commit hook automatically generates "ghost" files for versioned files to ensure that pull requests show diffs between versions.

## Problem Solved

When working with versioned files like:
- `src/libs/schemas/order-status-event/order-status-event-1.0.1.json`
- `src/workers/order-status-event/order-status-event-1.0.0.ts`

Git pull requests often don't show diffs compared to previous versions because the files are completely different (different names). This hook creates ghost files (e.g., `order-status-event.json.ghost`) that get updated with each new version, ensuring diffs are always visible.

## How It Works

1. **Scans configured directories** for versioned files
2. **Identifies the latest version** of each file using semantic versioning
3. **Generates/updates ghost files** by copying the latest version
4. **Automatically stages** the ghost files in git

## Configuration

The hook is configured via arguments in the `.pre-commit-config.yaml` file:

### Configuration Arguments

The hook accepts arguments in this order:
1. **Ghost suffix**: Suffix for ghost files (required)
2. **Directories to scan**: One or more directories containing versioned files (required)

### Example Configuration

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: generate-ghost-files
        name: Generate Ghost Files
        entry: generate-ghost-files/generate-ghost-files.sh
        language: system
        stages: [pre-commit]
        args: [
          ".ghost",            # Ghost file suffix (required)
          "src/libs/schemas",  # First directory to scan (required)
          "src/workers"        # Additional directory to scan (optional)
        ]
```

**Note**: Both the ghost suffix and at least one directory are required arguments.
```

### Multiple Directories

Simply add more directory arguments:

```yaml
args: [
  ".latest",           # Ghost file suffix
  "src/libs/schemas",  # First directory
  "src/libs/models",   # Second directory
  "src/workers",       # Third directory
  "src/processors"     # Fourth directory
]
```

## File Naming Convention

The hook expects versioned files to follow this pattern:
- Base name + version + extension
- Examples:
  - `order-status-event-1.0.0.json`
  - `order-status-event-1.0.1.json`
  - `order-status-event-2.0.0.ts`

## Generated Ghost Files

For each versioned file, a ghost file is created:
- **Input**: `order-status-event-1.0.1.json`
- **Ghost**: `order-status-event.json.ghost`

The ghost file always contains the latest version and gets updated on each commit.

## Usage

### 1. Add to pre-commit configuration

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: generate-ghost-files
        name: Generate Ghost Files
        entry: generate-ghost-files/generate-ghost-files.sh
        language: system
        stages: [pre-commit]
```

### 2. Run manually (for testing)

```bash
# Arguments are required: ghost suffix and at least one directory
./generate-ghost-files/generate-ghost-files.sh .ghost src/libs/schemas
```

### 3. With custom configuration

```bash
# Pass arguments directly to the script
# First argument: ghost file suffix, then directories to scan
./generate-ghost-files/generate-ghost-files.sh ".latest" "src/schemas" "src/models" "src/workers"
```

## Example Output

```
[INFO] Starting ghost file generation for versioned files
[INFO] Directories to scan: src/libs/schemas src/workers
[INFO] Ghost suffix: .ghost
[INFO] Processing versioned files directory: src/libs/schemas
[INFO] Found latest version: src/libs/schemas/order-status-event/order-status-event-1.0.1.json (v1.0.1)
[INFO] Generating/updating ghost file: src/libs/schemas/order-status-event/order-status-event.json.ghost
[INFO] Added ghost file to git staging: src/libs/schemas/order-status-event/order-status-event.json.ghost
[INFO] Processing versioned files directory: src/workers
[INFO] Ghost file generation completed successfully
```

## Benefits

- **Always see diffs** in pull requests between versions
- **Automatic updates** - no manual maintenance required
- **Configurable** - works with any directory structure
- **Git integration** - automatically stages generated files
- **Safe** - only reads existing files, never deletes

## Requirements

- Bash shell
- Git repository
- Files following the versioning naming convention

## Troubleshooting

### Ghost files not being generated
- Check that directories exist and contain versioned files
- Verify file naming follows the expected pattern
- Check pre-commit configuration arguments

### Files not being staged
- Ensure you're in a git repository
- Check git status and staging area
- Verify file permissions

### Version detection issues
- Ensure versions follow semantic versioning (e.g., 1.0.0, 2.1.3)
- Check for consistent naming patterns

