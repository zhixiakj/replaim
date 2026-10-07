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
| Spaces | A space = one set of reply rules + knowledge base + multiple email accounts (one per shop/brand). Each account can be toggled for **receiving (IMAP)** and **sending (SMTP)** independently; replies are sent from the receiving account by default, falling back to the space's default send account |
| Inbox | Aggregates mail from every receiving account in the space (merged by time); IMAP fetch, thread context, one-click "generate draft from rules"; **forward detection**: mail sent to an unconfigured address (e.g. support@) and forwarded to a configured account is detected, and the original recipient is CC'd on the reply |
| Drafts | Edit, send, or discard drafts; records the original draft / actually-sent version / whether it was edited; CC list adjustable before sending |
| Rule Library | Rules = the sole basis for drafting. Each rule records its **source** (which emails / which knowledge-base doc / which prompt / which draft edit) and **version history**, stored as YAML (partitioned per space) |
| Knowledge Base | Import .md/.txt documents (copied into the app directory), track changes by content hash, regenerate rules after changes (isolated per space) |
| Learn Center | Incremental learning from historical emails (across all accounts in the space): consumed emails are never reused; processed in chronological order with newer emails winning conflicts, so old mail can't overwrite newer rules |
| Settings | LLM profiles (multiple, OpenAI-compatible Base URL / model name / API key, assigned to spaces), custom prompts |

## Data Storage (all local)

```
<ApplicationSupport>/replaim/
├── app_state.yaml            # Global state (current space ID)
├── llm_profiles.yaml         # Global LLM profile registry (non-sensitive fields)
└── spaces/<spaceId>/         # One partition per space
    ├── space.yaml            # Space metadata + account list + learning prefs
    ├── rules/rules.yaml      # This space's rule library: content + sources + version history (core asset)
    ├── learn_state.yaml      # List of learned emails (Message-ID-level dedup)
    ├── knowledge_base/       # This space's knowledge-base copies + kb_index.yaml (hash versions)
    └── drafts/<id>.yaml      # Full record of each draft (original / sent / diff / rule updates)
```

Passwords and API keys live in the system secure storage (flutter_secure_storage),
namespaced by account / profile ID. The legacy single-space layout is migrated
automatically into a "default space" on first launch; on a fresh install the
user creates the first space themselves.

## Development

```bash
# This project uses FVM (substitute your actual version path)
flutter pub get
flutter test                        # Unit tests (YAML round-trip / tolerant JSON parsing / rule versions / diff)
flutter run -d macos --flavor dev   # Always develop with --flavor dev
```

On macOS, trust the development signing in Xcode (or allow the app on the first `flutter run`).

### Dev / production isolation (developing and daily-driving on the same machine)

Dev builds use `--flavor dev`; production builds do not. Data, secrets and build
artifacts are fully isolated, and both apps can run side by side:

| | dev (development) | production (daily use) |
|---|---|---|
| Command | `flutter run/build ... --flavor dev` | `flutter build macos --release` |
| App name / bundle ID | Replaim Dev (DEV badge in UI) / `com.replaim.replaim.dev` | replaim / `com.replaim.replaim` |
| Data | Sandbox container & data dir split by bundle ID — mutually invisible | same |
| Keychain | Separate service (`..._dev`); passwords / API keys never touch prod | default service |
| Build output | `build/macos/Build/Products/<Mode>-dev/` | `build/macos/Build/Products/<Mode>/` |

- Install / update the production app: `flutter build macos --release`, then copy
  `build/macos/Build/Products/Release/replaim.app` to `/Applications` (the only
  place an "overwrite" ever happens).
- The dev app needs its own test mailbox credentials and LLM keys; adding/removing
  spaces or wiping data in dev never affects production.
- Toolchain isolation: the Flutter SDK is pinned by `.fvmrc` (per-project via FVM);
  Homebrew lives in `/opt/homebrew` (userland) — neither shadows the system setup.
- Windows has no flavor configuration yet; apply the same approach (distinct
  product name + `FLUTTER_APP_FLAVOR`) when it is supported.

## Tech Stack

Flutter 3.47+ · Riverpod (state) · enough_mail (IMAP/SMTP) · dio (LLM HTTP) ·
yaml / yaml_writer (data files, atomic writes) · flutter_secure_storage (secrets) ·
diff_match_patch (draft diffs)

## Out of Scope (explicitly not in v1)

OAuth sign-in (use account + app password instead), PDF/Word knowledge
base (v1 supports .md/.txt only), vector search (rule generation is a low-frequency batch job —
chunks are fed to the LLM directly), auto-sending, team collaboration, parsing
embedded-.eml forwards (server alias/redirect forwarding is already supported).
