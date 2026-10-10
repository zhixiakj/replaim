import 'app_localizations.dart';
import 'messages.dart';

/// 把状态 / 异常里结构化存的 [L10nMsg] 解析成当前语言的文案。
/// args 里的 L10nMsg 会先递归解析再填入占位符。
String resolveL10nMsg(AppLocalizations l10n, L10nMsg msg) {
  final a = [
    for (final v in msg.args) v is L10nMsg ? resolveL10nMsg(l10n, v) : v
  ];
  String s(int i) => a[i].toString();
  int n(int i) => a[i] as int;
  return switch (msg.key) {
    // ---------------- 通用 ----------------
    'commonEmpty' => l10n.commonEmpty,
    'commonRawError' => l10n.commonRawError(s(0)),

    // ---------------- LLM 不可用原因 ----------------
    'llmReasonNoneConfigured' => l10n.llmReasonNoneConfigured,
    'llmReasonNotAssigned' => l10n.llmReasonNotAssigned,
    'llmReasonDeleted' => l10n.llmReasonDeleted,
    'llmReasonIncomplete' => l10n.llmReasonIncomplete,

    // ---------------- LLM 客户端错误 ----------------
    'llmErrNotConfigured' => l10n.llmErrNotConfigured,
    'llmErrTruncated' => l10n.llmErrTruncated,
    'llmErrEmptyPlain' => l10n.llmErrEmptyPlain,
    'llmErrEmptyReason' => l10n.llmErrEmptyReason(s(0)),
    'llmErrNotJson' => l10n.llmErrNotJson(s(0)),
    'llmErrHttp' => l10n.llmErrHttp(s(0), s(1)),
    'llmErrTimeout' => l10n.llmErrTimeout(n(0)),

    // ---------------- 邮件服务 ----------------
    'mailOpTimeout' => l10n.mailOpTimeout(n(0)),
    'mailOauthNotAuthorized' => l10n.mailOauthNotAuthorized,
    'mailReceiveIncomplete' => l10n.mailReceiveIncomplete,
    'mailSendIncomplete' => l10n.mailSendIncomplete,
    'mailConnectTimeout' => l10n.mailConnectTimeout(s(0), n(1)),
    'mailTokenRefreshStall' => l10n.mailTokenRefreshStall,
    'mailFrTokenTimeout' => l10n.mailFrTokenTimeout,
    'mailFrInvalidGrant' => l10n.mailFrInvalidGrant(s(0)),
    'mailFrAuthRejected' => l10n.mailFrAuthRejected(s(0)),

    // ---------------- Microsoft OAuth ----------------
    'oauthBrowserFailed' => l10n.oauthBrowserFailed(s(0)),
    'oauthWaitTimeout' => l10n.oauthWaitTimeout,
    'oauthStateMismatch' => l10n.oauthStateMismatch,
    'oauthAccessDenied' => l10n.oauthAccessDenied(s(0)),
    'oauthRejected' => l10n.oauthRejected(s(0), s(1)),
    'oauthNoCode' => l10n.oauthNoCode,
    'oauthTokenTimeout' => l10n.oauthTokenTimeout,
    'oauthConnectFailed' => l10n.oauthConnectFailed(s(0)),
    'oauthHttpError' => l10n.oauthHttpError(s(0), s(1)),
    'oauthNoBody' => l10n.oauthNoBody,
    'oauthTokenError' => l10n.oauthTokenError(s(0), s(1)),
    'oauthParseFailed' => l10n.oauthParseFailed(s(0)),

    // ---------------- 学习中心 ----------------
    'learnFetchingHistory' => l10n.learnFetchingHistory,
    'learnFetchingFolder' =>
      l10n.learnFetchingFolder(s(0), s(1), n(2)),
    'learnFetchingDetected' => l10n.learnFetchingDetected(s(0), s(1)),
    'learnFetchingInbox' => l10n.learnFetchingInbox(s(0)),
    'learnFailedNote' => l10n.learnFailedNote(n(0)),
    'learnRecoveredNote' => l10n.learnRecoveredNote(n(0)),
    'learnNoNewEmails' => l10n.learnNoNewEmails(s(0), s(1)),
    'learnDone' => l10n.learnDone(n(0), n(1), n(2), s(3), s(4)),
    'learnErrNeedSpace' => l10n.learnErrNeedSpace,
    'learnErrIncomplete' => l10n.learnErrIncomplete,
    'learnErrFailed' => l10n.learnErrFailed(s(0)),
    'learnErrNoRulesArray' => l10n.learnErrNoRulesArray,
    'learnErrNotRulesArray' => l10n.learnErrNotRulesArray(s(0)),
    'learnStageAnalyzing' => l10n.learnStageAnalyzing(n(0), n(1)),
    'learnStageMerging' => l10n.learnStageMerging(n(0), n(1)),
    'kbStageExtracting' => l10n.kbStageExtracting(s(0), n(1), n(2)),

    // ---------------- 知识库 ----------------
    'kbImporting' => l10n.kbImporting,
    'kbImported' => l10n.kbImported(n(0)),
    'kbImportFailed' => l10n.kbImportFailed(s(0)),
    'kbPreparing' => l10n.kbPreparing,
    'kbNoDocs' => l10n.kbNoDocs,
    'kbGenerated' => l10n.kbGenerated(n(0), n(1)),
    'kbGenerateFailed' => l10n.kbGenerateFailed(s(0)),

    // ---------------- 收件箱 ----------------
    'inboxPreparing' => l10n.inboxPreparing,
    'inboxSyncing' => l10n.inboxSyncing(s(0), s(1)),
    'inboxErrNoSpace' => l10n.inboxErrNoSpace,
    'inboxErrNoReceiver' => l10n.inboxErrNoReceiver,
    'inboxErrIncomplete' => l10n.inboxErrIncomplete(s(0), s(1)),
    'inboxReasonNoImap' => l10n.inboxReasonNoImap,
    'inboxReasonOauth' => l10n.inboxReasonOauth,
    'inboxReasonNoPassword' => l10n.inboxReasonNoPassword,
    'inboxErrSentMissing' => l10n.inboxErrSentMissing(s(0)),
    'inboxErrSyncFailedCached' =>
      l10n.inboxErrSyncFailedCached(s(0), s(1), s(2)),
    'inboxErrSyncFailed' => l10n.inboxErrSyncFailed(s(0), s(1), s(2)),
    'inboxErrInterrupted' => l10n.inboxErrInterrupted(s(0)),

    // ---------------- 草稿 ----------------
    'draftsErrNeedSpace' => l10n.draftsErrNeedSpace,
    'draftsMsgExisting' => l10n.draftsMsgExisting,
    'draftsErrRulesEmpty' => l10n.draftsErrRulesEmpty,
    'draftsErrRulesDisabled' => l10n.draftsErrRulesDisabled,
    'draftsErrRulesEmptyGen' => l10n.draftsErrRulesEmptyGen,
    'draftsErrGenerateFailed' => l10n.draftsErrGenerateFailed(s(0)),
    'draftsErrNoSender' => l10n.draftsErrNoSender,
    'draftsErrSendFailed' => l10n.draftsErrSendFailed(s(0)),
    'draftsErrNoBody' => l10n.draftsErrNoBody,
    'draftsFbSent' => l10n.draftsFbSent(s(0)),
    'draftsFbModifiedNoAdjust' => l10n.draftsFbModifiedNoAdjust,
    'draftsFbModifiedUpdates' => l10n.draftsFbModifiedUpdates(s(0)),
    'draftsFbUnmodified' => l10n.draftsFbUnmodified,
    'draftsFbFailed' => l10n.draftsFbFailed(s(0)),
    'draftsFbSkipped' => l10n.draftsFbSkipped,
    'draftsMarkedPlain' => l10n.draftsMarkedPlain,
    'draftsMarkedWithFeedback' => l10n.draftsMarkedWithFeedback(s(0)),

    // ---------------- 空间页测试连接结果 ----------------
    'spacesTestOkFoldersMatched' => l10n.spacesTestOkFoldersMatched(s(0)),
    'spacesTestFoldersMissing' => l10n.spacesTestFoldersMissing(s(0)),
    'spacesTestOkImap' => l10n.spacesTestOkImap,

    // 未知 key：显示 key 本身，开发期能立刻发现漏网的消息。
    _ => msg.key,
  };
}
