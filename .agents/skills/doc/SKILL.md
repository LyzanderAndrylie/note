---
name: doc
description: >-
  Create, update, check, simplify, and refresh technical documentation for libraries,
  concepts, and products using standardized templates. Use when the user invokes /doc
  or asks to write, update, audit, condense, or refresh documentation in the repository.
---

# Documentation Skill (`/doc`)

Manage technical documentation across the repository using the canonical templates in [`templates`](./templates/).

## Command Reference

```text
/doc create <lib|concept|product> <context>            - write a new doc
/doc update <doc path or topic> <what changed>         - refresh a doc
/doc check [doc path | type]                           - report broken links, stale claims, incorrect and inconsistent facts
/doc simplify <doc path>                               - the same facts in fewer words, bullets first
/doc refresh <doc paths | folder | type | topic | all> - update, check, and simplify each doc in turn
```

---

## Templates & Default Locations

Always read the template file before creating, restructuring, or simplifying a document of that type:

| Type      | Template                               | Default Output Path                           | Example                                                  |
| :-------- | :------------------------------------- | :-------------------------------------------- | :------------------------------------------------------- |
| `lib`     | [`lib.md`](./templates/lib.md)         | `software-engineer/lib/<category>/<name>.md`  | `software-engineer/lib/go/retry.md`                      |
| `concept` | [`concept.md`](./templates/concept.md) | `software-engineer/concept/<topic>/<name>.md` | `software-engineer/concept/postgres/lock.md`             |
| `product` | [`product.md`](./templates/product.md) | `software-engineer/product/<name>/<name>.md`  | `software-engineer/product/phonenumbers/phonenumbers.md` |

> [!NOTE]
> If the user provides an explicit file path in `<context>` (even outside `software-engineer/`, such as `english/concepts/...` or `invest/...`), write to that exact path.

---

## Workflows

### 1. `/doc create <lib|concept|product> <context>`

Write a new document from the matching template.

1. **Load Template**: Read [`<type>.md`](./templates/) and follow its section structure and inline `<!-- ... -->` instructions.
2. **Gather Facts**:
   - **`lib` / `product`**: Inspect the target codebase or repository in `<context>`. Identify entry points, package/module paths, core abstractions, public APIs, configuration, data models, error handling, git commit hash, and version. For large codebases, spawn parallel research subagents to analyze subsystems before synthesizing.
   - **`concept`**: Check existing notes in the same topic folder (e.g., [`concept`](../../../software-engineer/concept/)) so terminology and cross-links stay consistent.
3. **Draft & Finalize**:
   - Fill out all sections grounded in the actual codebase or technical references.
   - Strip all template HTML comments (`<!-- ... -->`) and ensure zero `{placeholder}` tokens remain.

---

### 2. `/doc update <doc path or topic> <what changed>`

Refresh an existing document to reflect code changes, new scope, or updated knowledge.

1. **Resolve Target**: Locate the document by file path or by searching filenames and headings matching `<topic>`.
2. **Determine Type & Template**: Identify whether the doc is a `lib`, `concept`, or `product` doc and read its template in [`templates`](./templates/).
3. **Analyze Changes**:
   - If `<what changed>` references code/commits, inspect the relevant source files, diffs, or git history.
   - If `<what changed>` describes new concepts, sections, or corrections, research the affected areas.
4. **Apply Updates**:
   - Update affected sections, tables, code examples, file references, and Mermaid diagrams.
   - If modified sections deviate from the current template conventions, bring them into alignment with the template.
   - Update the `Last Updated` / `Document Last Updated Date` metadata field (and `Product Version` or `Repositories` commit hash if applicable).

---

### 3. `/doc check [doc path | type]`

Audit documentation and report issues without modifying the files (unless explicitly asked to fix them).

1. **Resolve Scope**:
   - Specific file path → audit that file.
   - Type (`lib`, `concept`, `product`) → audit all docs of that type.
   - Topic or folder → audit all `.md` files in that directory.
   - Omitted → audit all docs under `software-engineer/`.
2. **Run Checks**:
   - **Broken Links**:
     - Verify every markdown link `[text](path)` resolves to an existing file on disk relative to the document's directory.
     - Verify `#heading-anchor` fragments match actual headings in the target file.
     - Flag any root-relative (`/path/...`), `file://`, or non-filename-labeled file links that violate [`links.md`](../../rules/links.md).
   - **Stale Claims**:
     - For `lib` and `product` docs, check referenced source paths, package names, function/type signatures, CLI flags, config defaults, versions, and commit hashes against the codebase.
     - Flag deprecated APIs, renamed files, or outdated version numbers.
   - **Incorrect Facts**:
     - Verify technical statements, formulas, complexity claims, protocol flows, SQL/code syntax, and commented `Output:` values.
   - **Inconsistent Facts**:
     - Check internal consistency across metadata tables, prose, code snippets, and Mermaid diagrams within the same document.
     - Check cross-document consistency across related notes in the same topic folder.
   - **Template & Formatting Hygiene**:
     - Check for leftover `{placeholder}` tokens, unremoved `<!-- ... -->` template comments, or invalid Mermaid syntax (e.g., `;` or unquoted labels containing `()`, `[]`, or `{}`).
3. **Report Findings**:
   - Output a concise report grouped by document and category: **Broken Links**, **Stale Claims**, **Incorrect Facts**, **Inconsistencies**, and **Template/Formatting Issues**.
   - Cite exact `file:line` locations and provide the concrete fix for each finding.

---

### 4. `/doc simplify <doc path>`

Rewrite the document to convey **the exact same facts in fewer words, bullets first**.

1. **Read & Classify**: Read `<doc path>` and its matching template in [`templates`](./templates/).
2. **Preserve Every Fact**:
   - Keep 100% of technical facts, numbers, formulas, config keys, defaults, edge cases, limits, trade-offs, gotchas, tables, code snippets, links, and valid Mermaid diagrams.
   - Never delete a factual claim to save words.
3. **Apply Simplification Rules**:
   - **Bullets First**: Replace multi-sentence prose paragraphs with flat, high-signal bullet points (`- **Key term**: concise fact`).
   - **Lead with the Takeaway**: Keep section openings to 1–2 direct sentences, then move immediately to bullets, tables, code blocks, or diagrams.
   - **Use Tables for Comparisons & Options**: Convert repetitive comparative prose into compact markdown tables.
   - **Eliminate Filler & Redundancy**: Cut throat-clearing phrases, conversational transitions, and prose that merely repeats what an adjacent table, code block, or Mermaid diagram already shows.
   - **Align Structure with Template**: If the document uses verbose legacy headings (e.g., long narrative sections in a `concept` or `lib` doc), reshape it to follow [`concept.md`](./templates/concept.md) or [`lib.md`](./templates/lib.md) cleanly.

---

### 5. `/doc refresh <doc paths | folder | type | topic | all>`

Run **`update` → `check` → `simplify`** on each target document in turn.

1. **Resolve Target List**:
   - Expand `<doc paths | folder | type | topic | all>` into an ordered list of markdown files.
2. **Process Each Document Sequentially**:
   For each document in the list, execute all three stages before moving to the next document:
   - **Stage 1 (`update`)**: Refresh stale content against the codebase/current context, align structure with its template in [`templates`](./templates/), and update `Last Updated` metadata where present.
   - **Stage 2 (`check`)**: Verify all relative links, anchors, code paths, technical claims, and internal/cross-doc consistency. Fix every broken link, stale reference, or inconsistency directly in the file.
   - **Stage 3 (`simplify`)**: Condense prose into bullets-first, high-density technical notes while preserving all facts, tables, code blocks, and diagrams.
3. **Summarize**:
   - After processing all target files, report a brief per-file summary of what was updated, fixed, and simplified.
