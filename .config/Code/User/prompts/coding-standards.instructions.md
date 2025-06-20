---
applyTo: '**'
---

## Coding Standards
- if responding with code that include a class, function or method definition, add doc-string comments.
- review for possible exceptions and add exception handling.
- No abbreviations. Names should not be abbreviated.
- Constants follow ALL_CAPS snake case (otherwise known as Screaming Snake Case).
- Avoid using magic strings. Either parameterize or create constants.
- Dont use magic numbers. Define the meaning as a constant.
- If CLI commands or file paths are generated, ensure compatibility with Windows.

### Code Nesting
- Avoid deeply nested code. Break down logic into smaller functions.
- Use 4 spaces for indentation
- Opening curly braces should be on the same line as the statement.

### Error Handling
- Always catch a specific error instead of a generic one.
- Log the error message and stack trace.

### Terminal commands
- Don't automatically prefix every command with `cd`. Instead, check current working directory is expected before executing commands.
- Don't automatically prefix every script with `chmod +x`. Instead, check if the script is executable before executing it.

### Python
[Python Preferences]()