# Replaim Client

English | [简体中文](README.zh-CN.md)

A desktop customer-support email copilot for cross-border e-commerce sellers (Flutter, macOS / Windows).

**Core loop**: receive emails → distill **reply rules** from *historical emails + knowledge base +
custom prompts* → draft English replies strictly from the rules → human edit & confirm, then send
via SMTP → compare the draft with what was actually sent and **auto-refine the reply rules**.
It drafts, never auto-sends; Chinese-language cockpit, English output.

## Features

| Module | Description |
| ------ | ----------- |
| Inbox | Fetch incoming mail via IMAP, thread context, one-click "generate draft from rules" |
| Drafts | Edit, send, or discard drafts; records the original draft / actually-sent version / whether it was edited |
| Rule Library | Rules = the sole basis for drafting. Each rule records its **source** (which emails / which knowledge-base doc / which prompt / which draft edit) and **version history**, stored as YAML |
| Knowledge Base | Import .md/.txt documents (copied into the app directory), track changes by content hash, regenerate rules after changes |
| Learn Center | Incremental learning from historical emails: consumed emails are never reused; processed in chronological order with newer emails winning conflicts, so old mail can't overwrite newer rules |
| Settings | Email (IMAP/SMTP with app password), LLM (custom Base URL / model name / API key, OpenAI-compatible protocol), output language, learning scope, custom prompts |

## Data Storage (all local)

```
<ApplicationSupport>/replaim/
├── config/app_config.yaml    # Non-sensitive config (passwords & API keys live in the system secure storage)
├── rules/rules.yaml          # Rule library: content + sources + version history (core asset)
├── learn_state.yaml          # List of learned emails (Message-ID-level dedup)
├── knowledge_base/           # Knowledge-base document copies + kb_index.yaml (hash versions)
└── drafts/<id>.yaml          # Full record of each draft (original / sent / diff / rule updates)
```

## Development

```bash
# This project uses FVM (substitute your actual version path)
flutter pub get
flutter test          # Unit tests (YAML round-trip / tolerant JSON parsing / rule versions / diff)
flutter run -d macos  # Debug-run on macOS (Windows: flutter run -d windows)
```

On macOS, trust the development signing in Xcode (or allow the app on the first `flutter run`).

## Tech Stack

Flutter 3.47+ · Riverpod (state) · enough_mail (IMAP/SMTP) · dio (LLM HTTP) ·
yaml / yaml_writer (data files, atomic writes) · flutter_secure_storage (secrets) ·
diff_match_patch (draft diffs)

## Out of Scope (explicitly not in v1)

Multiple email accounts, OAuth sign-in (use account + app password instead), PDF/Word knowledge
base (v1 supports .md/.txt only), vector search (rule generation is a low-frequency batch job —
chunks are fed to the LLM directly), auto-sending, team collaboration.
