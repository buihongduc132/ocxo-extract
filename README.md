# ocxo-extract

Extract text and metadata from ocxo JSON output.

## Installation

```bash
curl -sSL https://raw.githubusercontent.com/bhdtech/ocxo-extract/main/ocxo-extract -o ~/.local/bin/ocxo-extract
chmod +x ~/.local/bin/ocxo-extract
```

## Usage

```bash
ocxo run --command <cmd> --format json | ocxo-extract <subcommand>
```

### Subcommands

| Subcommand | Description |
|------------|-------------|
| `last-text` | Extract last text when type == "text" |
| `before-finish` | Extract text just above type == step_finish |
| `final-text` | Extract text where type == step_finish and messageID is matching |

### Options

| Option | Description |
|--------|-------------|
| `--no-session` | Don't output session ID (text only) |
| `-h, --help` | Show help message |

## Examples

```bash
# Extract final text
ocxo run --command se_infra --format json | ocxo-extract final-text

# Extract last text without session
ocxo run --command se_infra --format json | ocxo-extract last-text --no-session
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
