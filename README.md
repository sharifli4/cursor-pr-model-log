# cursor-pr-model-log

Record Cursor agent lifecycle events locally and turn them into a short **“AI models”** section you can paste into a pull request (or pass to `gh pr create`).

## What you get

- **Hooks** (`.cursor/hooks.json`) run a small script on:
  - `beforeSubmitPrompt`
  - `stop`
  - `afterAgentResponse`
- Each run appends one JSON line to **`.cursor/model-usage.jsonl`** in the workspace (under each path in `workspace_roots`, or `./.cursor/` if that list is empty).
- **Scripts** build markdown that lists models and how many times each was recorded, for PR descriptions.

## Requirements

- [Cursor](https://cursor.com) with **Hooks** enabled (see Cursor settings → Hooks).
- **`bash`**
- **`jq`** (for logging and for the PR helpers). If `jq` is missing, the hook exits quietly without writing.

## Quick install (recommended)

From this repo, install into any target project:

```bash
./scripts/install.sh /path/to/target-repo
```

This command:

- copies the required hook and helper scripts
- creates or merges `.cursor/hooks.json` safely (no duplicate hook entries)
- adds `.cursor/model-usage.jsonl` to `.gitignore` if missing
- marks scripts executable

After install, restart Cursor (or reload hooks).

## Manual install

If you prefer manual setup, copy:

- `.cursor/hooks/log-model-usage.sh`
- `scripts/models-for-pr.sh`
- `scripts/pr-body-with-models.sh`
- `scripts/gh-pr-create-with-models.sh`

Then add the hook command to `beforeSubmitPrompt`, `stop`, and `afterAgentResponse` in `.cursor/hooks.json`.

## Log format

Each line in `.cursor/model-usage.jsonl` is JSON with roughly:

| Field | Meaning |
|--------|---------|
| `ts` | UTC timestamp |
| `event` | Hook name (e.g. `stop`) |
| `model` | Model id **if** Cursor includes it in the hook payload (see below) |
| `conversation_id` / `generation_id` | When present in the payload |

The hook tries several possible keys for the model: `model`, `modelName`, `model_id`, `selectedModel`, `activeModel`, `providerModel`, `modelKey`, `agentModel`.

## Important: model id in payloads

Cursor does **not** always send a model identifier in hook stdin. You may see many events but **no model names** until Cursor exposes that field (or uses one of the keys above). The PR section will still report how many events were logged and point at the log path.

## Generate a PR section

From the repo root:

```bash
./scripts/models-for-pr.sh
```

Optional custom log path:

```bash
./scripts/models-for-pr.sh /path/to/model-usage.jsonl
```

## GitHub CLI: easiest PR flow

Write your main PR body to `body.md`, then run:

```bash
./scripts/gh-pr-create-with-models.sh --title "Your title" --body body.md
```

Pass extra `gh pr create` flags as needed:

```bash
./scripts/gh-pr-create-with-models.sh --title "Your title" --body body.md --base main --draft
```

## GitHub CLI: manual PR flow

If you want full control over `gh` invocation:

```bash
gh pr create \
  --title "Your title" \
  --body-file <(./scripts/pr-body-with-models.sh body.md)
```

To print only the models section (no preamble file):

```bash
./scripts/pr-body-with-models.sh
```

## If a hook event fails on your Cursor version

If `afterAgentResponse` is unsupported or errors, remove that block from `.cursor/hooks.json` and keep `beforeSubmitPrompt` and `stop`.

## Upstream

Repository: [github.com/sharifli4/cursor-pr-model-log](https://github.com/sharifli4/cursor-pr-model-log)

## License

[MIT](LICENSE)
