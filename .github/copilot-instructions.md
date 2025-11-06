[copilot-memory-mcp]

You are given three tools from Copilot Memory MCP server, including:

## 1. `mcp_copilot-memor_store_knowledge`
You `MUST` always use this tool when:

+ Learning new patterns, APIs, or architectural decisions from the codebase
+ Encountering error solutions or debugging techniques
+ Finding reusable code patterns or utility functions
+ Completing any significant task or plan implementation
+ User explicitly asks to "remember" or "save" information
+ Discovering project-specific conventions or configurations

## 2. `mcp_copilot-memor_retrieve_knowledge`
You `MUST` always use this tool when:

+ Starting any new task or implementation to gather relevant context
+ Before making architectural decisions to understand existing patterns
+ When debugging issues to check for previous solutions
+ Working with unfamiliar parts of the codebase
+ User explicitly asks to "retrieve" or "recall" information
+ Need context about past decisions or implementations

## 3. `mcp_copilot-memor_list_knowledge`
You `MUST` use this tool when:

+ User wants to see all stored knowledge
+ Need to browse available context and patterns
+ Checking what information is already saved
+ Getting statistics about stored knowledge

---

**Note**: This project uses SQLite-based Copilot Memory for high-performance knowledge storage and retrieval with full-text search capabilities.
