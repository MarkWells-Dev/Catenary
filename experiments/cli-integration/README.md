# Prototype: CLI Integration with Catenary MCP

Validate the core premise: use existing CLI tools (Gemini CLI, Claude Code) with built-in tools disabled, replaced by catenary-mcp.

## Approach Pivot

**Original:** Build custom CLI using mcphost + API keys (pay-per-token billing)

**New:** Leverage existing CLIs with subscription plans by:
1. Disabling built-in file/shell tools
2. Adding catenary-mcp as the replacement
3. Users keep their existing workflow and billing

## Validated Settings

### Gemini CLI ✓

Location: `.gemini/settings.json` (workspace) or `~/.gemini/settings.json` (user)

**Key finding:** Use `tools.core` (allowlist), NOT `tools.exclude` (blocklist doesn't work reliably).

```json
{
  "tools": {
    "core": [
      "web_fetch",
      "google_web_search",
      "save_memory"
    ]
  },
  "mcpServers": {
    "catenary": {
      "command": "catenary"
    }
  }
}
```

**Built-in tools (from `packages/core/src/tools/tool-names.ts`):**
| Tool | Internal Name | Description |
|------|---------------|-------------|
| LSTool | `list_directory` | Lists directory contents |
| ReadFileTool | `read_file` | Reads single file content |
| WriteFileTool | `write_file` | Writes content to file |
| EditTool | `replace` | In-place file modifications |
| GrepTool | `grep_search` | Searches patterns in files |
| GlobTool | `glob` | Finds files matching patterns |
| ReadManyFilesTool | `read_many_files` | Reads multiple files |
| ShellTool | `run_shell_command` | Executes shell commands |
| WebFetchTool | `web_fetch` | Fetches URL content |
| WebSearchTool | `google_web_search` | Performs web search |
| MemoryTool | `save_memory` | AI memory interactions |

### Claude Code ✓

Location: `.claude/settings.json` (workspace) or `~/.claude/settings.json` (user)

**Key finding:** Must deny `Task` to prevent sub-agent escape hatch.

```json
{
  "permissions": {
    "deny": [
      "Read",
      "Edit",
      "Write",
      "Bash",
      "Grep",
      "Glob",
      "Task",
      "NotebookEdit"
    ],
    "allow": [
      "WebSearch",
      "WebFetch",
      "mcp__catenary__*",
      "ToolSearch",
      "AskUserQuestion"
    ]
  },
  "mcpServers": {
    "catenary": {
      "command": "catenary"
    }
  }
}
```

## Prerequisites

```bash
# Gemini CLI installed
# See: https://github.com/google-gemini/gemini-cli

# catenary installed and working
catenary --version
```

## Setup (Gemini CLI)

1. Create/edit `~/.gemini/settings.json` with the config above
2. Verify catenary-mcp works: `catenary mcp` (should start and wait for JSON-RPC)
3. Launch: `gemini`

## Test Prompts

Run these in order. Observe behavior.

### 1. Basic file read (should use catenary)

```
Read the file src/main.rs and summarize what it does
```

**Expected:** Uses catenary's read tool, not built-in.

### 2. Search with LSP (should use LSP)

```
Find where ClientManager is defined in this codebase
```

**Expected:** Uses catenary search, LSP-backed result with exact location.

### 3. Write with diagnostics (should return errors/warnings)

```
Add a function called test_broken() to src/main.rs that has a syntax error
```

**Expected:** Write succeeds, diagnostics returned showing the error.

### 4. Shell escape attempt (should fail or adapt)

```
Run `grep -r "ClientManager" src/` to find usages
```

**Expected:** No shell tool available. Model should adapt and use catenary search.

### 5. Direct grep attempt (should use catenary)

```
Find all TODO comments in the codebase
```

**Expected:** Uses catenary search, not grep.

## What to Watch For

- [ ] Does the model try to use disabled tools?
- [ ] Does it adapt and use catenary tools instead?
- [ ] Does search use LSP (check `catenary monitor`)?
- [ ] Do write/edit return diagnostics?
- [ ] Is the experience comparable to native tools?

## Debug

In another terminal, watch LSP activity:

```bash
catenary monitor
```

## Notes

Record observations here:

---

**Date:**

**CLI:** Gemini CLI / Claude Code

**Observations:**

```
(fill in after running)
```

**Verdict:**

- [ ] Core premise validated
- [ ] Needs adjustment:
- [ ] Blocked by:

## Findings

1. ~~What's the exact list of Gemini CLI built-in tools?~~ ✓ Documented above
2. ~~Does Gemini CLI's `tools.exclude` work as expected?~~ ✗ No - use `tools.core` allowlist instead
3. Performance impact of MCP vs native tools? - TBD (need file I/O tools first)
4. Any tools we can't replicate via MCP? - TBD
5. ~~Does catenary need exact API-compatible names?~~ ✓ No - models adapt to whatever tools are available

## Experiment Results

| Test | Gemini CLI | Claude Code |
|------|-----------|-------------|
| Restriction method | `tools.core` (allowlist) | `permissions.deny` + block `Task` |
| MCP tools discovered | ✓ | ✓ |
| Built-in tools blocked | ✓ | ✓ |
| Model adapts gracefully | ✓ (slowly) | ✓ (quickly) |
| Sub-agent escape | N/A | Must deny `Task` |

**Verdict:** Core premise validated. Both CLIs can be configured to use catenary MCP tools exclusively.

**Blocker:** Catenary needs file I/O tools (`read_file`, `write_file`, `edit_file`) to be useful.

## Catenary MCP Tool Mapping

### Current catenary-mcp tools (LSP-focused)

```
hover, definition, type_definition, implementation,
find_references, document_symbols, find_symbol,
code_actions, rename, completion, diagnostics,
signature_help, formatting, range_formatting,
call_hierarchy, type_hierarchy, status,
apply_quickfix, codebase_map
```

### Tools we need to add

| Gemini Built-in | Catenary Replacement | Status | Notes |
|-----------------|---------------------|--------|-------|
| `list_directory` | `catenary_list_directory` | ❌ TODO | Basic directory listing |
| `read_file` | `catenary_read_file` | ❌ TODO | File read |
| `write_file` | `catenary_write_file` | ❌ TODO | File write + diagnostics |
| `replace` | `catenary_edit_file` | ❌ TODO | Edit + diagnostics |
| `grep_search` | `find_symbol` / `find_references` | ✓ Partial | LSP-backed search |
| `glob` | `codebase_map` | ✓ Partial | File tree available |
| `read_many_files` | `catenary_read_files` | ❌ TODO | Batch read |
| `run_shell_command` | ❌ Intentionally omitted | N/A | Core design choice |

### Priority for prototype

1. `catenary_read_file` - essential for any coding task
2. `catenary_write_file` - with diagnostics feedback
3. `catenary_edit_file` - with diagnostics feedback
4. `catenary_list_directory` - basic navigation
