# Replaim 客户端

面向跨境电商卖家的客服邮件 copilot 桌面应用（Flutter，macOS / Windows）。

**核心闭环**：接收邮件 → 从「历史邮件 + 知识库 + 自定义 Prompt」提炼**回复规则** →
严格依据规则起草英文回复 → 人工编辑确认后 SMTP 发送 → 对比草稿与实发内容，
**自动优化回复规则**。起草，不代发；中文操作台，英文输出。

## 功能

| 模块 | 说明 |
| ---- | ---- |
| 收件箱 | IMAP 拉取来信、线程上下文、一键「依据规则生成草稿」 |
| 草稿箱 | 草稿编辑、发送、丢弃；记录原始草稿 / 实发版本 / 是否修改 |
| 规则库 | 规则 = 唯一起草依据。每条规则记录**来源**（哪些邮件 / 哪个知识库文档 / 哪条 Prompt / 哪次草稿修改）与**版本历史**，YAML 文件保存 |
| 知识库 | 导入 .md/.txt 文档（复制进应用目录），按内容 hash 跟踪变更，变更后可重新生成规则 |
| 学习中心 | 历史邮件增量学习：已消费邮件绝不重复使用；按时间升序处理、冲突时新邮件优先，防止旧邮件覆盖新规则 |
| 设置 | 邮箱（IMAP/SMTP，授权码）、大模型（自定义 Base URL / 模型名 / API Key，OpenAI 兼容协议）、输出语言、学习范围、自定义 Prompt |

## 数据存放（全部本地）

```
<ApplicationSupport>/replaim/
├── config/app_config.yaml    # 非敏感配置（密码与 API Key 在系统安全存储中）
├── rules/rules.yaml          # 规则库：内容 + 来源 + 版本历史（核心资产）
├── learn_state.yaml          # 已学习邮件清单（Message-ID 级去重）
├── knowledge_base/           # 知识库文档副本 + kb_index.yaml（hash 版本）
└── drafts/<id>.yaml          # 每封草稿的完整记录（原始稿/实发稿/diff/规则更新）
```

## 开发

```bash
# 本项目使用 FVM（请用实际版本路径）
flutter pub get
flutter test          # 单元测试（YAML round-trip / JSON 容错解析 / 规则版本 / diff）
flutter run -d macos  # macOS 调试运行（Windows: flutter run -d windows）
```

macOS 调试需在 Xcode 中信任开发签名（或 `flutter run` 首次允许运行）。

## 技术栈

Flutter 3.47+ · Riverpod（状态） · enough_mail（IMAP/SMTP） · dio（LLM HTTP） ·
yaml / yaml_writer（数据文件，原子写入） · flutter_secure_storage（密钥） ·
diff_match_patch（草稿对比）

## 边界（首版明确不做）

多邮箱账号、OAuth 登录（用账号 + 授权码）、PDF/Word 知识库（首版 .md/.txt）、
向量检索（规则生成为低频批处理，直接分块喂 LLM）、自动发送、团队协作。
