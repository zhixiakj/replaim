// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Replaim Email Copilot';

  @override
  String get navInbox => 'Inbox';

  @override
  String get navDrafts => 'Drafts';

  @override
  String get navRules => 'Rules';

  @override
  String get navKb => 'Knowledge';

  @override
  String get navLearn => 'Learning';

  @override
  String get navSpaces => 'Spaces';

  @override
  String get navSettings => 'Settings';

  @override
  String get switchSpaceTooltip => 'Switch space';

  @override
  String accountsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts',
      one: '1 account',
    );
    return '$_temp0';
  }

  @override
  String get noSpaceSelected => 'No space selected';

  @override
  String get loading => 'Loading…';

  @override
  String spaceReceiveSend(num receive, num send) {
    return '$receive in / $send out';
  }

  @override
  String get newSpaceTooltip => 'New space';

  @override
  String get newSpaceTitle => 'New space';

  @override
  String get spaceNameLabel => 'Space name (e.g. store / brand)';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonJoinSeparator => ', ';

  @override
  String get commonDone => 'Done';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSend => 'Send';

  @override
  String get commonSending => 'Sending…';

  @override
  String get commonEmptyValue => '(empty)';

  @override
  String get commonTesting => 'Testing…';

  @override
  String get commonTestConnection => 'Test connection';

  @override
  String settingsSummary(num count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rules enabled in the current space',
      one: '1 rule enabled in the current space',
    );
    return '$_temp0 · Data folder: $path';
  }

  @override
  String get settingsGeneralTitle => 'General';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsLanguageSystem => 'Follow system';

  @override
  String get settingsLlmSectionTitle => 'LLM (global, OpenAI-compatible APIs)';

  @override
  String settingsLlmSectionSubtitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spaces have a model assigned',
      one: '1 space has a model assigned',
      zero: 'No space has a model assigned yet',
    );
    return '$_temp0. Configure multiple model endpoints here, then assign them to spaces on the Spaces page.';
  }

  @override
  String get settingsLlmEmpty =>
      'No model configured yet. Click the button below to add one.';

  @override
  String llmProfileTitle(String name, String model) {
    return '$name ($model)';
  }

  @override
  String get settingsAddLlm => 'Add LLM';

  @override
  String get settingsAddLlmTitle => 'Add LLM';

  @override
  String get settingsEditLlmTitle => 'Edit LLM';

  @override
  String get settingsLlmFieldName => 'Name (e.g. DeepSeek, company GPT)';

  @override
  String get settingsLlmFieldBaseUrl =>
      'API base URL (usually ends with /v1), e.g. https://api.deepseek.com/v1';

  @override
  String get settingsLlmFieldModel => 'Model name, e.g. deepseek-chat';

  @override
  String get settingsLlmFieldApiKey =>
      'API key (leave blank when editing to keep)';

  @override
  String get settingsLlmFieldTemperature => 'Temperature';

  @override
  String get settingsLlmFieldMaxTokens => 'Max tokens';

  @override
  String get settingsLlmFieldTimeout => 'Timeout (s)';

  @override
  String settingsLlmTestOk(String endpoint) {
    return 'Connection OK ($endpoint)';
  }

  @override
  String get settingsLlmUnnamed => 'Unnamed model';

  @override
  String get settingsLlmSaved => 'LLM configuration saved';

  @override
  String settingsLlmDeleteTitle(String name) {
    return 'Delete model \"$name\"';
  }

  @override
  String get settingsLlmDeleteUnused => 'This model is not used by any space.';

  @override
  String settingsLlmDeleteInUse(String spaces) {
    return 'These spaces are using this model and will become unassigned after deletion:\n$spaces';
  }

  @override
  String get settingsPromptSectionTitle => 'Custom prompt rules';

  @override
  String get settingsPromptSectionSubtitle =>
      'Turn your reply requirements into rules (saved to the current space, used for drafting together with history and knowledge-base rules)';

  @override
  String get settingsPromptHint =>
      'e.g. Apologize first, then offer a solution for all refund emails; sign off with \"Best regards, Amy\"';

  @override
  String get settingsPromptSplitButton =>
      'Split into rules with LLM (recommended)';

  @override
  String get settingsPromptDirectButton => 'Add as a single rule';

  @override
  String get settingsPromptEmpty => 'No custom prompt rules yet';

  @override
  String get settingsPromptSplitting => 'Splitting into rules…';

  @override
  String get settingsPromptConfirmTitle => 'Review generated rules';

  @override
  String get settingsPromptAddSelected => 'Add selected';

  @override
  String settingsPromptAddedRules(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count rules',
      one: 'Added 1 rule',
    );
    return '$_temp0';
  }

  @override
  String settingsPromptSplitFailed(String error) {
    return 'Split failed: $error';
  }

  @override
  String get settingsPromptAddedOne => 'Rule added';

  @override
  String get ruleSourceEmailHistory => 'History emails';

  @override
  String get ruleSourceKnowledgeBase => 'Knowledge base';

  @override
  String get ruleSourceUserPrompt => 'Custom prompt';

  @override
  String get ruleSourceDraftFeedback => 'Draft edit feedback';

  @override
  String get ruleSourceManual => 'Manual';

  @override
  String get ruleCategoryTone => 'Tone & style';

  @override
  String get ruleCategoryPolicy => 'After-sales policy';

  @override
  String get ruleCategoryFormat => 'Format & structure';

  @override
  String get ruleCategoryProduct => 'Product info';

  @override
  String get ruleCategoryCompliance => 'Platform compliance';

  @override
  String get ruleCategoryOther => 'Other';

  @override
  String get spacesTitle => 'Spaces';

  @override
  String get spacesEmptyIntro =>
      'A space is an independent business context (e.g. a store / brand):\n· One shared set of reply rules and knowledge base per space\n· Multiple email accounts, each with its own receive (IMAP) and send (SMTP) toggles\n· Forwarded mail (e.g. customer writes support@, forwarded to a configured account) is detected: the original recipient is CC\'d on replies';

  @override
  String get spacesCreateFirst => 'Create your first space';

  @override
  String spacesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spaces',
      one: '1 space',
    );
    return '$_temp0';
  }

  @override
  String get spacesCurrentBadge => 'Current';

  @override
  String spacesAccountSummary(num accounts, num receive, num send) {
    String _temp0 = intl.Intl.pluralLogic(
      accounts,
      locale: localeName,
      other: '$accounts accounts',
      one: '1 account',
    );
    return '$_temp0 · $receive in / $send out';
  }

  @override
  String get spacesDeleteTooltip => 'Delete space';

  @override
  String spacesDeleteTitle(String name) {
    return 'Delete space \"$name\"';
  }

  @override
  String get spacesDeleteContent =>
      'This will delete the space\'s rules, knowledge base, learning state and draft records, plus the stored passwords of all its accounts.\nThis cannot be undone.';

  @override
  String spacesDetailTitle(String name) {
    return 'Space: $name';
  }

  @override
  String get spacesSetCurrent => 'Set as current';

  @override
  String get spacesBasicInfoSection => 'Basics';

  @override
  String get spacesFieldName => 'Space name';

  @override
  String get spacesAssignLlmLabel => 'Assigned LLM (manage models in Settings)';

  @override
  String get spacesLlmUnassigned => 'Unassigned';

  @override
  String get spacesDefaultSendLabel =>
      'Default send account (fallback when a receive account can\'t send)';

  @override
  String get spacesDefaultSendAuto => 'Auto (any account with sending enabled)';

  @override
  String get spacesOutputLanguageLabel =>
      'Draft output language (default English)';

  @override
  String get spacesLearnPrefsSection => 'Learning preferences (per space)';

  @override
  String get spacesLearnMonthsLabel => 'Learning window (recent N months)';

  @override
  String get spacesLearnFoldersHint =>
      'History learn folders are set per email account (folder names vary by provider: Gmail uses [Gmail]/Sent Mail ([Gmail]/已发送邮件 on Chinese-language accounts), QQ/163 use Sent Messages, Outlook uses Sent). Edit each account under \"Email accounts\" below; common names match automatically, and when none match, learning falls back to the server\'s Sent flag.';

  @override
  String spacesAccountsSection(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Email accounts ($count)',
      one: 'Email account (1)',
    );
    return '$_temp0';
  }

  @override
  String get spacesAccountsSubtitle =>
      'Each account can separately enable receive (IMAP) and send (SMTP); replies are sent from the receiving account by default';

  @override
  String get spacesNoAccounts =>
      'No accounts yet. Click the button below to add one.';

  @override
  String get spacesAddAccount => 'Add email account';

  @override
  String get spacesAutoSaved => 'Changes save automatically';

  @override
  String spacesDeleteAccountTitle(String email) {
    return 'Delete account $email';
  }

  @override
  String get spacesDeleteAccountContent =>
      'This removes the account\'s configuration and stored password. Space data is unaffected.';

  @override
  String get accountDisabledBadge => 'Disabled';

  @override
  String get accountReceiveBadge => 'Receive';

  @override
  String get accountNoReceiveBadge => 'No receive';

  @override
  String get accountSendBadge => 'Send';

  @override
  String get accountNoSendBadge => 'No send';

  @override
  String get accountDefaultSendBadge => 'Default send';

  @override
  String accountLearnFoldersBadge(String folders) {
    return 'Learn: $folders';
  }

  @override
  String spacesAddAccountTitle(String space) {
    return 'Add email account (space: $space)';
  }

  @override
  String spacesEditAccountTitle(String email) {
    return 'Edit account $email';
  }

  @override
  String get spacesFieldEmail => 'Email address (also used as login username)';

  @override
  String get spacesFieldEmailHelper =>
      'Common providers (Gmail / QQ / 163 / Outlook…) auto-fill the server settings and learn folder below once the address is entered';

  @override
  String get spacesFieldDisplayName => 'From display name (optional)';

  @override
  String get spacesEnableAccount => 'Enable this account';

  @override
  String get spacesEnableAccountSubtitle =>
      'When disabled it stays out of receiving, sending and learning; the configuration is kept and can be re-enabled anytime';

  @override
  String get spacesOauthToggle =>
      'OAuth2 sign-in (required for Outlook: Microsoft has disabled password login)';

  @override
  String get spacesFieldPassword => 'Password / app password';

  @override
  String get spacesTabReceive => 'Receive (IMAP)';

  @override
  String get spacesTabSend => 'Send (SMTP)';

  @override
  String get spacesSaveAccount => 'Save account';

  @override
  String get spacesReceiveToggle =>
      'Receive (IMAP: fetches the inbox, used for learning)';

  @override
  String get spacesFieldImapHost => 'IMAP server, e.g. imap.qq.com';

  @override
  String get spacesFieldPort => 'Port';

  @override
  String get spacesImapSslToggle =>
      'Use SSL for IMAP (usually on for port 993)';

  @override
  String get spacesFieldLearnFolders =>
      'History learn folders (comma-separated, default Sent)';

  @override
  String get spacesLearnFoldersHelper =>
      'Folder names vary by provider: Gmail uses [Gmail]/Sent Mail ([Gmail]/已发送邮件 on Chinese-language accounts), QQ/163 use Sent Messages, Outlook uses Sent. Common names match automatically; if unsure, use the button below to pick from the server';

  @override
  String get spacesLoadFoldersButton => 'Load folder list from server';

  @override
  String get spacesSendToggle => 'Send (SMTP: can be used to send replies)';

  @override
  String get spacesFieldSmtpHost =>
      'SMTP server, e.g. smtp.qq.com (leave empty for receive-only)';

  @override
  String get spacesSmtpSecureToggle =>
      'SMTP encryption (465=SSL / 587=STARTTLS)';

  @override
  String get spacesForcedOffNoOauth => 'Microsoft authorization not completed';

  @override
  String get spacesForcedOffNoPassword =>
      'Password / app password not filled in';

  @override
  String get spacesForcedOffTestFailed => 'Last \"Test connection\" failed';

  @override
  String get spacesErrEmailRequired => 'Please fill in the email address';

  @override
  String spacesSavedDisabled(String email, String reason) {
    return '$email: $reason. Saved as disabled — complete and verify, then enable it in the account list.';
  }

  @override
  String get spacesOauthNeedClientId =>
      'Fill in the Azure app client ID first (the Application (client) ID on the Azure app\'s Overview page)';

  @override
  String spacesOauthSuccess(String expiry) {
    return '✓ Microsoft authorization succeeded (token valid until $expiry, renews automatically)';
  }

  @override
  String spacesOauthFailed(String error) {
    return 'Authorization failed: $error';
  }

  @override
  String spacesFoldersMore(num count) {
    return ' … $count in total';
  }

  @override
  String spacesFoldersMissing(String email, String folders, String existing) {
    return '$email: learn folder(s) \"$folders\" not found on the server (available: $existing). Edit the account and use \"Load folder list from server\" to pick.';
  }

  @override
  String spacesTestOkFoldersMatched(String folders) {
    return 'Connection OK; learn folder(s) \"$folders\" matched ✓';
  }

  @override
  String spacesTestFoldersMissing(String folders) {
    return 'Connection OK; ⚠ learn folder(s) \"$folders\" not found on the server (use the button below to pick from the server)';
  }

  @override
  String get spacesTestOkImap => 'Connection OK (IMAP login verified)';

  @override
  String get spacesPickFoldersNeedOauth =>
      'Fill in the email address and complete Microsoft authorization first';

  @override
  String get spacesPickFoldersNeedCreds =>
      'Fill in the email address, IMAP server and password first';

  @override
  String get spacesPickFoldersTitle => 'Choose history learn folders';

  @override
  String get spacesServerSentBadge => 'Server Sent';

  @override
  String spacesLoadFoldersFailed(String error) {
    return 'Failed to load folders: $error';
  }

  @override
  String get spacesPwdHelperNew =>
      'QQ, 163 and similar providers require an app password generated in the provider\'s console; it is encrypted and stored in the system keychain after saving';

  @override
  String get spacesPwdHelperSaved =>
      'App password saved (the dots are just a placeholder); type a new one to replace it';

  @override
  String get spacesPwdHelperNone => 'No password saved yet';

  @override
  String get spacesOauthClientIdLabel => 'Azure app client ID';

  @override
  String get spacesOauthClientIdHelper =>
      'Register a \"Mobile and desktop application\" in the Azure portal (redirect URI http://localhost, account type including personal Microsoft accounts); multiple Outlook accounts can share one ID';

  @override
  String get spacesOauthWaiting =>
      'Waiting for the browser to finish authorization… (up to 5 minutes)';

  @override
  String get spacesOauthRelogin => 'Sign in to Microsoft account again';

  @override
  String get spacesOauthLogin => 'Sign in to Microsoft account';

  @override
  String get spacesOauthNotYetHint =>
      'Not authorized yet: you can save first (the account stays disabled) and finish sign-in later to enable it (Outlook also requires enabling IMAP in its web settings)';

  @override
  String rulesEnabledSummary(num enabled, num total) {
    return '$enabled of $total enabled';
  }

  @override
  String get rulesAddManual => 'Add manually';

  @override
  String get rulesSearchHint => 'Search rule content';

  @override
  String get rulesFilterAllSources => 'All sources';

  @override
  String get rulesFilterEnabledOnly => 'Enabled only';

  @override
  String get rulesEmpty =>
      'The rule library is empty: learn from history in \"Learning\",\nimport documents into \"Knowledge\", or add a custom prompt in \"Settings\"';

  @override
  String get rulesAddManualTitle => 'Add a rule manually';

  @override
  String get rulesFieldContent => 'Rule content';

  @override
  String get rulesFieldCategory => 'Category';

  @override
  String get rulesSuperseded => 'superseded';

  @override
  String rulesStatsTooltip(num used, num kept, num edited) {
    return 'Used $used times · sent unchanged $kept times · edited $edited times';
  }

  @override
  String rulesUsedTimes(num count) {
    return '$count×';
  }

  @override
  String get rulesDetailTitle => 'Rule detail';

  @override
  String get rulesKvCategory => 'Category';

  @override
  String get rulesKvStatus => 'Status';

  @override
  String get rulesStatusEnabled => 'Enabled';

  @override
  String get rulesStatusDisabled => 'Disabled';

  @override
  String get rulesStatusSuperseded => 'Superseded';

  @override
  String get rulesKvVersion => 'Version';

  @override
  String get rulesKvStats => 'Usage';

  @override
  String rulesStatsDetail(num used, num kept, num edited) {
    return 'Used $used · sent unchanged $kept · edited $edited';
  }

  @override
  String get rulesSourceSection => 'Source (where this rule came from)';

  @override
  String get rulesKvType => 'Type';

  @override
  String get rulesKvGeneratedBy => 'Generated by';

  @override
  String get rulesKvCreatedAt => 'Created';

  @override
  String get rulesHistorySection => 'Version history';

  @override
  String rulesChangeReason(String reason) {
    return 'Change reason: $reason';
  }

  @override
  String get rulesDeleteTitle => 'Delete rule';

  @override
  String get rulesDeleteContent =>
      'This cannot be undone (version history included). Delete?';

  @override
  String get rulesKvDateRange => 'Email date range';

  @override
  String get rulesKvSourceMails => 'Source emails';

  @override
  String rulesSourceMailsDetail(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count emails (Message-IDs are recorded in the learning state, no re-learning)',
      one: '1 email (Message-IDs are recorded in the learning state, no re-learning)',
    );
    return '$_temp0';
  }

  @override
  String get rulesKvDoc => 'Document';

  @override
  String get rulesKvDocVersion => 'Doc version';

  @override
  String get rulesKvUserPrompt => 'User prompt';

  @override
  String get rulesKvSourceDraft => 'Source draft';

  @override
  String get rulesKvChangeSummary => 'Change summary';

  @override
  String get rulesKvReason => 'Reason';

  @override
  String get rulesEditContentTitle => 'Edit rule content';

  @override
  String get inboxRefreshTooltip => 'Refresh';

  @override
  String get inboxRefreshIncremental => 'Refresh (new mail only)';

  @override
  String get inboxRefreshFull => 'Full refresh (rebuild cache)';

  @override
  String get inboxEmpty =>
      'No emails yet. Configure an account in Spaces and refresh';

  @override
  String get inboxNoSelection => 'Select a conversation to view the thread';

  @override
  String get inboxInternalConversation => '(internal to this space)';

  @override
  String get inboxNoBody => '(no body)';

  @override
  String get inboxForwardedTooltip =>
      'Contains forwarded mail; the original recipient is not an account in this space';

  @override
  String get inboxRepliedBadge => 'Replied';

  @override
  String inboxMePrefix(String text) {
    return 'Me: $text';
  }

  @override
  String inboxMessagesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages (sent included)',
      one: '1 message (sent included)',
    );
    return '$_temp0';
  }

  @override
  String inboxDraftsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drafts',
      one: '1 draft',
    );
    return '$_temp0';
  }

  @override
  String get inboxNoIncoming =>
      'No incoming mail in this conversation; can\'t generate a draft';

  @override
  String get inboxTapToSelect =>
      'Click an incoming bubble to enable draft generation';

  @override
  String inboxSelected(String subject) {
    return 'Selected: $subject';
  }

  @override
  String get inboxGenerating => 'Generating…';

  @override
  String get inboxGenerateDraft => 'Generate draft from rules';

  @override
  String inboxForwardedWarning(String recipients, String account) {
    return 'Forward detected: the customer originally wrote to $recipients (not an account in this space). Drafts will be sent via $account with those addresses CC\'d by default; adjust on the draft page.';
  }

  @override
  String get inboxChipDraft => 'Draft';

  @override
  String get inboxChipSentManual => 'Sent · marked manually';

  @override
  String get inboxChipSent => 'Sent';

  @override
  String inboxReplySubject(String subject) {
    return 'Reply: $subject';
  }

  @override
  String inboxDraftPendingNote(String date) {
    return '$date · unsent drafts are not counted for future generation or learning';
  }

  @override
  String inboxDraftCountedNote(String date) {
    return '$date · counted as a reference for future generation and learning';
  }

  @override
  String get inboxMarkSent => 'Mark sent';

  @override
  String get inboxSentFallback => 'Sent';

  @override
  String get inboxSendFailed => 'Send failed';

  @override
  String get inboxMarkedSentFallback => 'Marked as sent';

  @override
  String get inboxEmailDetails => 'Email details';

  @override
  String inboxSentVia(String account) {
    return 'sent via $account';
  }

  @override
  String inboxReceivedVia(String account) {
    return 'received at $account';
  }

  @override
  String get inboxAuthInfoMissing =>
      'No sender authentication info found (the email may not include it, or the network is unavailable)';

  @override
  String get inboxAuthInfoLoading => 'Fetching sender authentication info…';

  @override
  String get learnReset => 'Reset learning history';

  @override
  String get learnResetTitle => 'Reset learning history';

  @override
  String get learnResetContent =>
      'This clears the \"consumed emails\" record; generated rules are kept. The next incremental learning run will re-read all history. Continue?';

  @override
  String get learnResetConfirm => 'Reset';

  @override
  String get learnRunning => 'Learning…';

  @override
  String get learnStart => 'Start incremental learning';

  @override
  String learnIntro(String folders, num months) {
    return 'Distills reply rules from each account\'s \"$folders\" and the last $months months of inbox history (folder names vary by provider; set per account under \"Spaces\" → email account). While learning, customer mails and your replies are paired by thread to learn \"what was asked → how it was answered\" (accounts are learned one by one). Learned emails are never reused; mails are processed oldest-first with newer mails winning conflicts, so old mails never overwrite rules distilled from newer ones.';
  }

  @override
  String get learnProcessing => 'Processing…';

  @override
  String get learnFailedFoldersTitle => 'Some learn folders failed to fetch';

  @override
  String get learnFailedFoldersHint =>
      'On \"Spaces\" → email account → edit the account → history learn folders, use a folder name that actually exists on the server, or pick directly via \"Load folder list from server\"; common sent-folder names (Sent / Sent Messages / Sent Items / 已发送) match automatically, and when none match, learning falls back to the server\'s \\Sent flag.';

  @override
  String get learnStatusSection => 'Learning status';

  @override
  String learnConsumedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count emails consumed',
      one: '1 email consumed',
    );
    return '$_temp0';
  }

  @override
  String learnLastRun(String time) {
    return 'Last learning run: $time';
  }

  @override
  String get learnNever => 'Never learned';

  @override
  String get learnNoRecords =>
      'No learning history yet. Click \"Start incremental learning\" to distill rules from history.';

  @override
  String get learnRecentSection => 'Recently consumed emails (up to 200 shown)';

  @override
  String get learnNoSubject => '(no subject)';

  @override
  String learnGeneratedRules(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rules produced',
      one: '1 rule produced',
    );
    return '$_temp0';
  }

  @override
  String get draftStatusEditing => 'Editing';

  @override
  String get draftStatusSentUnmodified => 'Sent (unmodified)';

  @override
  String get draftStatusSentEdited => 'Sent (edited)';

  @override
  String get draftStatusSentManually => 'Sent (marked manually)';

  @override
  String get draftStatusDiscarded => 'Discarded';

  @override
  String get draftConfirmDeleteTitle => 'Delete draft';

  @override
  String get draftConfirmDeleteContent =>
      'This cannot be undone (nothing will be sent).';

  @override
  String get draftMarkSentTitle => 'Mark as sent';

  @override
  String get draftMarkSentContent =>
      'Use this when you sent the draft outside this app (e.g. in the webmail).\nOnce marked, the content is counted as a reference for future generation and learning.';

  @override
  String get draftMarkSentFeedback => 'Compare my edits and improve rules';

  @override
  String get draftMarkSentFeedbackHint =>
      'Uncheck if you changed the content again elsewhere';

  @override
  String get draftMarkSentConfirm => 'Mark';

  @override
  String get draftConfirmSendTitle => 'Confirm send';

  @override
  String draftSendCcNote(String ccs) {
    return 'CC: $ccs';
  }

  @override
  String draftConfirmSendContent(String to, String ccNote, String subject) {
    return 'Will be sent to $to$ccNote\nSubject: Re: $subject';
  }

  @override
  String get draftSendKeepEditing => 'Keep editing';

  @override
  String get draftsSubtitle =>
      'If a draft was modified before sending, the change is analyzed automatically to improve the reply rules; unsent drafts are not counted for future generation or learning';

  @override
  String get draftsEmpty =>
      'No drafts yet — generate your first one from the inbox';

  @override
  String draftsTileSubtitle(String to, String date, num rules) {
    String _temp0 = intl.Intl.pluralLogic(
      rules,
      locale: localeName,
      other: '$rules rules',
      one: '1 rule',
    );
    return '$to · $date · based on $_temp0';
  }

  @override
  String get draftNotFound => 'Draft not found';

  @override
  String get draftUnsentNote =>
      'Unsent drafts are not counted for future generation or learning; only after sending or marking as sent does the content become a reference.';

  @override
  String draftToLine(String to) {
    return 'To: $to';
  }

  @override
  String get draftSenderMissing =>
      'Send account: (no available send account in this space)';

  @override
  String draftSenderLine(String account) {
    return 'Send account: $account';
  }

  @override
  String get draftSenderFallbackNote =>
      ' (receive account can\'t send; using the default send account)';

  @override
  String draftGeneratedByLine(String model) {
    return 'Generated by: $model';
  }

  @override
  String draftStatusLine(String status) {
    return 'Status: $status';
  }

  @override
  String get draftEditHint =>
      'The draft is generated from reply rules; edit directly or refine it via the AI chat on the right. On send, your edits are compared and the rules improve automatically.';

  @override
  String get draftCcLabel =>
      'CC (original recipients auto-detected from forwarding; add or remove)';

  @override
  String get draftAddCcHint => 'Add a CC address';

  @override
  String draftUsedRulesTitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count',
      one: '1',
    );
    return 'Reply rules used ($_temp0)';
  }

  @override
  String get draftUsedRulesSubtitle =>
      'Drafts are generated from rules only; anything the rules don\'t cover is never made up';

  @override
  String draftRuleSourceLine(String category, String source) {
    return '$category · Source: $source';
  }

  @override
  String get draftRuleUpdatesTitle => 'Rule improvements after sending';

  @override
  String get chatTitle => 'AI refine';

  @override
  String get chatSubtitle =>
      'Tell the AI what to change; the updated body syncs to the editor on the left';

  @override
  String get chatEmptyActive =>
      'Chat with the AI to refine the draft, e.g.:\n\"Make the tone more sincere\" · \"Start by thanking them for the feedback\" · \"Drop the specific day-count promise\"';

  @override
  String get chatEmptyLocked => 'This draft is finalized; chat is disabled';

  @override
  String get chatInputHint => 'Tell the AI how to modify the draft…';

  @override
  String get chatSendButton => 'Revise';

  @override
  String get chatCollapseBody => 'Collapse body';

  @override
  String get chatExpandBody => 'Body updated — click to view';

  @override
  String get chatBusy => 'AI is revising the draft…';

  @override
  String chatRefineFailed(String error) {
    return 'Revision failed: $error';
  }

  @override
  String get kbImportButton => 'Import .md / .txt documents';

  @override
  String get kbGenerateButton => 'Generate rules for pending docs';

  @override
  String get kbSubtitle =>
      'After-sales policies / FAQ / product info → distilled into reply rules; regenerate after a document changes (old rules are replaced)';

  @override
  String get kbEmpty =>
      'No documents yet. Import .md / .txt files to generate reply rules';

  @override
  String kbDocSubtitle(String time, String size, String hash, String status) {
    return 'Imported $time · $size KB · content $hash · $status';
  }

  @override
  String get kbStatusPending => 'rules not generated yet';

  @override
  String get kbStatusStale => 'content changed, regeneration needed';

  @override
  String get kbStatusFresh => 'rules up to date';

  @override
  String get kbDeleteDoc => 'Delete document';

  @override
  String get commonEmpty => '';

  @override
  String commonRawError(String text) {
    return '$text';
  }

  @override
  String get commonErrorSeparator => '; ';

  @override
  String get llmReasonNoneConfigured =>
      'Configure an LLM in Settings first and assign it to the space';

  @override
  String get llmReasonNotAssigned =>
      'An LLM is configured in Settings; assign it to the current space on the Spaces page';

  @override
  String get llmReasonDeleted =>
      'The LLM assigned to this space has been deleted; reassign on the Spaces page';

  @override
  String get llmReasonIncomplete =>
      'The LLM assigned to this space is incomplete (missing API URL or model name); finish it in Settings';

  @override
  String get llmErrNotConfigured => 'Fill in the Base URL and model name first';

  @override
  String get llmErrTruncated =>
      'Output truncated by max_tokens (reasoning models\' thinking counts toward the budget); increase max tokens';

  @override
  String get llmErrEmptyPlain => 'The model returned no content';

  @override
  String llmErrEmptyReason(String reason) {
    return 'The model returned no content (finish_reason=$reason)';
  }

  @override
  String llmErrNotJson(String error) {
    return 'The model failed to output valid JSON after retries: $error';
  }

  @override
  String llmErrHttp(String status, String detail) {
    return 'HTTP $status: $detail';
  }

  @override
  String llmErrTimeout(num seconds) {
    return 'Request timed out (${seconds}s); increase the timeout in Settings';
  }

  @override
  String get llmErrNetwork => 'Network error';

  @override
  String mailOpTimeout(num seconds) {
    return 'Mail operation did not complete within ${seconds}s and was aborted (network unreachable or server unresponsive; try refreshing later)';
  }

  @override
  String get mailOauthNotAuthorized =>
      'This account signs in with OAuth2 (Outlook); complete Microsoft authorization in the account settings first';

  @override
  String get mailReceiveIncomplete =>
      'Receive configuration incomplete (address / IMAP server / password)';

  @override
  String get mailSendIncomplete =>
      'Send configuration incomplete (address / SMTP server / password)';

  @override
  String mailConnectTimeout(String host, num port) {
    return 'Connecting to $host:$port timed out (auto-retried once): the server went silent after TLS, usually packet loss on a proxy/VPN node — switch nodes or disable the proxy temporarily and retry';
  }

  @override
  String get mailTokenRefreshStall =>
      'Microsoft token refresh stalled (two 22-second rounds with no progress): direct connections to login.microsoftonline.com are being blocked by the network — switch nodes, use global mode, or disable the proxy temporarily and retry';

  @override
  String get mailFrTokenTimeout =>
      'Cannot refresh the Microsoft token: direct connections to login.microsoftonline.com are blocked (usually a proxy/VPN issue). Switch nodes or use global mode in your proxy app and retry; it also recovers automatically once the network is back.';

  @override
  String mailFrInvalidGrant(String raw) {
    return 'Microsoft authorization has expired ($raw); sign in again in the account settings on the Spaces page';
  }

  @override
  String mailFrAuthRejected(String raw) {
    return 'Login rejected by the server ($raw). Personal Outlook accounts need IMAP enabled in the web settings: Settings → Mail → Sync email → POP and IMAP; for organizational accounts ask the admin to allow IMAP';
  }

  @override
  String oauthBrowserFailed(String url) {
    return 'Could not open the system browser; open this link manually to authorize:\n$url';
  }

  @override
  String get oauthWaitTimeout =>
      'Timed out waiting for browser authorization (5 minutes); try again';

  @override
  String get oauthStateMismatch =>
      'Authorization callback validation failed (state mismatch); try again';

  @override
  String oauthAccessDenied(String detail) {
    return 'You canceled the authorization$detail';
  }

  @override
  String oauthRejected(String error, String detail) {
    return 'Authorization denied: $error$detail';
  }

  @override
  String get oauthNoCode =>
      'Authorization callback is missing the code; try again';

  @override
  String get oauthTokenTimeout =>
      'Timed out connecting to the Microsoft token service (no response in 20s): direct connections may be blocked by a proxy/VPN — check your proxy app (try switching nodes or global mode) and retry';

  @override
  String oauthConnectFailed(String error) {
    return 'Failed to connect to the Microsoft token service: $error';
  }

  @override
  String oauthHttpError(String status, String detail) {
    return 'Microsoft token endpoint returned HTTP $status: $detail';
  }

  @override
  String get oauthNoBody => 'no response body';

  @override
  String oauthTokenError(String error, String detail) {
    return 'Microsoft returned an authorization error: $error$detail';
  }

  @override
  String oauthParseFailed(String error) {
    return 'Failed to parse the token returned by Microsoft: $error';
  }

  @override
  String get learnFetchingHistory => 'Fetching history emails…';

  @override
  String learnFetchingFolder(String email, String folder, num months) {
    return 'Fetching $folder of $email (last $months months)…';
  }

  @override
  String learnFetchingDetected(String email, String folder) {
    return 'Fetching $folder of $email (auto-detected)…';
  }

  @override
  String learnFetchingInbox(String email) {
    return 'Fetching INBOX of $email (pairing customer mails)…';
  }

  @override
  String learnFailedNote(num count) {
    return '; $count accounts/folders failed to fetch (see warnings below)';
  }

  @override
  String learnRecoveredNote(num count) {
    return '; learn folders of $count account(s) auto-detected and config updated';
  }

  @override
  String learnNoNewEmails(String failed, String recovered) {
    return 'No new emails to learn (all consumed or outside the time range)$failed$recovered';
  }

  @override
  String learnDone(
    num added,
    num updated,
    num consumed,
    String failed,
    String recovered,
  ) {
    return 'Learning finished: $added rules added, $updated updated, $consumed emails consumed$failed$recovered';
  }

  @override
  String get learnErrNeedSpace =>
      'Create a space and configure email accounts on the Spaces page first';

  @override
  String get learnErrIncomplete =>
      'No account in this space is fully configured (missing server or password)';

  @override
  String learnErrFailed(String error) {
    return 'Learning failed: $error';
  }

  @override
  String get learnErrNoRulesArray =>
      'The model output object contains no rules array';

  @override
  String learnErrNotRulesArray(String type) {
    return 'The model output is not a rules array ($type)';
  }

  @override
  String learnStageAnalyzing(num index, num total) {
    return 'Analyzing thread batch $index/$total';
  }

  @override
  String learnStageMerging(num index, num total) {
    return 'Merging rules (batch $index/$total)';
  }

  @override
  String kbStageExtracting(String doc, num index, num total) {
    return 'Extracting rules from \"$doc\" (chunk $index/$total)';
  }

  @override
  String get kbImporting => 'Importing documents…';

  @override
  String kbImported(num count) {
    return 'Import finished: $count documents';
  }

  @override
  String kbImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get kbPreparing => 'Preparing rule generation…';

  @override
  String get kbNoDocs => 'No documents need rule generation';

  @override
  String kbGenerated(num docs, num rules) {
    return 'Generated $rules rules for $docs documents';
  }

  @override
  String kbGenerateFailed(String error) {
    return 'Generation failed: $error';
  }

  @override
  String get inboxPreparing => 'Preparing to sync…';

  @override
  String inboxSyncing(String email, String role) {
    return 'Syncing $email $role…';
  }

  @override
  String get inboxErrNoSpace =>
      'Create a space and configure email accounts on the Spaces page first';

  @override
  String get inboxErrNoReceiver =>
      'No account in the current space has receiving enabled';

  @override
  String inboxErrIncomplete(String email, String reason) {
    return '$email: incomplete configuration ($reason)';
  }

  @override
  String get inboxReasonNoImap => 'missing IMAP server configuration';

  @override
  String get inboxReasonOauth =>
      'Microsoft authorization not completed (sign in again in the account settings)';

  @override
  String get inboxReasonNoPassword =>
      'missing password (keychain returned no app password for this account)';

  @override
  String inboxErrSentMissing(String email) {
    return '$email: sent folder not found, skipped';
  }

  @override
  String inboxErrSyncFailedCached(String email, String role, String error) {
    return '$email $role: sync failed (showing cache): $error';
  }

  @override
  String inboxErrSyncFailed(String email, String role, String error) {
    return '$email $role: $error';
  }

  @override
  String inboxErrInterrupted(String error) {
    return 'Refresh interrupted: $error';
  }

  @override
  String get draftsErrNeedSpace => 'Create a space first';

  @override
  String get draftsMsgExisting =>
      'An in-progress draft already exists for this email; opened it for you';

  @override
  String get draftsErrRulesEmpty =>
      'The rule library is empty: drafts are generated from reply rules only — generate rules first in Learning / Knowledge / Rules';

  @override
  String get draftsErrRulesDisabled =>
      'All rules are currently disabled; enable rules in the rule library first';

  @override
  String get draftsErrRulesEmptyGen =>
      'The rule library is empty; generate reply rules from history emails, the knowledge base, or a custom prompt first';

  @override
  String draftsErrGenerateFailed(String error) {
    return 'Draft generation failed: $error';
  }

  @override
  String get draftsErrNoSender =>
      'No account in this space can send (enable sending for an account in Spaces)';

  @override
  String draftsErrSendFailed(String error) {
    return 'Send failed: $error';
  }

  @override
  String get draftsErrNoBody => 'The model did not return a revised body';

  @override
  String draftsFbSent(String feedback) {
    return 'Sent. $feedback';
  }

  @override
  String get draftsFbModifiedNoAdjust =>
      'Edits detected; rules optimized: no adjustments needed this time';

  @override
  String draftsFbModifiedUpdates(String updates) {
    return 'Edits detected; rules optimized: $updates';
  }

  @override
  String get draftsFbUnmodified =>
      'The draft was sent unmodified; related rules got positive feedback';

  @override
  String draftsFbFailed(String error) {
    return ', but rule feedback learning failed: $error';
  }

  @override
  String get draftsFbSkipped =>
      '(no LLM configured; rule feedback learning skipped)';

  @override
  String get draftsMarkedPlain =>
      'Marked as sent manually. The content is counted as a reference for future generation and learning.';

  @override
  String draftsMarkedWithFeedback(String feedback) {
    return 'Marked as sent manually. $feedback';
  }
}
