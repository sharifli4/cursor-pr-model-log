# cursor-pr-model-log

`cursor-pr-model-log` makes Cursor usage metadata practical in real Git workflows.

It records Cursor hook events to a local JSONL log and provides helper commands to automatically append a model-usage section to:

- commit bodies
- pull request descriptions

This avoids manual copy/paste and keeps model usage details attached to code review artifacts.

## Why this exists

Teams often want lightweight attribution for AI-assisted work, but Cursor does not always expose a stable model identifier in every hook payload. This project is designed to:

- capture what Cursor provides today
- summarize model usage when model fields are present
- degrade safely when model fields are missing

## How it works

### 1) Hook logging

The hook script (`.cursor/hooks/log-model-usage.sh`) runs on:

- `beforeSubmitPrompt`
- `stop`
- `afterAgentResponse`

Each execution appends one JSON line to `.cursor/model-usage.jsonl`.

### 2) Summary generation

`scripts/models-for-pr.sh` reads the JSONL log and outputs a markdown section:

- model names + counts when model values exist
- a clear fallback message when no model ids were present

### 3) Git workflow helpers

- `scripts/git-commit-with-models.sh`: creates commits with model usage appended to commit body
- `scripts/gh-pr-create-with-models.sh`: creates PRs with model usage appended to PR body

### 4) Cursor rule

An always-on rule (`.cursor/rules/commit-pr-model-helpers.mdc`) instructs Cursor to prefer these helpers when the user asks to create commits or PRs.

## Requirements

- [Cursor](https://cursor.com) with Hooks enabled
- `bash`
- `jq`
- `git`
- `gh` (only for PR helper flow)

If `jq` is missing, logging/summarization cannot run.

## Quick start

Install into a target repository:

```bash
./scripts/install.sh /path/to/target-repo
```

Installer actions:

- copies hook and helper scripts
- creates or merges `.cursor/hooks.json` without duplicate entries
- installs `.cursor/rules/commit-pr-model-helpers.mdc`
- adds `.cursor/model-usage.jsonl` to `.gitignore` if missing
- marks scripts executable

Then restart Cursor (or reload hooks).

## Daily usage

### Create commit with model section

```bash
./scripts/git-commit-with-models.sh --subject "feat: add API endpoint" --body body.md
```

Subject only:

```bash
./scripts/git-commit-with-models.sh --subject "feat: add API endpoint"
```

### Create PR with model section

```bash
./scripts/gh-pr-create-with-models.sh --title "Add API endpoint" --body body.md
```

With extra `gh pr create` flags:

```bash
./scripts/gh-pr-create-with-models.sh --title "Add API endpoint" --body body.md --base main --draft
```

### Generate section manually

```bash
./scripts/models-for-pr.sh
```

Custom log file path:

```bash
./scripts/models-for-pr.sh /path/to/model-usage.jsonl
```

## Output format

The log file `.cursor/model-usage.jsonl` stores one JSON object per event.

Current fields:

- `ts`: UTC timestamp
- `event`: hook event name
- `model`: model identifier when present
- `conversation_id`: optional
- `generation_id`: optional

Model extraction checks these keys in payloads:

- `model`
- `modelName`
- `model_id`
- `selectedModel`
- `activeModel`
- `providerModel`
- `modelKey`
- `agentModel`

## Known limitation

Cursor does not always include model id in hook payloads. When this happens, summaries show event counts and explain that model ids were not available.

This is expected behavior, not a failure in this tool.

## Troubleshooting

- **No log file appears**
  - Confirm Cursor hooks are enabled.
  - Restart Cursor after installation.
  - Confirm `jq` is installed and available in PATH.
- **No model names in output**
  - Hook events are being captured, but your Cursor payloads do not include model fields.
- **`afterAgentResponse` fails**
  - Remove that event from `.cursor/hooks.json` and keep `beforeSubmitPrompt` + `stop`.

## Repository

[github.com/sharifli4/cursor-pr-model-log](https://github.com/sharifli4/cursor-pr-model-log)

## License

[MIT](LICENSE)
