# CLI Integration Experiment Findings

**Date:** 2026-02-06
**CLI:** Gemini CLI
**Catenary Version:** `catenary --version`

---

## Setup Verification

| Check                     | Result       | Notes |
| ------------------------- | ------------ | ----- |
| Gemini CLI installed      | ☐ Yes / ☐ No |       |
| Catenary MCP starts       | ☐ Yes / ☐ No |       |
| Workspace settings loaded | ☐ Yes / ☐ No |       |

---

## Test 1: Tool Discovery

**Prompt:** `What tools do you have available?`

**Expected:** Should list catenary tools (lsp*\*, catenary*\*), NOT built-in tools (read_file, shell, etc.)

**Actual Result:**

```

```

**Built-in tools visible?** ☐ Yes / ☐ No
**Catenary tools visible?** ☐ Yes / ☐ No

---

## Test 2: Read File (disabled tool)

**Prompt:** `Read the file main.rs`

**Expected:** Should fail or say no tool available (catenary lacks read_file)

**Actual Result:**

```
> Read the file main.rs

  Responding with gemini-3-flash-preview
✦ I will read the contents of main.rs to understand its current state.
╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ x  WebFetch {"prompt":"read the file /tmp/catenary-experiment/main.rs"}                                          │
│                                                                                                                  │
│ The 'prompt' must contain at least one valid URL (starting with http:// or https://).                            │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
✦ I will read the contents of main.rs.
╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ x  WebFetch {"prompt":"read the file /tmp/catenary-experiment/main.rs"}                                          │
│                                                                                                                  │
│ The 'prompt' must contain at least one valid URL (starting with http:// or https://).                            │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

ℹ ⚠️  Response stopped due to unexpected tool call.
✦ I will read the contents of main.rs.
╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ x  run_shell_command {"command":"cat main.rs"}                                                                   │
│                                                                                                                  │
│ Tool "run_shell_command" not found in registry. Tools must use the exact names that are registered. Did you mean │
│ one of: "web_fetch", "save_memory", "lsp_hover"?                                                                 │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
✦ I will use catenary_codebase_map to explore the project structure and symbols, as read_file is currently
  unavailable in my toolset.
╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ ✓  catenary_codebase_map (catenary MCP Server) {"path":"/tmp/catenary-experiment","include_symbols":true}        │
│                                                                                                                  │
│ main.rs                                                                                                          │
│   tests Module                                                                                                   │
│                                                                                                                  │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
✦ I will retrieve the document symbols for main.rs to better understand its structure.
╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ ✓  lsp_document_symbols (catenary MCP Server) {"file":"/tmp/catenary-experiment/main.rs"}                        │
│                                                                                                                  │
│ main [Function] /tmp/catenary-experiment/main.rs:1:1                                                             │
│ add [Function] /tmp/catenary-experiment/main.rs:5:1                                                              │
│ tests [Module] /tmp/catenary-experiment/main.rs:9:1                                                              │
│ test_add [Function] /tmp/catenary-experiment/main.rs:13:5                                                        │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
✦ I will delegate the task of reading and analyzing main.rs to the codebase_investigator sub-agent, as it may have
  access to the necessary tools for file analysis.

╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ -  Delegate to Agent Delegating to agent 'codebase_investigator'                                                 │
│                                                                                                                  │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

ℹ Request cancelled.
```

**Behavior:** ☐ Used disabled tool anyway / ☐ Said no tool / ☐ Tried catenary / ☐ Other

---

## Test 3: LSP Definition

**Prompt:** `Find the definition of the add function in main.rs`

**Expected:** Should use catenary's lsp_definition or catenary_find_symbol

**Actual Result:**

````

(paste response here)

```

**Tool used:**
**LSP server started?** ☐ Yes / ☐ No (check `catenary monitor`)

---

## Test 4: Shell Blocked

**Prompt:** `Run ls -la to show the files`

**Expected:** Should fail - shell is excluded

**Actual Result:**

```

(paste response here)

```

**Shell blocked?** ☐ Yes / ☐ No

---

## Test 5: Grep/Search (optional)

**Prompt:** `Search for "println" in the codebase`

**Expected:** Should fail (grep disabled) or adapt

**Actual Result:**

```

(paste response here)

```

---

## Summary

### What worked:

- `tools.core` allowlist - successfully blocked `run_shell_command`
- MCP server integration - catenary tools discovered and used
- Model adaptation - pivoted to LSP tools when file tools unavailable

### What didn't work:

- `tools.exclude` - either broken or we had wrong tool names
- Sub-agent delegation - got stuck in "debugging permissions" loop for 1.5+ min

### Unexpected behavior:

- Model tried WebFetch to read local file (wrong tool choice)
- Sub-agent wouldn't admit defeat, kept trying workarounds until cancelled
- Model is resourceful but burns tokens when truly blocked

### Key findings:

1. `tools.exclude` works? ☐ Yes / ☐ Partial / ☒ No (use `tools.core` instead)
2. MCP tools visible? ☒ Yes
3. Model adapts when tools missing? ☒ Yes (but slowly, burns tokens)

---

## Next Steps

- [x] Validate `tools.core` allowlist approach
- [ ] Implement `catenary_read_file` - essential for any coding task
- [ ] Implement `catenary_write_file` - with diagnostics feedback
- [ ] Implement `catenary_edit_file` - with diagnostics feedback
- [ ] Re-run tests with file I/O tools available

---

## Raw Notes

```
- tools.exclude didn't work, tools.core does
- Sub-agents inherit tool restrictions but don't handle them gracefully
- Model will try creative workarounds (WebFetch for local files) before giving up
- Catenary MCP successfully provides LSP tools as alternatives
```

```
````
