# Plan Mode Extension

Read-only exploration mode for safe code analysis.

## Features

- **Read-only tools**: Restricts available tools to read, bash, grep, find, ls, ask-user
- **Bash allowlist**: Only read-only bash commands are allowed
- **Plan extraction**: Extracts ordered tasks from `## Tasks (Ordered)` sections
- **Progress tracking**: Widget shows completion status during execution
- **[DONE:n] markers**: Explicit step completion tracking
- **Session persistence**: State survives session resume

## Commands

- `/plan` - Toggle plan mode
- `/todos` - Show current plan progress
- `Ctrl+Alt+P` - Toggle plan mode (shortcut)

## Usage

1. Enable plan mode with `/plan` or `--plan` flag
2. Ask the agent to analyze code and create a plan
3. The agent should output a structured plan using these sections:

```
## Goal
One concise objective

## Tasks (Ordered)
1. First step description
2. Second step description
3. Third step description

## Relevant Files
- path/to/file1
- path/to/file2
```

4. Choose "Execute the plan" when prompted
5. During execution, the agent marks each step complete immediately with `[DONE:n]` as it is finished (not batched at the end)
6. Progress widget updates incrementally as `[DONE:n]` tags are emitted

## How It Works

### Plan Mode (Read-Only)
- Only read-only tools available
- Bash commands filtered through allowlist
- Agent asks clarifying questions first when needed, then creates the plan without making changes

### Execution Mode
- Restores the tool set that was active before plan mode was enabled
- Agent executes steps in order
- `[DONE:n]` markers track completion
- Widget shows progress

### Command Allowlist

Safe commands (allowed):
- File inspection: `cat`, `head`, `tail`, `less`, `more`
- Search: `grep`, `find`, `rg`, `fd`
- Directory: `ls`, `pwd`, `tree`
- Git read: `git status`, `git log`, `git diff`, `git branch`
- Package info: `npm list`, `npm outdated`, `yarn info`
- System info: `uname`, `whoami`, `date`, `uptime`

Blocked commands:
- File modification: `rm`, `mv`, `cp`, `mkdir`, `touch`
- Git write: `git add`, `git commit`, `git push`
- Package install: `npm install`, `yarn add`, `pip install`
- System: `sudo`, `kill`, `reboot`
- Editors: `vim`, `nano`, `code`
