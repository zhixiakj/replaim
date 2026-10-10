import '../models/draft_record.dart';
import '../models/rule.dart';
import 'app_localizations.dart';

/// 模型层枚举的显示名：模型存原始枚举，UI 层按 locale 解析显示文本。
/// （枚举上的 .label 旧中文实现仅作兼容，新代码一律用这里的函数。）

String ruleSourceTypeLabel(AppLocalizations l10n, RuleSourceType type) =>
    switch (type) {
      RuleSourceType.emailHistory => l10n.ruleSourceEmailHistory,
      RuleSourceType.knowledgeBase => l10n.ruleSourceKnowledgeBase,
      RuleSourceType.userPrompt => l10n.ruleSourceUserPrompt,
      RuleSourceType.draftFeedback => l10n.ruleSourceDraftFeedback,
      RuleSourceType.manual => l10n.ruleSourceManual,
    };

String ruleCategoryLabel(AppLocalizations l10n, RuleCategory category) =>
    switch (category) {
      RuleCategory.tone => l10n.ruleCategoryTone,
      RuleCategory.policy => l10n.ruleCategoryPolicy,
      RuleCategory.format => l10n.ruleCategoryFormat,
      RuleCategory.product => l10n.ruleCategoryProduct,
      RuleCategory.compliance => l10n.ruleCategoryCompliance,
      RuleCategory.other => l10n.ruleCategoryOther,
    };

String draftStatusLabel(AppLocalizations l10n, DraftStatus status) =>
    switch (status) {
      DraftStatus.editing => l10n.draftStatusEditing,
      DraftStatus.sentUnmodified => l10n.draftStatusSentUnmodified,
      DraftStatus.sentEdited => l10n.draftStatusSentEdited,
      DraftStatus.sentManually => l10n.draftStatusSentManually,
      DraftStatus.discarded => l10n.draftStatusDiscarded,
    };
