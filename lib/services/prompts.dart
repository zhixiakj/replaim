/// 所有 LLM prompt 模板集中在此，便于统一调整语气与约束。
///
/// 通用约定：
/// - 规则内容用中文书写（操作台语言，便于用户阅读维护）；
/// - 草稿正文用配置的输出语言（默认英文）；
/// - 要求 JSON 输出的地方，字段名统一 snake_case。
library;

const ruleCategorySpec =
    'category 取值：tone（语气风格）/ policy（售后政策）/ format（格式结构）/ '
    'product（商品信息）/ compliance（平台合规）/ other（其他）';

const ruleJsonSpec =
    '[{"category": "...", "content": "...", "reason": "为什么从材料中得出这条规则"}]';

/// 1. 历史邮件 → 规则。
///
/// [batchText] 是按时间升序排列的往来邮件文本。
String emailRulesPrompt(String batchText, String dateRange) => '''
你是一名客服邮件专家。下面是一批真实的客服往来邮件（$dateRange，按时间从早到晚排列）。
每封邮件标注了「角色」：客户 = 来信提问的一方，我方 = 写回复的一方。
请从这些成对的「问 → 答」中提炼「回复规则」——以后起草客服回复时可复用的做法，包括但不限于：
- 常见问答口径：客户问了什么（退款、换货、物流、评价等）、我方的标准答法是什么（问法→怎么答）
- 语气与称呼习惯（开头/结尾套路、正式程度）
- 结构习惯（先道歉还是先给方案、是否分点、是否给时效承诺）
- 平台合规红线（如 Amazon 禁止外链、禁止引导站外交易）
- 签名与落款

要求：
- 只依据给出的邮件，不要推测邮件中没有的做法；
- 每条规则一句话说清「怎么做」，具体可执行；
- 重复出现的做法合并为一条；只出现过一次但明确的做法也可保留；
- 忽略一次性、偶发的内容（例如某个具体订单号的处理）。

输出 JSON 数组，不要输出其他文字：
$ruleJsonSpec

邮件材料：
$batchText''';

/// 2. 新旧规则合并。
///
/// 冲突时新规则胜出——新规则来自更新的邮件，反映卖家当前的口径；
/// 这保证旧邮件不会覆盖新邮件沉淀的规则。
String mergeRulesPrompt(String existingRulesText, String newRulesText) => '''
你是规则库管理员。现有规则库与一批新提取的规则如下。
请把新规则合并进规则库，输出合并操作列表。

合并原则：
1. 新规则与某条现有规则语义相同或包含 → 输出 {"op": "skip", "target_id": "该规则id"}；
2. 新规则是对某条现有规则的更新（做法变了、口径变了）→ 输出 {"op": "update", "target_id": "该规则id", "content": "合并后的新内容", "reason": "变化说明"}；
3. 新规则与现有规则矛盾（冲突）→ 以新规则为准（新规则来自更新的材料），输出 {"op": "update", "target_id": "被替代的规则id", "content": "新规则内容", "reason": "旧规则已过时的原因"}；
4. 新规则是全新做法 → 输出 {"op": "add", "category": "...", "content": "...", "reason": "..."}；
5. 拿不准就 skip，宁缺毋滥。

$ruleCategorySpec。
输出 JSON 数组，不要输出其他文字：
[{"op": "skip|update|add", "target_id": "现有规则id（skip/update 必填，add 为空）", "category": "add 时必填", "content": "add/update 时的新内容", "reason": "说明"}]

现有规则库（id | 类目 | 内容）：
$existingRulesText

新提取的规则：
$newRulesText''';

/// 3. 知识库 → 规则。
String kbRulesPrompt(String docName, String chunkText) => '''
你是一名客服邮件专家。下面是知识库文档《$docName》的一个片段（商品信息/售后政策/FAQ 等）。
请从中提炼「回复规则」：起草客服回复时应该如何引用、如何执行这些信息。

要求：
- 规则要写成「怎么做」，而不是抄录原文；涉及具体政策数字（如退款天数、运费承担）要原样保留；
- 无法转化为回复做法的背景性内容直接忽略；
- 每条规则一句话，具体可执行。

输出 JSON 数组，不要输出其他文字：
$ruleJsonSpec

文档片段：
$chunkText''';

/// 4. 用户自定义 prompt → 规范化规则。
String userPromptRulesPrompt(String promptText) => '''
用户给了一条自定义指示，请把它拆解/改写为若干条独立、可执行的「回复规则」。
尽量保留用户原意，不要添加用户没有说的要求。如果指示本身就是一条规则，输出一条即可。

输出 JSON 数组，不要输出其他文字：
$ruleJsonSpec

用户指示：
$promptText''';

/// 5. 生成草稿（只用规则，不看其他材料）。
String draftPrompt({
  required String incomingEmail,
  required String threadContext,
  required String rulesText,
  required String language,
}) => '''
你是客服邮件起草助手。请严格依据下面给出的「回复规则」起草一封对来信的回复。

铁律：
1. 只能依据回复规则起草，规则未覆盖的信息不得编造、不得自行补充政策或承诺；
2. 若来信涉及规则没有覆盖的问题，在草稿中礼貌说明需要稍后确认，不要猜测答案；
3. 遵守规则中的语气、结构、格式与合规要求；
4. 输出语言：$language；
5. 只输出邮件正文本身（含称呼与落款），不要输出主题行、不要任何解释或前后缀。

来信：
$incomingEmail

${threadContext.isEmpty ? '' : '此前的往来（供理解语境，不要直接引用内容）：\n$threadContext\n'}
回复规则（唯一依据）：
$rulesText''';

/// 6. 草稿修改 → 规则优化。
String draftFeedbackPrompt({
  required String originalDraft,
  required String finalSent,
  required String rulesText,
  required String diffSummary,
}) => '''
用户修改了 AI 起草的客服邮件并发出。请对比原始草稿与用户实际发出的版本，
分析用户的修改表达了什么偏好，并决定如何优化当时使用的「回复规则」。

分析要点：
- 删掉了什么（如客套话、道歉、免责声明）？
- 加了什么（如具体承诺、折扣、追问）？
- 语气/长度/结构怎么变了？
- 这些修改是普适偏好（应沉淀为规则更新）还是针对这一单的临时处理（不应改规则）？
  拿不准就不要改（输出空数组）。

可输出的操作：
- {"op": "add", "category": "...", "content": "...", "reason": "新规则"}：用户展现出全新且普适的做法；
- {"op": "update", "target_id": "规则id", "content": "更新后的内容", "reason": "用户修改说明了该规则应如何调整"}；
- {"op": "disable", "target_id": "规则id", "reason": "用户总是删掉该规则导致的内容，该规则应停用"}。

$ruleCategorySpec。
同时请给出一段中文「修改摘要」（50 字内），概括用户改了什么。
输出 JSON 对象，不要输出其他文字：
{"change_summary": "...", "operations": [...]}

原始草稿：
$originalDraft

用户实际发出的版本：
$finalSent

文本差异（供参考）：
$diffSummary

当时使用的回复规则（id | 类目 | 内容）：
$rulesText''';

/// 7. 线程上下文摘要（供草稿 prompt 使用，压缩历史往来）。
String threadDigestPrompt(String threadText) => '''
用中文简要概括下面这组往来邮件的关键信息（每封一行：谁、何时、说了什么、结论是什么），
不要任何多余解释：

$threadText''';

/// 8. AI 对话改稿：按用户指示输出修改后的完整草稿正文。
///
/// [historyText] 是此前几轮「用户指示 → AI 概括」的对话记录（可为空），
/// 让模型理解累积的修改意图。
String refineDraftPrompt({
  required String currentDraft,
  required String historyText,
  required String instruction,
  required String language,
}) => '''
你是邮件草稿修改助手。用户会给出对当前草稿的修改指示，请输出修改后的完整邮件正文。

铁律：
1. 只按用户指示及其直接含义修改，不要自行补充原草稿中没有的信息、政策或承诺；
2. 未被指示修改的部分保持原样；
3. 正文语言保持与当前草稿一致（$language）；
4. body 必须是完整的邮件正文（含称呼与落款），不是片段或差异说明。

输出 JSON 对象，不要输出其他文字：
{"brief": "一句话中文说明本次改了什么", "body": "修改后的完整正文"}

${historyText.isEmpty ? '' : '此前的修改对话（供理解意图，正文以当前草稿为准）：\n$historyText\n'}
当前草稿：
$currentDraft

用户本轮指示：
$instruction''';
