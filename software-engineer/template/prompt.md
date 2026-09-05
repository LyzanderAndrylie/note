# Prompt for Document Generation

## Generate Usecase Sequence Diagram

```text
<task>
Create a sequence diagram in {markdown_path} by checking the whole code in {code_path}.
</task>

<constraint>
1. If there is multiple version of the usecase, create a sequence diagram for each version. This is usually controlled by a feature flag or a different method V1, V2, etc.
2. Specficy the actual SQL affected by the usecase.
</constraint>

<expected_output>
1. Follow the existing format in the markdown.
2. Add a separete section for each version, each with its own mermaid diagram and SQL code blocks.
3. You may add a simple description to explain each version.
4. For very specific operations in the sequence diagram, provide background and explanation in the markdown to describe its specific business logic or implementation details.
    - For example, user state validation, third party integrations, background jobs, etc.
</expected_output>
```

> Note: You can insert the corresponding file path via `Opt + K` (macOS) on Claude Code extension in VS Code.

## Generate Feature Documentation

```text
<task>
Create a feature documentation in {markdown_path} by checking the whole code in {code_path}.
</task>

<expected_output>
1. Follow the existing format in the markdown.
2. Add a separete section for each feature, each with its own feature interaction diagram or flow chart in mermaid to better visualize its functionality.
</expected_output>
```

## Generate Product Architecture Documentation

```text
<task>
Create an end-to-end product architecture documentation in {markdown_path} by exploring and analyzing the codebase in {code_path}.
</task>

<expected_output>
1. Follow the existing format in the markdown.
    - Draw all diagrams using mermaid.
    - For code snippets in the markdown, always provide the expected output in the form of comments.
2. Fill out all sections based on actual implementation found in the codebase.
    - Take your time to understand the codebase.
    - Spawn multiple agents if needed to analyze different parts of the codebase.
</expected_output>
```
