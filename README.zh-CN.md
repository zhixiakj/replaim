# Replaim 客户端

[English](README.md) | 简体中文

面向跨境电商卖家的客服邮件 copilot 桌面应用（Flutter，macOS / Windows）。

**核心闭环**：接收邮件 → 从「历史邮件 + 知识库 + 自定义 Prompt」提炼**回复规则** →
严格依据规则起草英文回复 → 人工编辑确认后 SMTP 发送 → 对比草稿与实发内容，
**自动优化回复规则**。起草，不代发；中文操作台，英文输出。

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

OAuth 登录（用账号 + 授权码）、PDF/Word 知识库（首版 .md/.txt）、
向量检索（规则生成为低频批处理，直接分块喂 LLM）、自动发送、团队协作、
以附件形式转发的邮件（.eml 内嵌）不解析原始收件地址（服务器别名/转发已支持）。
