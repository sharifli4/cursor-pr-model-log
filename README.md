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

## Install in a repo

1. Copy into your project (or use this repo as a template):
   - `.cursor/hooks.json`
   - `.cursor/hooks/log-model-usage.sh`
   - `scripts/models-for-pr.sh`
   - `scripts/pr-body-with-models.sh`
2. Ensure the hook is executable:

   ```bash
   chmod +x .cursor/hooks/log-model-usage.sh scripts/models-for-pr.sh scripts/pr-body-with-models.sh
   ```

3. Add a line to `.gitignore` if you do not want logs in git:

   ```
   .cursor/model-usage.jsonl
   ```

4. Restart Cursor (or reload hooks) so `hooks.json` is picked up.

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

## GitHub CLI: open a PR with your notes + models section

Write your main body to a file (e.g. `body.md`), then:

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

This project is released into the public domain under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) unless you add your own `LICENSE` file.

</think>
Adding a minimal CC0 `LICENSE` file would be extra — the README references CC0 but no LICENSE exists. Removing the License section or adding a one-line CC0 file is cleaner. Prefer removing the License section to avoid claiming a license we didn't add.

<｜tool▁calls▁begin｜><｜tool▁call▁begin｜>
StrReplace