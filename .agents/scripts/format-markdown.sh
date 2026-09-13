# Read JSON payload from stdin
# Hooks receive input via stdin as JSON
PAYLOAD=$(cat)

# Extract TargetFile from toolCall.args
# In jq, // is the alternative operator, and empty is a built-in filter that emits nothing at all (zero outputs).
TARGET_FILE=$(echo "$PAYLOAD" | jq -r '.toolCall.args.TargetFile // empty')

# Only run if a file was targeted and has a .md extension
# -n checks if the TARGET_FILE string is not empty
if [[ -n "$TARGET_FILE" && "$TARGET_FILE" == *.md ]]; then
  npx prettier -w "$TARGET_FILE" > /dev/null 2>&1
fi

# PostToolUse requires returning an empty JSON object
# Hooks should return output via stdout as JSON
echo "{}"