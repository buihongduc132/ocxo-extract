# ocxo-extract

Extract text and metadata from ocxo JSON output.

## Installation

```bash
curl -sSL https://raw.githubusercontent.com/buihongduc132/ocxo-extract/main/ocxo-extract -o ~/.local/bin/ocxo-extract
chmod +x ~/.local/bin/ocxo-extract
```

## Usage

```bash
ocxo run --command <cmd> --format json | ocxo-extract [subcommand]
```

**Default:** If no subcommand is specified, uses `final-text`.

### Subcommands

| Subcommand | Description |
|------------|-------------|
| `final-text` | Extract text where type == step_finish and messageID is matching (default) |
| `last-text` | Extract last text when type == "text" |
| `before-finish` | Extract text just above type == step_finish |
| `tools` | Show tool usage summary (tools called, files read, commands run) |

### Options

| Option | Description |
|--------|-------------|
| `--no-session` | Don't output session ID (text only) |
| `--json` | Output tools as JSON (for tools subcommand) |
| `-h, --help` | Show help message |

## Examples

```bash
# Default - extract final text
ocxo run "Read 3 files and summarize" --format json | ocxo-extract

# Extract last text without session
ocxo run --command se_infra --format json | ocxo-extract last-text --no-session

# Show tool usage summary
ocxo run "Read foo.md and fix the bug" --format json | ocxo-extract tools

# Get tool usage as JSON for further processing
ocxo run "Do something" --format json | ocxo-extract tools --json --no-session
```

## Tools Output

The `tools` subcommand shows:
- Tools used (unique list)
- Total tool calls
- Calls by tool (breakdown)
- Files read
- Files written/edited
- Commands run

Example output:
```
Session: ses_abc123
---
Tools Used: bash, read, edit

Total Tool Calls: 5

Calls by Tool:
  bash: 2
  read: 2
  edit: 1

Files Read:
  /path/to/file1.md
  /path/to/file2.md

Files Written/Edited:
  /path/to/file3.md

Commands Run:
  npm test
  git status
```

## Error Handling

Handles:
- Error responses (`type: error`) - displays error name, message, status code
- Non-JSON lines - filters gracefully
- Null/empty results - proper error messages

## Testing

```bash
bash ocxo-extract.test.sh
```
