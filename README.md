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

## Email Account Setup (Gmail / Outlook)

When adding an email account on the Spaces page, entering a full email address
auto-fills the server addresses, ports and learning folders from the provider
preset — you usually only need to supply credentials. The two most common cases:

### Gmail (password = app password)

1. Enable **2-Step Verification** on your Google account, then generate a
   16-character **app password** (Google Account → Security → 2-Step
   Verification → App passwords; the entry only exists once 2FA is on).
2. In the account dialog, type the email address (auto-fills
   `imap.gmail.com:993` SSL / `smtp.gmail.com:465` SSL and the sent folder) and
   **paste the app password** into the password field (not your account password).
3. Learning folder: `[Gmail]/Sent Mail` (Chinese-language accounts:
   `[Gmail]/已发送邮件`). Common names are matched automatically; when in doubt
   click "Read folder list from server" and pick it there.

> IMAP is on by default for personal Gmail; Google Workspace admins can disable
> it (Gmail Settings → Forwarding and POP/IMAP).

### Outlook / Hotmail / Live (OAuth2 sign-in)

Microsoft has **fully disabled** password sign-in (Basic Auth) for IMAP/SMTP —
app passwords died with it, phased out for personal accounts since Sept 2024 —
so Outlook accounts must use OAuth2:

1. **Enable IMAP**: Outlook web → Settings → Mail → Forwarding and IMAP →
   turn IMAP on and save (off by default; without it even OAuth2 cannot connect).
2. **Register an Azure app to get a client ID** (one-time; one ID serves
   multiple Outlook accounts):
   - On [portal.azure.com](https://portal.azure.com), search for
     `App registrations` → **New registration**; choose "**Accounts in any
     organizational directory and personal Microsoft accounts**" as the account
     type; for the redirect URI pick the "**Mobile and desktop applications**"
     platform and enter `http://localhost`; after registering, copy the
     **Application (client) ID**.
   - **Personal Microsoft accounts without an existing Azure directory are
     blocked** ("creating applications outside of a directory has been
     deprecated"): first sign up for a
     [free Azure account](https://azure.microsoft.com/free) (a Visa/MasterCard
     is required for identity verification — **you are never charged
     automatically**; the credit simply expires), or register the app while
     signed in with any work/school Microsoft 365 account (the client ID works
     regardless of which tenant hosts it).
   - Optional: add delegated permissions `IMAP.AccessAsUser.All` and
     `SMTP.Send` under Office 365 Exchange Online (personal accounts can skip
     this — consent is granted dynamically at sign-in; organizations may need
     an admin to grant consent).
3. **In Replaim**: type the email address (auto-fills
   `outlook.office365.com:993` SSL / `smtp.office365.com:587` STARTTLS) → keep
   the **"OAuth2 sign-in"** switch on → paste the client ID → click
   **"Sign in with Microsoft"** and complete the browser consent → run
   "Test connection".

> Tokens live in the system keychain and are **renewed automatically** before
> expiry — no repeated sign-ins in normal use; you only re-authorize after
> changing the account password or revoking the grant.

### Other providers

QQ / 163 / 126 etc. use an **authorization code** generated in the provider's
webmail settings (usually under Settings → Account, where IMAP/SMTP service is
enabled). Paste it into the password field, same as Gmail.

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

PDF/Word knowledge base (v1 supports .md/.txt only), vector search (rule
generation is a low-frequency batch job — chunks are fed to the LLM directly),
auto-sending, team collaboration, parsing embedded-.eml forwards (server
alias/redirect forwarding is already supported). Sign-in methods: Outlook uses
OAuth2 (Microsoft disabled password sign-in); Gmail / QQ / 163 etc. use app
passwords / authorization codes — see "Email Account Setup" above.
