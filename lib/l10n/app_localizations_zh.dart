// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Replaim 客服邮件助手';

  @override
  String get navInbox => '邮件列表';

  @override
  String get navDrafts => '草稿箱';

  @override
  String get navRules => '规则库';

  @override
  String get navKb => '知识库';

  @override
  String get navLearn => '学习中心';

  @override
  String get navSpaces => '空间';

  @override
  String get navSettings => '设置';

  @override
  String get switchSpaceTooltip => '切换空间';

  @override
  String accountsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 账号',
    );
    return '$_temp0';
  }

  @override
  String get noSpaceSelected => '未选择空间';

  @override
  String get loading => '加载中…';

  @override
  String spaceReceiveSend(num receive, num send) {
    return '$receive 收 / $send 发';
  }

  @override
  String get newSpaceTooltip => '新建空间';

  @override
  String get newSpaceTitle => '新建空间';

  @override
  String get spaceNameLabel => '空间名称（如店铺 / 品牌名）';

  @override
  String get commonCancel => '取消';

  @override
  String get commonCreate => '创建';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonDelete => '删除';

  @override
  String get commonSave => '保存';

  @override
  String get commonJoinSeparator => '、';

  @override
  String get commonDone => '完成';

  @override
  String get commonAdd => '添加';

  @override
  String get commonClose => '关闭';

  @override
  String get commonSend => '发送';

  @override
  String get commonSending => '发送中…';

  @override
  String get commonEmptyValue => '（空）';

  @override
  String get commonTesting => '测试中…';

  @override
  String get commonTestConnection => '测试连接';

  @override
  String settingsSummary(num count, String path) {
    return '当前空间启用规则 $count 条 · 数据目录 $path';
  }

  @override
  String get settingsGeneralTitle => '通用';

  @override
  String get settingsLanguageLabel => '语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsLlmSectionTitle => '大模型（全局，OpenAI 兼容接口）';

  @override
  String settingsLlmSectionSubtitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '当前 $count 个空间已分配模型',
    );
    return '$_temp0；可配置多个模型端点，在「空间」页分配给各空间使用。';
  }

  @override
  String get settingsLlmEmpty => '还没有模型配置，点击下方按钮添加';

  @override
  String llmProfileTitle(String name, String model) {
    return '$name（$model）';
  }

  @override
  String get settingsAddLlm => '添加大模型';

  @override
  String get settingsAddLlmTitle => '添加大模型';

  @override
  String get settingsEditLlmTitle => '编辑大模型';

  @override
  String get settingsLlmFieldName => '名称（如 DeepSeek、公司 GPT）';

  @override
  String get settingsLlmFieldBaseUrl =>
      'API 地址（通常以 /v1 结尾），如 https://api.deepseek.com/v1';

  @override
  String get settingsLlmFieldModel => '模型名称，如 deepseek-chat';

  @override
  String get settingsLlmFieldApiKey => 'API Key（编辑时留空保持不变）';

  @override
  String get settingsLlmFieldTemperature => '温度';

  @override
  String get settingsLlmFieldMaxTokens => '最大 tokens';

  @override
  String get settingsLlmFieldTimeout => '超时（秒）';

  @override
  String settingsLlmTestOk(String endpoint) {
    return '连接成功（$endpoint）';
  }

  @override
  String get settingsLlmUnnamed => '未命名模型';

  @override
  String get settingsLlmSaved => '已保存大模型配置';

  @override
  String settingsLlmDeleteTitle(String name) {
    return '删除大模型「$name」';
  }

  @override
  String get settingsLlmDeleteUnused => '该模型未被任何空间使用。';

  @override
  String settingsLlmDeleteInUse(String spaces) {
    return '以下空间正在使用该模型，删除后将变为未分配：\n$spaces';
  }

  @override
  String get settingsPromptSectionTitle => '自定义 Prompt 规则';

  @override
  String get settingsPromptSectionSubtitle =>
      '把你对回复的要求沉淀成规则（写入当前空间，与历史邮件、知识库规则一起作为草稿依据）';

  @override
  String get settingsPromptHint => '例如：所有退款邮件先致歉再给方案；落款用 Best regards, Amy';

  @override
  String get settingsPromptSplitButton => '经大模型拆分成规则（推荐）';

  @override
  String get settingsPromptDirectButton => '直接作为一条规则';

  @override
  String get settingsPromptEmpty => '暂无自定义 Prompt 规则';

  @override
  String get settingsPromptSplitting => '正在拆分规则…';

  @override
  String get settingsPromptConfirmTitle => '确认生成的规则';

  @override
  String get settingsPromptAddSelected => '添加选中项';

  @override
  String settingsPromptAddedRules(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已添加 $count 条规则',
    );
    return '$_temp0';
  }

  @override
  String settingsPromptSplitFailed(String error) {
    return '拆分失败：$error';
  }

  @override
  String get settingsPromptAddedOne => '已添加规则';

  @override
  String get ruleSourceEmailHistory => '历史邮件';

  @override
  String get ruleSourceKnowledgeBase => '知识库';

  @override
  String get ruleSourceUserPrompt => '自定义 Prompt';

  @override
  String get ruleSourceDraftFeedback => '草稿修改反馈';

  @override
  String get ruleSourceManual => '手动添加';

  @override
  String get ruleCategoryTone => '语气风格';

  @override
  String get ruleCategoryPolicy => '售后政策';

  @override
  String get ruleCategoryFormat => '格式结构';

  @override
  String get ruleCategoryProduct => '商品信息';

  @override
  String get ruleCategoryCompliance => '平台合规';

  @override
  String get ruleCategoryOther => '其他';

  @override
  String get spacesTitle => '空间管理';

  @override
  String get spacesEmptyIntro =>
      '一个空间是一个独立的业务上下文（如一个店铺 / 品牌）：\n· 空间内共用一套回复规则与知识库\n· 可配置多个邮箱账号，分别设置收信（IMAP）与发信（SMTP）能力\n· 转发来的邮件（如客户发给 support@，转发到配置账号）会自动识别原始收件地址，回信时抄送';

  @override
  String get spacesCreateFirst => '新建第一个空间';

  @override
  String spacesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个空间',
    );
    return '$_temp0';
  }

  @override
  String get spacesCurrentBadge => '当前';

  @override
  String spacesAccountSummary(num accounts, num receive, num send) {
    return '$accounts 个账号 · $receive 收 / $send 发';
  }

  @override
  String get spacesDeleteTooltip => '删除空间';

  @override
  String spacesDeleteTitle(String name) {
    return '删除空间「$name」';
  }

  @override
  String get spacesDeleteContent =>
      '将删除该空间的规则库、知识库、学习状态与草稿记录，以及全部账号的已存密码。\n此操作不可恢复。';

  @override
  String spacesDetailTitle(String name) {
    return '空间：$name';
  }

  @override
  String get spacesSetCurrent => '设为当前空间';

  @override
  String get spacesBasicInfoSection => '基本信息';

  @override
  String get spacesFieldName => '空间名称';

  @override
  String get spacesAssignLlmLabel => '分配大模型（在设置页管理多个模型）';

  @override
  String get spacesLlmUnassigned => '未分配';

  @override
  String get spacesDefaultSendLabel => '默认发信账号（收信账号未开发信时回落使用）';

  @override
  String get spacesDefaultSendAuto => '自动（任一可发信账号）';

  @override
  String get spacesOutputLanguageLabel => '草稿输出语言（默认 English）';

  @override
  String get spacesLearnPrefsSection => '学习偏好（按空间）';

  @override
  String get spacesLearnMonthsLabel => '学习时间范围（近 N 个月）';

  @override
  String get spacesLearnFoldersHint =>
      '历史学习文件夹按邮箱账号单独设置（文件夹名因服务商而异：Gmail 为 [Gmail]/Sent Mail（中文账号为 [Gmail]/已发送邮件）、QQ/163 为 Sent Messages、Outlook 为 Sent）。请在下方「邮箱账号」中编辑各账号填写；常见命名会自动匹配，全部未命中时学习会按服务器标记自动识别。';

  @override
  String spacesAccountsSection(num count) {
    return '邮箱账号（$count）';
  }

  @override
  String get spacesAccountsSubtitle =>
      '每个账号可分别设置收信（IMAP）与发信（SMTP）能力；回信默认用收信账号发出';

  @override
  String get spacesNoAccounts => '还没有账号，点击下方按钮添加';

  @override
  String get spacesAddAccount => '添加邮箱账号';

  @override
  String get spacesAutoSaved => '修改后自动保存';

  @override
  String spacesDeleteAccountTitle(String email) {
    return '删除账号 $email';
  }

  @override
  String get spacesDeleteAccountContent => '将移除该账号的配置与已存密码。空间内数据不受影响。';

  @override
  String get accountDisabledBadge => '已停用';

  @override
  String get accountReceiveBadge => '收信';

  @override
  String get accountNoReceiveBadge => '不收信';

  @override
  String get accountSendBadge => '发信';

  @override
  String get accountNoSendBadge => '不发信';

  @override
  String get accountDefaultSendBadge => '默认发信';

  @override
  String accountLearnFoldersBadge(String folders) {
    return '学习 $folders';
  }

  @override
  String spacesAddAccountTitle(String space) {
    return '添加邮箱账号（空间：$space）';
  }

  @override
  String spacesEditAccountTitle(String email) {
    return '编辑账号 $email';
  }

  @override
  String get spacesFieldEmail => '邮箱地址（同时作为登录用户名）';

  @override
  String get spacesFieldEmailHelper =>
      '常见邮箱（Gmail / QQ / 163 / Outlook 等）输入地址后自动填充下方服务器与学习文件夹';

  @override
  String get spacesFieldDisplayName => '发件显示名（可选）';

  @override
  String get spacesEnableAccount => '启用此账号';

  @override
  String get spacesEnableAccountSubtitle => '停用后不参与收信、发信与学习，配置保留可随时再开启';

  @override
  String get spacesOauthToggle => 'OAuth2 登录（Outlook 必需：微软已禁用密码登录）';

  @override
  String get spacesFieldPassword => '密码 / 授权码';

  @override
  String get spacesTabReceive => '收信（IMAP）';

  @override
  String get spacesTabSend => '发信（SMTP）';

  @override
  String get spacesSaveAccount => '保存账号';

  @override
  String get spacesReceiveToggle => '收信（IMAP：拉取收件箱、参与学习）';

  @override
  String get spacesFieldImapHost => 'IMAP 服务器，如 imap.qq.com';

  @override
  String get spacesFieldPort => '端口';

  @override
  String get spacesImapSslToggle => 'IMAP 使用 SSL（993 端口通常开启）';

  @override
  String get spacesFieldLearnFolders => '历史学习文件夹（逗号分隔，默认 Sent）';

  @override
  String get spacesLearnFoldersHelper =>
      '文件夹名因邮箱服务商而异：Gmail 为 [Gmail]/Sent Mail（中文账号为 [Gmail]/已发送邮件）、QQ/163 为 Sent Messages、Outlook 为 Sent。常见命名会自动匹配，不确定可点下方按钮从服务器选取';

  @override
  String get spacesLoadFoldersButton => '从服务器读取文件夹列表';

  @override
  String get spacesSendToggle => '发信（SMTP：可用于发出回复）';

  @override
  String get spacesFieldSmtpHost => 'SMTP 服务器，如 smtp.qq.com（只收信可留空）';

  @override
  String get spacesSmtpSecureToggle => 'SMTP 加密（465=SSL / 587=STARTTLS）';

  @override
  String get spacesForcedOffNoOauth => '尚未完成 Microsoft 授权';

  @override
  String get spacesForcedOffNoPassword => '尚未填写密码 / 授权码';

  @override
  String get spacesForcedOffTestFailed => '最近一次「测试连接」未成功';

  @override
  String get spacesErrEmailRequired => '请填写邮箱地址';

  @override
  String spacesSavedDisabled(String email, String reason) {
    return '$email：$reason，已保存为停用状态，补齐并验证后可在账号列表中开启';
  }

  @override
  String get spacesOauthNeedClientId =>
      '请先填写 Azure 应用客户端 ID（Azure 应用 Overview 页的 Application (client) ID）';

  @override
  String spacesOauthSuccess(String expiry) {
    return '✓ Microsoft 授权成功（令牌有效期至 $expiry，到期自动续期）';
  }

  @override
  String spacesOauthFailed(String error) {
    return '授权失败：$error';
  }

  @override
  String spacesFoldersMore(num count) {
    return ' 等共 $count 个';
  }

  @override
  String spacesFoldersMissing(String email, String folders, String existing) {
    return '$email：学习文件夹「$folders」在服务器上不存在（现有：$existing），可编辑该账号并点「从服务器读取文件夹列表」选取';
  }

  @override
  String spacesTestOkFoldersMatched(String folders) {
    return '连接成功；学习文件夹「$folders」✓ 已匹配';
  }

  @override
  String spacesTestFoldersMissing(String folders) {
    return '连接成功；⚠ 学习文件夹「$folders」在服务器上不存在（可点下方按钮从服务器选取）';
  }

  @override
  String get spacesTestOkImap => '连接成功（IMAP 登录正常）';

  @override
  String get spacesPickFoldersNeedOauth => '请先填写邮箱地址并完成 Microsoft 授权';

  @override
  String get spacesPickFoldersNeedCreds => '请先填写邮箱地址、IMAP 服务器和密码';

  @override
  String get spacesPickFoldersTitle => '选择历史学习文件夹';

  @override
  String get spacesServerSentBadge => '服务器已发送';

  @override
  String spacesLoadFoldersFailed(String error) {
    return '读取文件夹失败：$error';
  }

  @override
  String get spacesPwdHelperNew => 'QQ、163 等需在邮箱后台生成授权码；保存后加密存入系统钥匙串';

  @override
  String get spacesPwdHelperSaved => '已保存授权码（框内圆点仅为占位）；更换时直接输入新授权码';

  @override
  String get spacesPwdHelperNone => '尚未保存密码';

  @override
  String get spacesOauthClientIdLabel => 'Azure 应用客户端 ID';

  @override
  String get spacesOauthClientIdHelper =>
      'Azure 门户注册「移动和桌面应用」获得（重定向 URI 填 http://localhost，账号类型含个人 Microsoft 帐户）；多个 Outlook 账号可复用同一个 ID';

  @override
  String get spacesOauthWaiting => '等待浏览器完成授权…（最多 5 分钟）';

  @override
  String get spacesOauthRelogin => '重新登录 Microsoft 账号';

  @override
  String get spacesOauthLogin => '登录 Microsoft 账号';

  @override
  String get spacesOauthNotYetHint =>
      '尚未授权：也可先保存（账号将处于停用状态），稍后编辑完成登录再启用（Outlook 还需先在网页版设置里开启 IMAP）';

  @override
  String rulesEnabledSummary(num enabled, num total) {
    return '启用 $enabled / 共 $total 条';
  }

  @override
  String get rulesAddManual => '手动添加';

  @override
  String get rulesSearchHint => '搜索规则内容';

  @override
  String get rulesFilterAllSources => '全部来源';

  @override
  String get rulesFilterEnabledOnly => '只看启用';

  @override
  String get rulesEmpty => '规则库为空：去「学习中心」学习历史邮件、\n「知识库」导入文档、或「设置」添加自定义 Prompt';

  @override
  String get rulesAddManualTitle => '手动添加规则';

  @override
  String get rulesFieldContent => '规则内容';

  @override
  String get rulesFieldCategory => '类目';

  @override
  String get rulesSuperseded => '已被新规则取代';

  @override
  String rulesStatsTooltip(num used, num kept, num edited) {
    return '使用 $used 次 · 未改直接发 $kept 次 · 被修改 $edited 次';
  }

  @override
  String rulesUsedTimes(num count) {
    return '$count次';
  }

  @override
  String get rulesDetailTitle => '规则详情';

  @override
  String get rulesKvCategory => '类目';

  @override
  String get rulesKvStatus => '状态';

  @override
  String get rulesStatusEnabled => '启用';

  @override
  String get rulesStatusDisabled => '停用';

  @override
  String get rulesStatusSuperseded => '已被取代';

  @override
  String get rulesKvVersion => '当前版本';

  @override
  String get rulesKvStats => '使用统计';

  @override
  String rulesStatsDetail(num used, num kept, num edited) {
    return '使用 $used 次 / 未改发送 $kept / 被修改 $edited';
  }

  @override
  String get rulesSourceSection => '来源（这条规则怎么来的）';

  @override
  String get rulesKvType => '类型';

  @override
  String get rulesKvGeneratedBy => '生成模型';

  @override
  String get rulesKvCreatedAt => '生成时间';

  @override
  String get rulesHistorySection => '版本历史';

  @override
  String rulesChangeReason(String reason) {
    return '变更原因：$reason';
  }

  @override
  String get rulesDeleteTitle => '删除规则';

  @override
  String get rulesDeleteContent => '删除后不可恢复（含版本历史）。确定？';

  @override
  String get rulesKvDateRange => '邮件日期范围';

  @override
  String get rulesKvSourceMails => '来源邮件数';

  @override
  String rulesSourceMailsDetail(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 封（Message-ID 已记录在学习状态中，不会重复学习）',
    );
    return '$_temp0';
  }

  @override
  String get rulesKvDoc => '文档';

  @override
  String get rulesKvDocVersion => '文档版本';

  @override
  String get rulesKvUserPrompt => '用户 Prompt';

  @override
  String get rulesKvSourceDraft => '来源草稿';

  @override
  String get rulesKvChangeSummary => '修改摘要';

  @override
  String get rulesKvReason => '优化原因';

  @override
  String get rulesEditContentTitle => '编辑规则内容';

  @override
  String get inboxRefreshTooltip => '刷新';

  @override
  String get inboxRefreshIncremental => '刷新（只拉新邮件）';

  @override
  String get inboxRefreshFull => '完全刷新（重建缓存）';

  @override
  String get inboxEmpty => '暂无邮件，请先在空间中配置账号并刷新';

  @override
  String get inboxNoSelection => '选择一个会话查看往来';

  @override
  String get inboxInternalConversation => '（本空间内部往来）';

  @override
  String get inboxNoBody => '（无正文）';

  @override
  String get inboxForwardedTooltip => '会话中含转发邮件，原始收件不在本空间账号内';

  @override
  String get inboxRepliedBadge => '已回';

  @override
  String inboxMePrefix(String text) {
    return '我：$text';
  }

  @override
  String inboxMessagesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 封往来（含已发出）',
    );
    return '$_temp0';
  }

  @override
  String inboxDraftsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 份草稿',
    );
    return '$_temp0';
  }

  @override
  String get inboxNoIncoming => '本会话暂无对方来件，无法生成草稿';

  @override
  String get inboxTapToSelect => '点击对方邮件气泡后可生成草稿';

  @override
  String inboxSelected(String subject) {
    return '选中：$subject';
  }

  @override
  String get inboxGenerating => '生成中…';

  @override
  String get inboxGenerateDraft => '依据规则生成草稿';

  @override
  String inboxForwardedWarning(String recipients, String account) {
    return '检测到转发：客户原始收件地址为 $recipients，（不在本空间账号内）。生成草稿时会默认通过 $account 发送并抄送上述地址，可在草稿页调整。';
  }

  @override
  String get inboxChipDraft => '草稿';

  @override
  String get inboxChipSentManual => '已发送 · 手工标注';

  @override
  String get inboxChipSent => '已发送';

  @override
  String inboxReplySubject(String subject) {
    return '回复：$subject';
  }

  @override
  String inboxDraftPendingNote(String date) {
    return '$date · 未发送的草稿不会计入后续草稿生成与学习';
  }

  @override
  String inboxDraftCountedNote(String date) {
    return '$date · 已计入后续草稿生成与学习的参考';
  }

  @override
  String get inboxMarkSent => '标注已发送';

  @override
  String get inboxSentFallback => '已发送';

  @override
  String get inboxSendFailed => '发送失败';

  @override
  String get inboxMarkedSentFallback => '已标注为已发送';

  @override
  String get inboxEmailDetails => '邮件详情';

  @override
  String inboxSentVia(String account) {
    return '经 $account 发出';
  }

  @override
  String inboxReceivedVia(String account) {
    return '收信 $account';
  }

  @override
  String get inboxAuthInfoMissing => '未获取到发件认证信息（该邮件可能未提供，或网络不可用）';

  @override
  String get inboxAuthInfoLoading => '正在获取发件认证信息…';

  @override
  String get learnReset => '重置学习记录';

  @override
  String get learnResetTitle => '重置学习记录';

  @override
  String get learnResetContent =>
      '将清空「已消费邮件」记录，不影响已生成的规则。下次「开始增量学习」会重新读取全部历史邮件。确定？';

  @override
  String get learnResetConfirm => '重置';

  @override
  String get learnRunning => '学习中…';

  @override
  String get learnStart => '开始增量学习';

  @override
  String learnIntro(String folders, num months) {
    return '从各账号「$folders」与收件箱近 $months 个月的历史中提炼回复规则（文件夹因服务商而异，按账号在「空间」页的邮箱账号中设置）：学习时自动把客户来信与你的回复按线程配对，从「问了什么 → 怎么答」中学习（空间内全部账号逐一学习）。已学习过的邮件不会重复使用；邮件按时间升序处理、冲突时新邮件优先，保证旧邮件不会覆盖新邮件沉淀的规则。';
  }

  @override
  String get learnProcessing => '正在处理…';

  @override
  String get learnFailedFoldersTitle => '部分学习文件夹拉取失败';

  @override
  String get learnFailedFoldersHint =>
      '请在「空间」页 → 邮箱账号 → 编辑该账号 → 历史学习文件夹 中改用服务器实际存在的文件夹名，或点「从服务器读取文件夹列表」直接选择；常用已发送命名（Sent / Sent Messages / Sent Items / 已发送）会自动匹配，全部未命中时学习会按服务器 \\Sent 标记自动识别。';

  @override
  String get learnStatusSection => '学习状态';

  @override
  String learnConsumedCount(num count) {
    return '已消费邮件：$count 封';
  }

  @override
  String learnLastRun(String time) {
    return '上次学习：$time';
  }

  @override
  String get learnNever => '从未学习';

  @override
  String get learnNoRecords => '还没有学习记录。点击「开始增量学习」从历史邮件中提炼规则。';

  @override
  String get learnRecentSection => '最近消费的邮件（最多显示 200 封）';

  @override
  String get learnNoSubject => '（无主题）';

  @override
  String learnGeneratedRules(num count) {
    return '产出规则 $count 条';
  }

  @override
  String get draftStatusEditing => '编辑中';

  @override
  String get draftStatusSentUnmodified => '已发送（未修改）';

  @override
  String get draftStatusSentEdited => '已发送（修改后）';

  @override
  String get draftStatusSentManually => '已发送（手工标注）';

  @override
  String get draftStatusDiscarded => '已丢弃';

  @override
  String get draftConfirmDeleteTitle => '删除草稿';

  @override
  String get draftConfirmDeleteContent => '删除后不可恢复（不会发送）。';

  @override
  String get draftMarkSentTitle => '标注为已发送';

  @override
  String get draftMarkSentContent =>
      '用于「已在本应用之外（如邮箱网页版）手工发送这封草稿」的情况。\n标注后，该内容会计入后续草稿生成与学习的参考。';

  @override
  String get draftMarkSentFeedback => '对比我的修改并优化规则';

  @override
  String get draftMarkSentFeedbackHint => '若你在其他平台又改动过内容，请取消勾选';

  @override
  String get draftMarkSentConfirm => '标注';

  @override
  String get draftConfirmSendTitle => '确认发送';

  @override
  String draftSendCcNote(String ccs) {
    return '抄送：$ccs';
  }

  @override
  String draftConfirmSendContent(String to, String ccNote, String subject) {
    return '将发送到 $to$ccNote\n主题：Re: $subject';
  }

  @override
  String get draftSendKeepEditing => '再改改';

  @override
  String get draftsSubtitle => '发送时若草稿被修改，会自动分析修改并优化回复规则；未发送的草稿不会计入后续草稿生成与学习';

  @override
  String get draftsEmpty => '暂无草稿，去邮件列表生成第一封吧';

  @override
  String draftsTileSubtitle(String to, String date, num rules) {
    return '$to · $date · 依据 $rules 条规则';
  }

  @override
  String get draftNotFound => '草稿不存在';

  @override
  String get draftUnsentNote => '未发送的草稿不会计入后续草稿生成与学习；发送或标注已发送后，内容才会作为参考。';

  @override
  String draftToLine(String to) {
    return '收件人：$to';
  }

  @override
  String get draftSenderMissing => '发信账号：（空间内无可用发信账号）';

  @override
  String draftSenderLine(String account) {
    return '发信账号：$account';
  }

  @override
  String get draftSenderFallbackNote => '（收信账号未开发信，使用默认发信账号）';

  @override
  String draftGeneratedByLine(String model) {
    return '生成模型：$model';
  }

  @override
  String draftStatusLine(String status) {
    return '状态：$status';
  }

  @override
  String get draftEditHint => '草稿由回复规则生成，可直接编辑或用右侧 AI 对话修改；发送时会对比修改并自动优化规则。';

  @override
  String get draftCcLabel => '抄送（转发场景自动识别的原始收件地址，可增删）';

  @override
  String get draftAddCcHint => '添加抄送地址';

  @override
  String draftUsedRulesTitle(num count) {
    return '本草稿依据的回复规则（$count 条）';
  }

  @override
  String get draftUsedRulesSubtitle => '草稿只依据规则生成，规则未覆盖的内容不会编造';

  @override
  String draftRuleSourceLine(String category, String source) {
    return '$category · 来源：$source';
  }

  @override
  String get draftRuleUpdatesTitle => '发送后规则优化记录';

  @override
  String get chatTitle => 'AI 改稿';

  @override
  String get chatSubtitle => '告诉 AI 怎么改，修改后的正文会自动更新到左侧';

  @override
  String get chatEmptyActive =>
      '和 AI 对话来修改草稿，例如：\n「语气更诚恳一点」「开头加上感谢反馈」「去掉具体天数承诺」';

  @override
  String get chatEmptyLocked => '草稿已定稿，对话已停用';

  @override
  String get chatInputHint => '告诉 AI 怎么修改草稿…';

  @override
  String get chatSendButton => '修改';

  @override
  String get chatCollapseBody => '收起正文';

  @override
  String get chatExpandBody => '正文已更新，点击查看';

  @override
  String get chatBusy => 'AI 正在修改草稿…';

  @override
  String chatRefineFailed(String error) {
    return '修改失败：$error';
  }

  @override
  String get kbImportButton => '导入 .md / .txt 文档';

  @override
  String get kbGenerateButton => '为待生成文档生成规则';

  @override
  String get kbSubtitle => '售后政策 / FAQ / 商品信息 → 提炼为回复规则；文档内容变更后可重新生成（旧规则会被替换）';

  @override
  String get kbEmpty => '暂无文档。导入 .md / .txt 文件后即可生成回复规则';

  @override
  String kbDocSubtitle(String time, String size, String hash, String status) {
    return '导入于 $time · $size KB · 内容 $hash · $status';
  }

  @override
  String get kbStatusPending => '尚未生成规则';

  @override
  String get kbStatusStale => '内容已变更，待重新生成';

  @override
  String get kbStatusFresh => '规则已是最新';

  @override
  String get kbDeleteDoc => '删除文档';

  @override
  String get commonEmpty => '';

  @override
  String commonRawError(String text) {
    return '$text';
  }

  @override
  String get commonErrorSeparator => '；';

  @override
  String get llmReasonNoneConfigured => '请先在设置中配置大模型，并在空间中分配';

  @override
  String get llmReasonNotAssigned => '设置中已配置大模型，请在「空间」页为当前空间分配大模型';

  @override
  String get llmReasonDeleted => '当前空间分配的大模型已被删除，请在「空间」页重新分配';

  @override
  String get llmReasonIncomplete => '当前空间分配的大模型配置不完整（缺接口地址或模型名），请在「设置」页完善';

  @override
  String get llmErrNotConfigured => '请先填写 Base URL 和模型名';

  @override
  String get llmErrTruncated =>
      '输出被 max_tokens 截断（推理型模型的思考也计入预算），请调大 max tokens';

  @override
  String get llmErrEmptyPlain => '模型未返回任何内容';

  @override
  String llmErrEmptyReason(String reason) {
    return '模型未返回任何内容（finish_reason=$reason）';
  }

  @override
  String llmErrNotJson(String error) {
    return '模型多次未能输出合法 JSON：$error';
  }

  @override
  String llmErrHttp(String status, String detail) {
    return 'HTTP $status：$detail';
  }

  @override
  String llmErrTimeout(num seconds) {
    return '请求超时（${seconds}s），可在设置中调大超时';
  }

  @override
  String get llmErrNetwork => '网络错误';

  @override
  String mailOpTimeout(num seconds) {
    return '邮件操作超过 $seconds 秒未完成，已中止（网络不通或服务器无响应，可稍后刷新重试）';
  }

  @override
  String get mailOauthNotAuthorized =>
      '该账号为 OAuth2 登录（Outlook），请先在账号设置里完成 Microsoft 授权';

  @override
  String get mailReceiveIncomplete => '邮箱账号收信配置不完整（地址/IMAP 服务器/密码）';

  @override
  String get mailSendIncomplete => '邮箱账号发信配置不完整（地址/SMTP 服务器/密码）';

  @override
  String mailConnectTimeout(String host, num port) {
    return '连接 $host:$port 超时（已自动重试一次）：服务器完成 TLS 后无响应，通常是代理/VPN 节点丢包——请切换代理节点、或暂时关闭代理后重试';
  }

  @override
  String get mailTokenRefreshStall =>
      '刷新 Microsoft 令牌停滞（两轮各 22 秒均无任何进展）：应用直连 login.microsoftonline.com 被网络层拦截——请在代理软件中切换节点、改用全局模式或暂时关闭代理后重试';

  @override
  String get mailFrTokenTimeout =>
      '无法刷新 Microsoft 令牌：应用直连 login.microsoftonline.com 被拦截（通常是代理/VPN 问题）。请在代理软件中切换节点或改用全局模式后重试；现在网络恢复时也会自动好转。';

  @override
  String mailFrInvalidGrant(String raw) {
    return 'Microsoft 授权已失效（$raw），请在「空间」页的账号设置里重新登录';
  }

  @override
  String mailFrAuthRejected(String raw) {
    return '登录被服务器拒绝（$raw）。Outlook 个人账号需先在网页版开启 IMAP：设置 → 邮件 → 同步邮件 → POP 和 IMAP；企业账号请联系管理员放行 IMAP';
  }

  @override
  String oauthBrowserFailed(String url) {
    return '无法唤起系统浏览器，请手动打开此链接完成授权：\n$url';
  }

  @override
  String get oauthWaitTimeout => '等待浏览器授权超时（5 分钟未完成），请重试';

  @override
  String get oauthStateMismatch => '授权回调校验失败（state 不匹配），请重试';

  @override
  String oauthAccessDenied(String detail) {
    return '你取消了授权$detail';
  }

  @override
  String oauthRejected(String error, String detail) {
    return '授权被拒绝：$error$detail';
  }

  @override
  String get oauthNoCode => '授权回调缺少 code，请重试';

  @override
  String get oauthTokenTimeout =>
      '连接微软令牌服务超时（20 秒无响应）：直连可能被代理/VPN 拦截，请检查代理软件（可尝试切换节点或全局模式）后重试';

  @override
  String oauthConnectFailed(String error) {
    return '连接微软令牌服务失败：$error';
  }

  @override
  String oauthHttpError(String status, String detail) {
    return '微软令牌接口返回 HTTP $status：$detail';
  }

  @override
  String get oauthNoBody => '无响应体';

  @override
  String oauthTokenError(String error, String detail) {
    return '微软返回授权错误：$error$detail';
  }

  @override
  String oauthParseFailed(String error) {
    return '解析微软返回的令牌失败：$error';
  }

  @override
  String get learnFetchingHistory => '正在拉取历史邮件…';

  @override
  String learnFetchingFolder(String email, String folder, num months) {
    return '正在拉取 $email 的 $folder（近 $months 个月）…';
  }

  @override
  String learnFetchingDetected(String email, String folder) {
    return '正在拉取 $email 的 $folder（自动识别）…';
  }

  @override
  String learnFetchingInbox(String email) {
    return '正在拉取 $email 的 INBOX（配对客户来信）…';
  }

  @override
  String learnFailedNote(num count) {
    return '；$count 个账号/文件夹拉取失败（详见下方警告）';
  }

  @override
  String learnRecoveredNote(num count) {
    return '；$count 个账号的学习文件夹已自动识别并更新配置';
  }

  @override
  String learnNoNewEmails(String failed, String recovered) {
    return '没有新的可学习邮件（均已消费过或超出时间范围）$failed$recovered';
  }

  @override
  String learnDone(
    num added,
    num updated,
    num consumed,
    String failed,
    String recovered,
  ) {
    return '学习完成：新增 $added 条规则，更新 $updated 条，消费 $consumed 封邮件$failed$recovered';
  }

  @override
  String get learnErrNeedSpace => '请先在「空间」页创建空间并配置邮箱账号';

  @override
  String get learnErrIncomplete => '空间内的邮箱账号均未配置完整（缺服务器或密码）';

  @override
  String learnErrFailed(String error) {
    return '学习失败：$error';
  }

  @override
  String get learnErrNoRulesArray => '模型输出对象中不含规则数组';

  @override
  String learnErrNotRulesArray(String type) {
    return '模型输出不是规则数组（$type）';
  }

  @override
  String learnStageAnalyzing(num index, num total) {
    return '正在分析第 $index/$total 批往来邮件';
  }

  @override
  String learnStageMerging(num index, num total) {
    return '正在合并规则（第 $index/$total 批）';
  }

  @override
  String kbStageExtracting(String doc, num index, num total) {
    return '正在从《$doc》提取规则（片段 $index/$total）';
  }

  @override
  String get kbImporting => '正在导入文档…';

  @override
  String kbImported(num count) {
    return '导入完成，共 $count 个文档';
  }

  @override
  String kbImportFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get kbPreparing => '准备生成规则…';

  @override
  String get kbNoDocs => '没有需要生成规则的文档';

  @override
  String kbGenerated(num docs, num rules) {
    return '已为 $docs 个文档生成 $rules 条规则';
  }

  @override
  String kbGenerateFailed(String error) {
    return '生成失败：$error';
  }

  @override
  String get inboxPreparing => '准备同步…';

  @override
  String inboxSyncing(String email, String role) {
    return '正在同步 $email $role…';
  }

  @override
  String get inboxErrNoSpace => '请先在「空间」页创建空间并配置邮箱账号';

  @override
  String get inboxErrNoReceiver => '当前空间没有开启收信的账号';

  @override
  String inboxErrIncomplete(String email, String reason) {
    return '$email：配置不完整（$reason）';
  }

  @override
  String get inboxReasonNoImap => '缺 IMAP 服务器配置';

  @override
  String get inboxReasonOauth => '尚未完成 Microsoft 授权（在账号设置里重新登录）';

  @override
  String get inboxReasonNoPassword => '缺密码（钥匙串未返回该账号的授权码）';

  @override
  String inboxErrSentMissing(String email) {
    return '$email：未找到已发送文件夹，已跳过';
  }

  @override
  String inboxErrSyncFailedCached(String email, String role, String error) {
    return '$email $role：同步失败（展示缓存）：$error';
  }

  @override
  String inboxErrSyncFailed(String email, String role, String error) {
    return '$email $role：$error';
  }

  @override
  String inboxErrInterrupted(String error) {
    return '刷新中断：$error';
  }

  @override
  String get draftsErrNeedSpace => '请先创建空间';

  @override
  String get draftsMsgExisting => '这封邮件已有进行中的草稿，已为你打开';

  @override
  String get draftsErrRulesEmpty =>
      '规则库为空：草稿只能依据回复规则生成，请先在学习中心 / 知识库 / 规则库生成规则';

  @override
  String get draftsErrRulesDisabled => '当前规则全部处于停用状态，请先在规则库启用规则';

  @override
  String get draftsErrRulesEmptyGen => '规则库为空，请先从历史邮件、知识库或自定义 Prompt 生成回复规则';

  @override
  String draftsErrGenerateFailed(String error) {
    return '生成草稿失败：$error';
  }

  @override
  String get draftsErrNoSender => '当前空间没有可用于发信的账号（请在空间管理中开启账号的发信能力）';

  @override
  String draftsErrSendFailed(String error) {
    return '发送失败：$error';
  }

  @override
  String get draftsErrNoBody => '模型未返回修改后的正文';

  @override
  String draftsFbSent(String feedback) {
    return '已发送。$feedback';
  }

  @override
  String get draftsFbModifiedNoAdjust => '检测到修改，规则库已优化：本次无需调整';

  @override
  String draftsFbModifiedUpdates(String updates) {
    return '检测到修改，规则库已优化：$updates';
  }

  @override
  String get draftsFbUnmodified => '草稿未被修改，相关规则获得正反馈';

  @override
  String draftsFbFailed(String error) {
    return '但规则反馈学习失败：$error';
  }

  @override
  String get draftsFbSkipped => '（未配置大模型，跳过规则反馈学习）';

  @override
  String get draftsMarkedPlain => '已标注为手工发送。该内容会计入后续草稿生成与学习的参考。';

  @override
  String draftsMarkedWithFeedback(String feedback) {
    return '已标注为手工发送。$feedback';
  }
}
