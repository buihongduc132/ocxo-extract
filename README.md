# ocxo-extract

Compatibility wrapper for the unified `agent-extract` implementation.

## Installation

```bash
ocxo run --command <cmd> --format json | ocxo-extract [subcommand]
codex exec --json "<prompt>" | cli/ops/agent-extract/agent-extract [subcommand]
```

**Default:** If no subcommand is specified, `final-text` is used.

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
| `--no-duration` | Don't output duration |
| `--no-agent` | Don't output agent name |
| `--no-model` | Don't output model name |
| `--json` | Output tools as JSON (for tools subcommand) |
| `-h, --help` | Show help message |

## Examples

```bash
# OpenCode
ocxo run "Read 3 files and summarize" --format json | ocxo-extract

# Codex
codex exec --json "Read 3 files and summarize" | cli/ops/agent-extract/agent-extract

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
- OpenCode JSONL
- Codex `exec --json` JSONL
- Error responses
- Mixed JSON/non-JSON input
- Null/empty results

## Testing

```bash
pytest -o addopts='' cli/ops/agent-extract/tests -q
```
