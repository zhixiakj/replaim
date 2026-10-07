import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 规则 ID：rule_ + 8 位短随机串，短且可读，便于在 YAML 与日志中比对。
String newRuleId() => 'rule_${_uuid.v4().substring(0, 8)}';

/// 草稿 ID。
String newDraftId() => 'draft_${_uuid.v4().substring(0, 8)}';

/// 空间 ID。
String newSpaceId() => 'space_${_uuid.v4().substring(0, 8)}';

/// 邮箱账号 ID（密码等敏感信息以其为命名空间键）。
String newAccountId() => 'acct_${_uuid.v4().substring(0, 8)}';

/// LLM Profile ID（API Key 以其为命名空间键）。
String newLlmId() => 'llm_${_uuid.v4().substring(0, 8)}';

/// 普通短 ID。
String newId() => _uuid.v4();
