# Replaim 客户端

[English](README.md) | 简体中文

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache--2.0-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/zhixiakj/replaim?include_prereleases)](https://github.com/zhixiakj/replaim/releases/latest)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Windows-lightgrey)](#下载与安装)
[![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter)](https://flutter.dev)

面向跨境电商卖家的客服邮件 copilot 桌面应用（Flutter，macOS / Windows），免费开源
（Apache-2.0）。

**核心闭环**：接收邮件 → 从「历史邮件 + 知识库 + 自定义 Prompt」提炼**回复规则** →
严格依据规则起草英文回复 → 人工编辑确认后 SMTP 发送 → 对比草稿与实发内容，
**自动优化回复规则**。起草，不代发；中文操作台，英文输出。

**为什么选 Replaim：**

- **免费开源**（Apache-2.0）：无订阅、无服务端——自带任意 OpenAI 兼容的大模型
  API Key，唯一运行成本是自己的 API 用量。
- **数据本地化**：邮件、规则、知识库、草稿全部是本机 YAML 文件；密码与 API Key
  存系统钥匙串。除连邮箱的 IMAP/SMTP 和你主动触发的大模型调用外，没有任何外发流量。
- **学的是「你」的回法**：规则库从你真实的历史收发邮件提炼，每次改稿后自动继续优化。
- **人工把关**：每封草稿都等你编辑确认，绝不自动发送。
- **多品牌**：按店铺/品牌划分空间，规则、知识库、邮箱账号彼此隔离。

## 截图

<!-- TODO(作者): 截图放入 docs/screenshots/ 后取消注释。
     1. inbox.png   聚合聊天式收件箱（线程上下文）
2. draft.png   一键生成草稿 + 对话式改稿面板
3. learn.png   学习中心运行中（带进度）
4. rules.png   规则库（来源与版本历史）
5. spaces.png  空间页 + 账号弹窗（收信/发信开关）
6. demo.gif    30–60 秒端到端演示（收信 → 起草 → 编辑 → 发送）

| 聊天式收件箱 | AI 起草 |
|---|---|
| ![收件箱](docs/screenshots/inbox.png) | ![草稿](docs/screenshots/draft.png) |

| 学习中心 | 规则库 |
|---|---|
| ![学习](docs/screenshots/learn.png) | ![规则](docs/screenshots/rules.png) |

端到端演示：![demo](docs/screenshots/demo.gif)
-->

## 下载与安装

到 [Releases](https://github.com/zhixiakj/replaim/releases/latest) 页面下载最新版安装包：

- **macOS**（Apple Silicon 与 Intel）：`replaim-vX.Y.Z-macos.dmg`——打开后把
  **replaim** 拖进「应用程序」。
- **Windows**（10/11，x64）：`replaim-vX.Y.Z-windows-x64.zip`——解压运行
  `replaim.exe`（绿色便携版，无需安装）。

安装包**尚未代码签名**，首次打开系统会拦截：

- **macOS**：右键 App →「打开」→ 弹窗里再点一次「打开」即可；或在终端执行
  `xattr -cr /Applications/replaim.app`；或「系统设置 → 隐私与安全性 → 仍要打开」。
- **Windows**：SmartScreen 提示时点「更多信息」→「仍要运行」。

首次使用：创建空间 → 添加邮箱账号（见[邮箱账号配置](#邮箱账号配置gmail--outlook)）→
在设置里添加大模型 Profile（任意 OpenAI 兼容的 Base URL / 模型名 / API Key）。

## 功能

| 模块 | 说明 |
| ---- | ---- |
| 空间 | 一个空间 = 一套回复规则 + 知识库 + 若干邮箱账号（按店铺/品牌划分）。空间内可配置多个邮箱账号，分别设置**收信（IMAP）**与**发信（SMTP）**能力；回信默认用收信账号发出，未开发信时回落到默认发信账号 |
| 收件箱 | 汇总空间内全部收信账号的邮件（按时间合并）；IMAP 拉取来信、线程上下文、一键「依据规则生成草稿」；**转发识别**：客户发给未配置地址（如 support@）再转发到配置账号的邮件，自动识别原始收件地址，回信时抄送 |
| 草稿箱 | 草稿编辑、发送、丢弃；记录原始草稿 / 实发版本 / 是否修改；发送前可调整发信抄送 |
| 规则库 | 规则 = 唯一起草依据。每条规则记录**来源**（哪些邮件 / 哪个知识库文档 / 哪条 Prompt / 哪次草稿修改）与**版本历史**，YAML 文件保存（按空间分区） |
| 知识库 | 导入 .md/.txt 文档（复制进应用目录），按内容 hash 跟踪变更，变更后可重新生成规则（按空间隔离） |
| 学习中心 | 历史邮件增量学习（空间内全部账号逐一学习）：已消费邮件绝不重复使用；按时间升序处理、冲突时新邮件优先，防止旧邮件覆盖新规则 |
| 设置 | 大模型 Profiles（可配置多个，OpenAI 兼容 Base URL / 模型名 / API Key，分配给各空间使用）、自定义 Prompt |

## 横向对比

| | Replaim | Superhuman / Shortwave | Gmail 快速回复模板 | 手动复制粘贴 ChatGPT |
|---|---|---|---|---|
| 价格 | 免费（开源）+ 自付 API 用量 | 约 $10–30 / 月 | 免费 | 手动折腾 |
| 学习你的回信风格 | ✅ 从历史邮件提炼，持续自我优化 | 部分（云端 AI） | ❌ 静态模板 | ❌ 每次从零开始 |
| 邮件数据在哪 | 100% 本地文件 | 服务商云端 | Google 云端 | 手动到处粘贴 |
| 发送安全 | 只起草，每封都要人确认发送 | 有自动代发类功能 | 手动 | 手动 |
| 多品牌（按店铺隔离规则/知识库/账号） | ✅ 空间 | ❌ | 按账号 | ❌ |

## 数据存放（全部本地）

```
<ApplicationSupport>/replaim/
├── app_state.yaml            # 全局状态（当前空间 ID）
├── llm_profiles.yaml         # 全局大模型注册表（非敏感字段）
└── spaces/<spaceId>/         # 每个空间一个分区
    ├── space.yaml            # 空间元数据 + 账号列表 + 学习偏好
    ├── rules/rules.yaml      # 本空间规则库：内容 + 来源 + 版本历史（核心资产）
    ├── learn_state.yaml      # 已学习邮件清单（Message-ID 级去重）
    ├── knowledge_base/       # 本空间知识库文档副本 + kb_index.yaml（hash 版本）
    └── drafts/<id>.yaml      # 每封草稿的完整记录（原始稿/实发稿/diff/规则更新）
```

密码与 API Key 按账号 / 模型 ID 命名存放于系统安全存储（flutter_secure_storage）。
旧版单空间布局在启动时自动迁移为「默认空间」；全新安装由用户创建第一个空间。

## 邮箱账号配置（Gmail / Outlook）

在「空间」页添加邮箱账号时，输入完整邮箱地址会按服务商预设自动填充服务器地址、
端口与学习文件夹，一般只需补齐凭证。两类常见邮箱的配置方式：

### Gmail（密码 = 应用专用密码）

1. Google 账号开启**两步验证**，再到「安全性 → 两步验证 → 应用专用密码」生成一个
   16 位应用专用密码（没有两步验证就没有这个入口）。
2. 账号弹窗里输入邮箱地址（自动填充 `imap.gmail.com:993` SSL / `smtp.gmail.com:465`
   SSL 与已发送文件夹），**密码框粘贴应用专用密码**（不是账号登录密码）。
3. 学习文件夹：Gmail 为 `[Gmail]/Sent Mail`（中文界面的账号为
   `[Gmail]/已发送邮件`），应用会自动匹配常见命名；不确定就点
   「从服务器读取文件夹列表」直接勾选。

> 个人 Gmail 的 IMAP 默认开启；Google Workspace 组织账号可由管理员关闭
> （Gmail 设置 → 转发和 POP/IMAP）。

### Outlook / Hotmail / Live（OAuth2 登录）

微软已**全面禁用** IMAP/SMTP 的密码登录（Basic Auth，应用密码同渠道一并废弃，
个人账号 2024-09 起分阶段停用），Outlook 账号必须走 OAuth2：

1. **开启 IMAP**：Outlook 网页版 → 设置 → 邮件 → 转发和 IMAP → 打开 IMAP 并保存
   （默认关闭，不开则授权后也连不上）。
2. **注册 Azure 应用拿客户端 ID**（一次性，多个 Outlook 账号可复用同一个）：
   - [portal.azure.com](https://portal.azure.com) → 顶部搜索 `App registrations` →
     **New registration**；帐户类型选「**Accounts in any organizational directory
     and personal Microsoft accounts**」；重定向 URI 平台选
     「**Mobile and desktop applications**」、填 `http://localhost`；注册后复制
     **Application (client) ID**。
   - **个人 Microsoft 账号且从未有过 Azure 目录会被拦**（提示「在目录外创建应用已
     弃用」）：先注册 [Azure 免费账户](https://azure.microsoft.com/free)（需
     Visa/MasterCard 验证身份，**不会自动扣费**，赠金到期即停、需手动升级），或改用
     任一工作/学校 Microsoft 365 账号登录门户注册（客户端 ID 与所在租户无关，
     个人账号照样能用）。
   - 可选：API 权限添加 Office 365 Exchange Online → 委托权限
     `IMAP.AccessAsUser.All`、`SMTP.Send`（个人账号可跳过，授权时动态同意；
     组织账号若被拒需管理员「授予管理员同意」）。
3. **Replaim 配置**：输入邮箱地址（自动填充 `outlook.office365.com:993` SSL /
   `smtp.office365.com:587` STARTTLS）→ 保持「**OAuth2 登录**」开关开启 → 填入
   客户端 ID → 点「**登录 Microsoft 账号**」在浏览器完成授权 → 「测试连接」验证。

> 令牌存于系统钥匙串并**到期自动续期**，正常使用无需重复登录；只有修改密码或
> 撤销授权后才需要重新点「登录 Microsoft 账号」。

### 其它服务商

QQ / 163 / 126 等在网页版邮箱设置（通常在「设置 → 账户」开启 IMAP/SMTP 服务）生成
**授权码**，账号弹窗密码框填授权码即可，方式与 Gmail 相同。

## 常见问题

**真的免费吗？有什么代价？**
Apache-2.0 开源，无订阅、无任何人的服务端。你需要一个大模型 API Key（OpenAI、
DeepSeek、GLM、Moonshot、本地 Ollama……凡 OpenAI 兼容均可），费用直接付给服务商——
客服邮件这个量级通常一天几毛钱。

**隐私怎么保障？**
邮件、规则、知识库、草稿全部以 YAML 存在本机用户目录；密码、API Key、OAuth 令牌存
系统钥匙串。对外流量只有两类：连你邮箱的 IMAP/SMTP，和你主动触发的大模型调用
（把当前邮件内容 + 规则发到**你自己配置**的端点、用**你自己的** Key）。

**支持哪些邮箱？**
Gmail（应用专用密码）、Outlook / Hotmail / Live（OAuth2，微软已禁用密码登录）、
QQ / 163 / 126（授权码），以及任何标准 IMAP/SMTP 服务商。见
[邮箱账号配置](#邮箱账号配置gmail--outlook)。

**界面是什么语言？**
操作台为中文（面向中文卖家回复海外客户），草稿输出为英文。英文界面暂未提供。

**会自动发信吗？**
绝不。只起草；每一封都由人编辑确认后才发出。

## 开发

```bash
# 本项目使用 FVM（请用实际版本路径）
flutter pub get
flutter test                        # 单元测试（YAML round-trip / JSON 容错解析 / 规则版本 / diff）
flutter run -d macos --flavor dev   # 开发调试一律带 --flavor dev
```

macOS 调试需在 Xcode 中信任开发签名（或 `flutter run` 首次允许运行）。

### 开发版 / 正式版隔离（同一台机器既开发又日常使用）

开发构建带 `--flavor dev`，正式构建不带。两者数据、密钥、产物完全隔离，可同时运行：

| | dev（开发调试） | 正式（日常使用） |
|---|---|---|
| 命令 | `flutter run/build ... --flavor dev` | `flutter build macos --release` |
| App 名 / Bundle ID | Replaim Dev（界面带 DEV 角标）/ `com.replaim.replaim.dev` | replaim / `com.replaim.replaim` |
| 数据 | 沙箱容器与数据目录按 bundle id 自动分离，互不可见 | 同左 |
| 钥匙串 | 独立 service（`..._dev`），密码 / API Key 与正式版互不影响 | 默认 service |
| 构建产物 | `build/macos/Build/Products/<Mode>-dev/` | `build/macos/Build/Products/<Mode>/` |

- 正式版安装 / 更新：`flutter build macos --release` 后将
  `build/macos/Build/Products/Release/replaim.app` 拷贝到 `/Applications`（唯一会发生「覆盖」的地方）。
- dev 版首次使用需单独配置测试邮箱授权码与 LLM Key；在 dev 里增删空间、重装数据都不影响正式版。
- 工具链隔离：Flutter SDK 由 `.fvmrc` 锁定（FVM 按项目隔离），Homebrew 装在 `/opt/homebrew`（用户态），不覆盖系统日常环境。
- Windows 端暂未配置 flavor，将来支持时按同样思路（独立产品名 + `FLUTTER_APP_FLAVOR`）实现。

## 技术栈

Flutter 3.47+ · Riverpod（状态） · enough_mail（IMAP/SMTP） · dio（LLM HTTP） ·
yaml / yaml_writer（数据文件，原子写入） · flutter_secure_storage（密钥） ·
diff_match_patch（草稿对比）

## 边界（首版明确不做）

PDF/Word 知识库（首版 .md/.txt）、向量检索（规则生成为低频批处理，直接分块喂 LLM）、
自动发送、团队协作、以附件形式转发的邮件（.eml 内嵌）不解析原始收件地址
（服务器别名/转发已支持）。邮箱登录方式：Outlook 走 OAuth2（微软已禁用密码登录），
Gmail / QQ / 163 等用应用专用密码 / 授权码，见上文「邮箱账号配置」。

## 许可证

以 [Apache License 2.0](LICENSE) 开源发布。
Copyright 2026 The Replaim Authors.
