# Claude Code Integration Experiment Findings

**Date:** 2026-02-06
**CLI:** Claude Code
**Model:** Sonnet 4.5

---

## Working Settings

Location: `.claude/settings.json` (workspace) or `~/.claude/settings.json` (user)

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

**Key insight:** Must deny `Task` to prevent sub-agent escape hatch.

---

## Test 1: Tool Discovery

**Prompt:** `What tools do you have available?`

**Result:**
```
Direct Tools:
- Task Management (TaskCreate, TaskGet, etc.)
- Planning (EnterPlanMode, ExitPlanMode)
- Web (WebSearch, WebFetch)
- NotebookEdit, Skill, ToolSearch

Deferred Tools (via ToolSearch):
- Catenary LSP Tools (definition, find_references, hover, etc.)

Sub-Agent Tools:
- Bash, Read/Write/Edit, Glob/Grep (via Task delegation)
```

**Observation:** Claude correctly identified catenary tools. Also revealed sub-agents have full tool access - this was the loophole we needed to close.

---

## Test 2: Read File (without Task deny)

**Prompt:** `Read the file main.rs`

**Result:**
```
Bash(Read main.rs file) Haiku 4.5
⎿  Done (0 tool uses · 989 tokens · 2s)

The main.rs file doesn't exist... The directory appears to be empty.
```

**Behavior:** Delegated to Bash sub-agent to bypass Read deny. Sub-agent either:
- Couldn't actually read (deny propagated silently)
- Or ran in wrong directory

**Finding:** Denying Read/Bash on main agent insufficient - sub-agents provide escape hatch.

---

## Test 3: Read File (with Task deny)

**Prompt:** `Read the file main.rs`

**Result:**
```
❯ Read the file main.rs

● I'll read the main.rs file for you.

● Skill(read)
  ⎿  Initializing…
  ⎿  Error: Unknown skill: read

● I notice that the standard file reading tools don't appear to be available in this environment. Let me try using
  the LSP document symbols tool to show you the structure of main.rs:

● plugin:catenary:catenary - document_symbols (MCP)(file: "main.rs")
  ⎿  main [Function] /tmp/catenary-experiment/main.rs:1:1
     add [Function] /tmp/catenary-experiment/main.rs:5:1
     tests [Module] /tmp/catenary-experiment/main.rs:9:1
     test_add [Function] /tmp/catenary-experiment/main.rs:13:5

● I can see the structure of main.rs which contains:
  - main function at line 1
  - add function at line 5
  - tests module at line 9 with a test_add function inside

  However, I don't have access to the standard file reading tools in this environment to show you the full file
  contents. The available tools are primarily LSP-based navigation tools. Would you like me to use the LSP hover tool
   to get more details about each function, or do you need the complete source code?

✻ Sautéed for 54s
```

**Behavior:**
1. Tried Skill(read) - failed
2. No Read/Bash/Task available - all blocked
3. Adapted to catenary `document_symbols`
4. Admitted limitations gracefully
5. Offered LSP-based alternatives

**Finding:** ✓ Deny rules work when `Task` is also denied. Model adapts gracefully.

---

## Summary

### What worked:

- `permissions.deny` with explicit tool list
- Blocking `Task` to prevent sub-agent escape
- MCP server integration - catenary tools discovered and used
- Model graceful degradation - admits limitations, offers alternatives

### What didn't work:

- Denying only Read/Bash - sub-agents bypass restrictions
- Skill(read) - no such built-in skill

### Key findings:

1. **Must deny `Task`** to prevent sub-agent escape hatch
2. **MCP tools visible via ToolSearch** - deferred loading works
3. **Model adapts gracefully** - uses available tools, admits limitations
4. **Claude more graceful than Gemini** - admits defeat faster, clearer communication

### Behavioral notes:

- Claude tried Skill before giving up (creative workaround attempt)
- Sub-agents (Haiku 4.5) used for delegation when Task allowed
- Model clearly communicates what it can/cannot do
- Offers alternatives within constraints

---

## Comparison: Claude vs Gemini

| Aspect | Gemini CLI | Claude Code |
|--------|-----------|-------------|
| Restriction method | `tools.core` (allowlist) | `permissions.deny` + block `Task` |
| Config location | `.gemini/settings.json` | `.claude/settings.json` |
| MCP tools work | ✓ | ✓ |
| Sub-agent escape | N/A (no sub-agents) | Must deny `Task` |
| Admits defeat | Slowly (burns tokens) | Quickly and gracefully |
| Workaround attempts | WebFetch, shell, sub-agent | Skill, sub-agent |

---

## Next Steps

- [x] Validate deny rules block main agent
- [x] Validate deny `Task` blocks sub-agent escape
- [x] Validate MCP tools work as replacement
- [ ] Implement `catenary_read_file`
- [ ] Implement `catenary_write_file`
- [ ] Implement `catenary_edit_file`
- [ ] Re-test full workflow with file I/O tools
