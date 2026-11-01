---
trigger: glob
description: Markdown formatting and link rules for documents
globs: "*.md"
---

# Markdown Rules

1. **Relative Links**: Always use relative paths and the filename (the last path segment) as the link text when creating or modifying links to files in markdown documents (e.g., `[file.md](./path/to/file.md)` or `[file.md](../path/to/file.md)`).
2. **Mermaid Diagrams**: Quote node labels that contain parentheses, brackets, or special characters (e.g., `A["Label (Detail)"]`), and do not use `;`.
3. **Code Blocks**: Always tag fenced code blocks with a language identifier (`go`, `sql`, `shell`, `yaml`, `json`, `text`) and keep examples copy-pasteable.
