# Generate Ghost Files Pre-commit Hook

This pre-commit hook automatically generates "ghost" files for versioned files to ensure that pull requests show diffs between versions.

## Problem Solved

When working with versioned files like:
- `src/libs/schemas/order-status-event/order-status-event-1.0.1.json`
- `src/workers/order-status-event/order-status-event-1.0.0.ts`

Git pull requests often don't show diffs compared to previous versions because the files are completely different (different names). This hook creates ghost files (e.g., `order-status-event.json.ghost`) that get updated with each new version, ensuring diffs are always visible.

## How It Works

The hook scans the specified directories for versioned files and generates "ghost" files that always contain the latest version. This ensures that when you create a new version of a file, the ghost file will show a diff in pull requests.

**Important**: The hook creates/updates ghost files but does NOT stage them automatically. You need to manually add them to your commit after the hook runs.

**Validation**: The hook will fail if you try to commit a versioned file without a corresponding ghost file, ensuring consistency.

## Configuration Arguments

The hook accepts the following arguments in your `.pre-commit-config.yaml`:

- **First argument**: Ghost file suffix (e.g., `.ghost`)
- **Remaining arguments**: Directories to scan for versioned files

## Usage

### After Installation

After installing the hook, you must run it once to generate ghost files for all existing versioned files:

```bash
pre-commit run generate-ghost-files --all-files
```

**Then manually add the generated ghost files to your commit:**

```bash
git add **/*.ghost
git commit -m "Add ghost files for versioned schemas and workers"
```

### Normal Operation

On subsequent commits, the hook will:
- **Create/Update**: Generate or update ghost files when versioned files change
- **Fail**: Always fail when ghost files are created/updated (requiring user action)
- **Validate**: Check that staged versioned files have up-to-date ghost files
- **Enforce**: Block commits until ghost files are properly staged

### Workflow

1. **Stage versioned file**: `git add src/libs/schemas/order-status-event/order-status-event-1.0.3.json`
2. **Try to commit**: `git commit -m "Update order status event"`
3. **Hook runs and fails**:
   ```
   Ghost file 'src/libs/schemas/order-status-event/order-status-event.json.ghost' was created/updated and needs to be added to your commit.
   Please run: git add src/libs/schemas/order-status-event/order-status-event.json.ghost
   Then commit again.
   ```
4. **Add ghost file**: `git add src/libs/schemas/order-status-event/order-status-event.json.ghost`
5. **Commit again**: `git commit -m "Update order status event"` ✅

### Error Handling

The hook will fail in these scenarios:

1. **Missing ghost file**: When a versioned file is staged but has no ghost file
2. **Out of sync ghost file**: When a ghost file exists but doesn't match the staged version
3. **New ghost file created**: When the hook creates/updates a ghost file

In all cases, the hook provides clear instructions on how to fix the issue.

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

