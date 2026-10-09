# Changelog

All notable changes to Replaim are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); versions follow the git tags.

> Note: the first tag is `1.0.0` (without the `v` prefix); later tags use `v*`.
> Existing tags are left untouched to avoid rewriting published history.

## English

### [1.1.0] – 2026-10-09

#### Fixed

- Outlook / Hotmail / Live (OAuth2) accounts could fail to load mail into the inbox;
  token handling around sign-in and refresh was reworked (two rounds of fixes).
- Version metadata bumped to 1.1.0.

### [v1.0.1] – 2026-10-08

#### Added

- Release workflow (`.github/workflows/release.yml`): pushing a `v*` tag (or a manual
  dispatch) builds the macOS DMG and the Windows portable zip and attaches both to the
  GitHub Release. First release with downloadable binaries.

### [1.0.0] – 2026-10-08

#### Added — initial release

- **Spaces**: one space = reply rules + knowledge base + multiple email accounts
  (per shop/brand); per-account receive (IMAP) / send (SMTP) toggles.
- **Inbox**: chat-style aggregation across all receiving accounts, thread context,
  one-click "draft from rules"; forward detection (mail forwarded from an unconfigured
  address gets the original recipient auto-CC'd); offline cache with UID-based
  incremental sync.
- **Rule library**: rules are the sole drafting basis, each with sources (which emails /
  KB docs / prompts / draft edits) and version history, stored as local YAML.
- **Knowledge base**: import .md/.txt, hash-tracked changes, rule regeneration.
- **Learn Center**: incremental learning from historical mail (Message-ID dedup,
  chronological so newer mail wins conflicts).
- **Drafts**: edit → confirm → SMTP send; original vs. actually-sent diff is fed back
  to auto-refine the rules; chat-style AI revision panel.
- **LLM profiles**: multiple OpenAI-compatible endpoints (Base URL / model / API key)
  assigned per space; configurable max_tokens.
- **Email providers**: Gmail (app password), QQ / 163 / 126 (authorization codes),
  Outlook / Hotmail / Live via OAuth2 (XOAUTH2, auto token renewal).
- **Local-first storage**: plain YAML under the app-support dir; passwords, keys and
  tokens in the system keychain; dev/prod build flavors fully isolated.

[1.1.0]: https://github.com/zhixiakj/replaim/compare/v1.0.1...v1.1.0
[v1.0.1]: https://github.com/zhixiakj/replaim/compare/1.0.0...v1.0.1
[1.0.0]: https://github.com/zhixiakj/replaim/releases/tag/1.0.0

---

## 中文

### [1.1.0] – 2026-10-09

#### 修复

- Outlook / Hotmail / Live（OAuth2）账号收件箱加载邮件失败的问题；重做了登录与
  令牌刷新相关的处理（两轮修复）。
- 版本号升至 1.1.0。

### [v1.0.1] – 2026-10-08

#### 新增

- 发布工作流（`.github/workflows/release.yml`）：推送 `v*` tag（或手动触发）自动
  构建 macOS DMG 与 Windows 便携 zip 并挂到 GitHub Release。首个带可下载安装包的版本。

### [1.0.0] – 2026-10-08

#### 新增 —— 首个版本

- **空间**：一个空间 = 回复规则 + 知识库 + 若干邮箱账号（按店铺/品牌划分）；
  账号级收信（IMAP）/ 发信（SMTP）开关。
- **收件箱**：跨账号聊天式聚合、线程上下文、一键「依据规则起草」；转发识别
  （发给未配置地址再转发进来的邮件，回信自动抄送原始收件人）；离线缓存 +
  UID 增量同步。
- **规则库**：规则 = 唯一起草依据，记录来源（哪些邮件/知识库文档/Prompt/草稿修改）
  与版本历史，本地 YAML 保存。
- **知识库**：导入 .md/.txt，按内容 hash 跟踪变更，可重新生成规则。
- **学习中心**：历史邮件增量学习（Message-ID 去重，按时间升序、新邮件优先）。
- **草稿**：编辑 → 确认 → SMTP 发送；「原始稿 vs 实发稿」差异回流自动优化规则；
  对话式 AI 改稿面板。
- **大模型 Profiles**：多个 OpenAI 兼容端点（Base URL / 模型 / API Key）分配给各
  空间；max_tokens 可配置。
- **邮箱服务商**：Gmail（应用专用密码）、QQ / 163 / 126（授权码）、
  Outlook / Hotmail / Live 走 OAuth2（XOAUTH2，令牌自动续期）。
- **本地化存储**：数据全部为本机 YAML；密码、Key、令牌进系统钥匙串；
  开发版/正式版构建完全隔离。
