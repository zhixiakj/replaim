import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Window / task-switcher app title
  ///
  /// In en, this message translates to:
  /// **'Replaim Email Copilot'**
  String get appTitle;

  /// No description provided for @navInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get navInbox;

  /// No description provided for @navDrafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get navDrafts;

  /// No description provided for @navRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get navRules;

  /// No description provided for @navKb.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get navKb;

  /// No description provided for @navLearn.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get navLearn;

  /// No description provided for @navSpaces.
  ///
  /// In en, this message translates to:
  /// **'Spaces'**
  String get navSpaces;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @switchSpaceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch space'**
  String get switchSpaceTooltip;

  /// No description provided for @accountsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 account} other{{count} accounts}}'**
  String accountsCount(num count);

  /// No description provided for @noSpaceSelected.
  ///
  /// In en, this message translates to:
  /// **'No space selected'**
  String get noSpaceSelected;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @spaceReceiveSend.
  ///
  /// In en, this message translates to:
  /// **'{receive} in / {send} out'**
  String spaceReceiveSend(num receive, num send);

  /// No description provided for @newSpaceTooltip.
  ///
  /// In en, this message translates to:
  /// **'New space'**
  String get newSpaceTooltip;

  /// No description provided for @newSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'New space'**
  String get newSpaceTitle;

  /// No description provided for @spaceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Space name (e.g. store / brand)'**
  String get spaceNameLabel;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonJoinSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get commonJoinSeparator;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commonSend;

  /// No description provided for @commonSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get commonSending;

  /// No description provided for @commonEmptyValue.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get commonEmptyValue;

  /// No description provided for @commonTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get commonTesting;

  /// No description provided for @commonTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get commonTestConnection;

  /// No description provided for @settingsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 rule enabled in the current space} other{{count} rules enabled in the current space}} · Data folder: {path}'**
  String settingsSummary(num count, String path);

  /// No description provided for @settingsGeneralTitle.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneralTitle;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLlmSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'LLM (global, OpenAI-compatible APIs)'**
  String get settingsLlmSectionTitle;

  /// No description provided for @settingsLlmSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No space has a model assigned yet} =1{1 space has a model assigned} other{{count} spaces have a model assigned}}. Configure multiple model endpoints here, then assign them to spaces on the Spaces page.'**
  String settingsLlmSectionSubtitle(num count);

  /// No description provided for @settingsLlmEmpty.
  ///
  /// In en, this message translates to:
  /// **'No model configured yet. Click the button below to add one.'**
  String get settingsLlmEmpty;

  /// No description provided for @llmProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} ({model})'**
  String llmProfileTitle(String name, String model);

  /// No description provided for @settingsAddLlm.
  ///
  /// In en, this message translates to:
  /// **'Add LLM'**
  String get settingsAddLlm;

  /// No description provided for @settingsAddLlmTitle.
  ///
  /// In en, this message translates to:
  /// **'Add LLM'**
  String get settingsAddLlmTitle;

  /// No description provided for @settingsEditLlmTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit LLM'**
  String get settingsEditLlmTitle;

  /// No description provided for @settingsLlmFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. DeepSeek, company GPT)'**
  String get settingsLlmFieldName;

  /// No description provided for @settingsLlmFieldBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'API base URL (usually ends with /v1), e.g. https://api.deepseek.com/v1'**
  String get settingsLlmFieldBaseUrl;

  /// No description provided for @settingsLlmFieldModel.
  ///
  /// In en, this message translates to:
  /// **'Model name, e.g. deepseek-chat'**
  String get settingsLlmFieldModel;

  /// No description provided for @settingsLlmFieldApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key (leave blank when editing to keep)'**
  String get settingsLlmFieldApiKey;

  /// No description provided for @settingsLlmFieldTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get settingsLlmFieldTemperature;

  /// No description provided for @settingsLlmFieldMaxTokens.
  ///
  /// In en, this message translates to:
  /// **'Max tokens'**
  String get settingsLlmFieldMaxTokens;

  /// No description provided for @settingsLlmFieldTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout (s)'**
  String get settingsLlmFieldTimeout;

  /// No description provided for @settingsLlmTestOk.
  ///
  /// In en, this message translates to:
  /// **'Connection OK ({endpoint})'**
  String settingsLlmTestOk(String endpoint);

  /// No description provided for @settingsLlmUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed model'**
  String get settingsLlmUnnamed;

  /// No description provided for @settingsLlmSaved.
  ///
  /// In en, this message translates to:
  /// **'LLM configuration saved'**
  String get settingsLlmSaved;

  /// No description provided for @settingsLlmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete model \"{name}\"'**
  String settingsLlmDeleteTitle(String name);

  /// No description provided for @settingsLlmDeleteUnused.
  ///
  /// In en, this message translates to:
  /// **'This model is not used by any space.'**
  String get settingsLlmDeleteUnused;

  /// No description provided for @settingsLlmDeleteInUse.
  ///
  /// In en, this message translates to:
  /// **'These spaces are using this model and will become unassigned after deletion:\n{spaces}'**
  String settingsLlmDeleteInUse(String spaces);

  /// No description provided for @settingsPromptSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom prompt rules'**
  String get settingsPromptSectionTitle;

  /// No description provided for @settingsPromptSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn your reply requirements into rules (saved to the current space, used for drafting together with history and knowledge-base rules)'**
  String get settingsPromptSectionSubtitle;

  /// No description provided for @settingsPromptHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Apologize first, then offer a solution for all refund emails; sign off with \"Best regards, Amy\"'**
  String get settingsPromptHint;

  /// No description provided for @settingsPromptSplitButton.
  ///
  /// In en, this message translates to:
  /// **'Split into rules with LLM (recommended)'**
  String get settingsPromptSplitButton;

  /// No description provided for @settingsPromptDirectButton.
  ///
  /// In en, this message translates to:
  /// **'Add as a single rule'**
  String get settingsPromptDirectButton;

  /// No description provided for @settingsPromptEmpty.
  ///
  /// In en, this message translates to:
  /// **'No custom prompt rules yet'**
  String get settingsPromptEmpty;

  /// No description provided for @settingsPromptSplitting.
  ///
  /// In en, this message translates to:
  /// **'Splitting into rules…'**
  String get settingsPromptSplitting;

  /// No description provided for @settingsPromptConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Review generated rules'**
  String get settingsPromptConfirmTitle;

  /// No description provided for @settingsPromptAddSelected.
  ///
  /// In en, this message translates to:
  /// **'Add selected'**
  String get settingsPromptAddSelected;

  /// No description provided for @settingsPromptAddedRules.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 rule} other{Added {count} rules}}'**
  String settingsPromptAddedRules(num count);

  /// No description provided for @settingsPromptSplitFailed.
  ///
  /// In en, this message translates to:
  /// **'Split failed: {error}'**
  String settingsPromptSplitFailed(String error);

  /// No description provided for @settingsPromptAddedOne.
  ///
  /// In en, this message translates to:
  /// **'Rule added'**
  String get settingsPromptAddedOne;

  /// No description provided for @ruleSourceEmailHistory.
  ///
  /// In en, this message translates to:
  /// **'History emails'**
  String get ruleSourceEmailHistory;

  /// No description provided for @ruleSourceKnowledgeBase.
  ///
  /// In en, this message translates to:
  /// **'Knowledge base'**
  String get ruleSourceKnowledgeBase;

  /// No description provided for @ruleSourceUserPrompt.
  ///
  /// In en, this message translates to:
  /// **'Custom prompt'**
  String get ruleSourceUserPrompt;

  /// No description provided for @ruleSourceDraftFeedback.
  ///
  /// In en, this message translates to:
  /// **'Draft edit feedback'**
  String get ruleSourceDraftFeedback;

  /// No description provided for @ruleSourceManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get ruleSourceManual;

  /// No description provided for @ruleCategoryTone.
  ///
  /// In en, this message translates to:
  /// **'Tone & style'**
  String get ruleCategoryTone;

  /// No description provided for @ruleCategoryPolicy.
  ///
  /// In en, this message translates to:
  /// **'After-sales policy'**
  String get ruleCategoryPolicy;

  /// No description provided for @ruleCategoryFormat.
  ///
  /// In en, this message translates to:
  /// **'Format & structure'**
  String get ruleCategoryFormat;

  /// No description provided for @ruleCategoryProduct.
  ///
  /// In en, this message translates to:
  /// **'Product info'**
  String get ruleCategoryProduct;

  /// No description provided for @ruleCategoryCompliance.
  ///
  /// In en, this message translates to:
  /// **'Platform compliance'**
  String get ruleCategoryCompliance;

  /// No description provided for @ruleCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get ruleCategoryOther;

  /// No description provided for @spacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Spaces'**
  String get spacesTitle;

  /// No description provided for @spacesEmptyIntro.
  ///
  /// In en, this message translates to:
  /// **'A space is an independent business context (e.g. a store / brand):\n· One shared set of reply rules and knowledge base per space\n· Multiple email accounts, each with its own receive (IMAP) and send (SMTP) toggles\n· Forwarded mail (e.g. customer writes support@, forwarded to a configured account) is detected: the original recipient is CC\'d on replies'**
  String get spacesEmptyIntro;

  /// No description provided for @spacesCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create your first space'**
  String get spacesCreateFirst;

  /// No description provided for @spacesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 space} other{{count} spaces}}'**
  String spacesCount(num count);

  /// No description provided for @spacesCurrentBadge.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get spacesCurrentBadge;

  /// No description provided for @spacesAccountSummary.
  ///
  /// In en, this message translates to:
  /// **'{accounts, plural, =1{1 account} other{{accounts} accounts}} · {receive} in / {send} out'**
  String spacesAccountSummary(num accounts, num receive, num send);

  /// No description provided for @spacesDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete space'**
  String get spacesDeleteTooltip;

  /// No description provided for @spacesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete space \"{name}\"'**
  String spacesDeleteTitle(String name);

  /// No description provided for @spacesDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'This will delete the space\'s rules, knowledge base, learning state and draft records, plus the stored passwords of all its accounts.\nThis cannot be undone.'**
  String get spacesDeleteContent;

  /// No description provided for @spacesDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Space: {name}'**
  String spacesDetailTitle(String name);

  /// No description provided for @spacesSetCurrent.
  ///
  /// In en, this message translates to:
  /// **'Set as current'**
  String get spacesSetCurrent;

  /// No description provided for @spacesBasicInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get spacesBasicInfoSection;

  /// No description provided for @spacesFieldName.
  ///
  /// In en, this message translates to:
  /// **'Space name'**
  String get spacesFieldName;

  /// No description provided for @spacesAssignLlmLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned LLM (manage models in Settings)'**
  String get spacesAssignLlmLabel;

  /// No description provided for @spacesLlmUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get spacesLlmUnassigned;

  /// No description provided for @spacesDefaultSendLabel.
  ///
  /// In en, this message translates to:
  /// **'Default send account (fallback when a receive account can\'t send)'**
  String get spacesDefaultSendLabel;

  /// No description provided for @spacesDefaultSendAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto (any account with sending enabled)'**
  String get spacesDefaultSendAuto;

  /// No description provided for @spacesOutputLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Draft output language (default English)'**
  String get spacesOutputLanguageLabel;

  /// No description provided for @spacesLearnPrefsSection.
  ///
  /// In en, this message translates to:
  /// **'Learning preferences (per space)'**
  String get spacesLearnPrefsSection;

  /// No description provided for @spacesLearnMonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Learning window (recent N months)'**
  String get spacesLearnMonthsLabel;

  /// No description provided for @spacesLearnFoldersHint.
  ///
  /// In en, this message translates to:
  /// **'History learn folders are set per email account (folder names vary by provider: Gmail uses [Gmail]/Sent Mail ([Gmail]/已发送邮件 on Chinese-language accounts), QQ/163 use Sent Messages, Outlook uses Sent). Edit each account under \"Email accounts\" below; common names match automatically, and when none match, learning falls back to the server\'s Sent flag.'**
  String get spacesLearnFoldersHint;

  /// No description provided for @spacesAccountsSection.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Email account (1)} other{Email accounts ({count})}}'**
  String spacesAccountsSection(num count);

  /// No description provided for @spacesAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Each account can separately enable receive (IMAP) and send (SMTP); replies are sent from the receiving account by default'**
  String get spacesAccountsSubtitle;

  /// No description provided for @spacesNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet. Click the button below to add one.'**
  String get spacesNoAccounts;

  /// No description provided for @spacesAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add email account'**
  String get spacesAddAccount;

  /// No description provided for @spacesAutoSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes save automatically'**
  String get spacesAutoSaved;

  /// No description provided for @spacesDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account {email}'**
  String spacesDeleteAccountTitle(String email);

  /// No description provided for @spacesDeleteAccountContent.
  ///
  /// In en, this message translates to:
  /// **'This removes the account\'s configuration and stored password. Space data is unaffected.'**
  String get spacesDeleteAccountContent;

  /// No description provided for @accountDisabledBadge.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get accountDisabledBadge;

  /// No description provided for @accountReceiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get accountReceiveBadge;

  /// No description provided for @accountNoReceiveBadge.
  ///
  /// In en, this message translates to:
  /// **'No receive'**
  String get accountNoReceiveBadge;

  /// No description provided for @accountSendBadge.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get accountSendBadge;

  /// No description provided for @accountNoSendBadge.
  ///
  /// In en, this message translates to:
  /// **'No send'**
  String get accountNoSendBadge;

  /// No description provided for @accountDefaultSendBadge.
  ///
  /// In en, this message translates to:
  /// **'Default send'**
  String get accountDefaultSendBadge;

  /// No description provided for @accountLearnFoldersBadge.
  ///
  /// In en, this message translates to:
  /// **'Learn: {folders}'**
  String accountLearnFoldersBadge(String folders);

  /// No description provided for @spacesAddAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Add email account (space: {space})'**
  String spacesAddAccountTitle(String space);

  /// No description provided for @spacesEditAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit account {email}'**
  String spacesEditAccountTitle(String email);

  /// No description provided for @spacesFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address (also used as login username)'**
  String get spacesFieldEmail;

  /// No description provided for @spacesFieldEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'Common providers (Gmail / QQ / 163 / Outlook…) auto-fill the server settings and learn folder below once the address is entered'**
  String get spacesFieldEmailHelper;

  /// No description provided for @spacesFieldDisplayName.
  ///
  /// In en, this message translates to:
  /// **'From display name (optional)'**
  String get spacesFieldDisplayName;

  /// No description provided for @spacesEnableAccount.
  ///
  /// In en, this message translates to:
  /// **'Enable this account'**
  String get spacesEnableAccount;

  /// No description provided for @spacesEnableAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When disabled it stays out of receiving, sending and learning; the configuration is kept and can be re-enabled anytime'**
  String get spacesEnableAccountSubtitle;

  /// No description provided for @spacesOauthToggle.
  ///
  /// In en, this message translates to:
  /// **'OAuth2 sign-in (required for Outlook: Microsoft has disabled password login)'**
  String get spacesOauthToggle;

  /// No description provided for @spacesFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password / app password'**
  String get spacesFieldPassword;

  /// No description provided for @spacesTabReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive (IMAP)'**
  String get spacesTabReceive;

  /// No description provided for @spacesTabSend.
  ///
  /// In en, this message translates to:
  /// **'Send (SMTP)'**
  String get spacesTabSend;

  /// No description provided for @spacesSaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Save account'**
  String get spacesSaveAccount;

  /// No description provided for @spacesReceiveToggle.
  ///
  /// In en, this message translates to:
  /// **'Receive (IMAP: fetches the inbox, used for learning)'**
  String get spacesReceiveToggle;

  /// No description provided for @spacesFieldImapHost.
  ///
  /// In en, this message translates to:
  /// **'IMAP server, e.g. imap.qq.com'**
  String get spacesFieldImapHost;

  /// No description provided for @spacesFieldPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get spacesFieldPort;

  /// No description provided for @spacesImapSslToggle.
  ///
  /// In en, this message translates to:
  /// **'Use SSL for IMAP (usually on for port 993)'**
  String get spacesImapSslToggle;

  /// No description provided for @spacesFieldLearnFolders.
  ///
  /// In en, this message translates to:
  /// **'History learn folders (comma-separated, default Sent)'**
  String get spacesFieldLearnFolders;

  /// No description provided for @spacesLearnFoldersHelper.
  ///
  /// In en, this message translates to:
  /// **'Folder names vary by provider: Gmail uses [Gmail]/Sent Mail ([Gmail]/已发送邮件 on Chinese-language accounts), QQ/163 use Sent Messages, Outlook uses Sent. Common names match automatically; if unsure, use the button below to pick from the server'**
  String get spacesLearnFoldersHelper;

  /// No description provided for @spacesLoadFoldersButton.
  ///
  /// In en, this message translates to:
  /// **'Load folder list from server'**
  String get spacesLoadFoldersButton;

  /// No description provided for @spacesSendToggle.
  ///
  /// In en, this message translates to:
  /// **'Send (SMTP: can be used to send replies)'**
  String get spacesSendToggle;

  /// No description provided for @spacesFieldSmtpHost.
  ///
  /// In en, this message translates to:
  /// **'SMTP server, e.g. smtp.qq.com (leave empty for receive-only)'**
  String get spacesFieldSmtpHost;

  /// No description provided for @spacesSmtpSecureToggle.
  ///
  /// In en, this message translates to:
  /// **'SMTP encryption (465=SSL / 587=STARTTLS)'**
  String get spacesSmtpSecureToggle;

  /// No description provided for @spacesForcedOffNoOauth.
  ///
  /// In en, this message translates to:
  /// **'Microsoft authorization not completed'**
  String get spacesForcedOffNoOauth;

  /// No description provided for @spacesForcedOffNoPassword.
  ///
  /// In en, this message translates to:
  /// **'Password / app password not filled in'**
  String get spacesForcedOffNoPassword;

  /// No description provided for @spacesForcedOffTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Last \"Test connection\" failed'**
  String get spacesForcedOffTestFailed;

  /// No description provided for @spacesErrEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the email address'**
  String get spacesErrEmailRequired;

  /// No description provided for @spacesSavedDisabled.
  ///
  /// In en, this message translates to:
  /// **'{email}: {reason}. Saved as disabled — complete and verify, then enable it in the account list.'**
  String spacesSavedDisabled(String email, String reason);

  /// No description provided for @spacesOauthNeedClientId.
  ///
  /// In en, this message translates to:
  /// **'Fill in the Azure app client ID first (the Application (client) ID on the Azure app\'s Overview page)'**
  String get spacesOauthNeedClientId;

  /// No description provided for @spacesOauthSuccess.
  ///
  /// In en, this message translates to:
  /// **'✓ Microsoft authorization succeeded (token valid until {expiry}, renews automatically)'**
  String spacesOauthSuccess(String expiry);

  /// No description provided for @spacesOauthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authorization failed: {error}'**
  String spacesOauthFailed(String error);

  /// No description provided for @spacesFoldersMore.
  ///
  /// In en, this message translates to:
  /// **' … {count} in total'**
  String spacesFoldersMore(num count);

  /// No description provided for @spacesFoldersMissing.
  ///
  /// In en, this message translates to:
  /// **'{email}: learn folder(s) \"{folders}\" not found on the server (available: {existing}). Edit the account and use \"Load folder list from server\" to pick.'**
  String spacesFoldersMissing(String email, String folders, String existing);

  /// No description provided for @spacesTestOkFoldersMatched.
  ///
  /// In en, this message translates to:
  /// **'Connection OK; learn folder(s) \"{folders}\" matched ✓'**
  String spacesTestOkFoldersMatched(String folders);

  /// No description provided for @spacesTestFoldersMissing.
  ///
  /// In en, this message translates to:
  /// **'Connection OK; ⚠ learn folder(s) \"{folders}\" not found on the server (use the button below to pick from the server)'**
  String spacesTestFoldersMissing(String folders);

  /// No description provided for @spacesTestOkImap.
  ///
  /// In en, this message translates to:
  /// **'Connection OK (IMAP login verified)'**
  String get spacesTestOkImap;

  /// No description provided for @spacesPickFoldersNeedOauth.
  ///
  /// In en, this message translates to:
  /// **'Fill in the email address and complete Microsoft authorization first'**
  String get spacesPickFoldersNeedOauth;

  /// No description provided for @spacesPickFoldersNeedCreds.
  ///
  /// In en, this message translates to:
  /// **'Fill in the email address, IMAP server and password first'**
  String get spacesPickFoldersNeedCreds;

  /// No description provided for @spacesPickFoldersTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose history learn folders'**
  String get spacesPickFoldersTitle;

  /// No description provided for @spacesServerSentBadge.
  ///
  /// In en, this message translates to:
  /// **'Server Sent'**
  String get spacesServerSentBadge;

  /// No description provided for @spacesLoadFoldersFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load folders: {error}'**
  String spacesLoadFoldersFailed(String error);

  /// No description provided for @spacesPwdHelperNew.
  ///
  /// In en, this message translates to:
  /// **'QQ, 163 and similar providers require an app password generated in the provider\'s console; it is encrypted and stored in the system keychain after saving'**
  String get spacesPwdHelperNew;

  /// No description provided for @spacesPwdHelperSaved.
  ///
  /// In en, this message translates to:
  /// **'App password saved (the dots are just a placeholder); type a new one to replace it'**
  String get spacesPwdHelperSaved;

  /// No description provided for @spacesPwdHelperNone.
  ///
  /// In en, this message translates to:
  /// **'No password saved yet'**
  String get spacesPwdHelperNone;

  /// No description provided for @spacesOauthClientIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Azure app client ID'**
  String get spacesOauthClientIdLabel;

  /// No description provided for @spacesOauthClientIdHelper.
  ///
  /// In en, this message translates to:
  /// **'Register a \"Mobile and desktop application\" in the Azure portal (redirect URI http://localhost, account type including personal Microsoft accounts); multiple Outlook accounts can share one ID'**
  String get spacesOauthClientIdHelper;

  /// No description provided for @spacesOauthWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the browser to finish authorization… (up to 5 minutes)'**
  String get spacesOauthWaiting;

  /// No description provided for @spacesOauthRelogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Microsoft account again'**
  String get spacesOauthRelogin;

  /// No description provided for @spacesOauthLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Microsoft account'**
  String get spacesOauthLogin;

  /// No description provided for @spacesOauthNotYetHint.
  ///
  /// In en, this message translates to:
  /// **'Not authorized yet: you can save first (the account stays disabled) and finish sign-in later to enable it (Outlook also requires enabling IMAP in its web settings)'**
  String get spacesOauthNotYetHint;

  /// No description provided for @rulesEnabledSummary.
  ///
  /// In en, this message translates to:
  /// **'{enabled} of {total} enabled'**
  String rulesEnabledSummary(num enabled, num total);

  /// No description provided for @rulesAddManual.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get rulesAddManual;

  /// No description provided for @rulesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search rule content'**
  String get rulesSearchHint;

  /// No description provided for @rulesFilterAllSources.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get rulesFilterAllSources;

  /// No description provided for @rulesFilterEnabledOnly.
  ///
  /// In en, this message translates to:
  /// **'Enabled only'**
  String get rulesFilterEnabledOnly;

  /// No description provided for @rulesEmpty.
  ///
  /// In en, this message translates to:
  /// **'The rule library is empty: learn from history in \"Learning\",\nimport documents into \"Knowledge\", or add a custom prompt in \"Settings\"'**
  String get rulesEmpty;

  /// No description provided for @rulesAddManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a rule manually'**
  String get rulesAddManualTitle;

  /// No description provided for @rulesFieldContent.
  ///
  /// In en, this message translates to:
  /// **'Rule content'**
  String get rulesFieldContent;

  /// No description provided for @rulesFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get rulesFieldCategory;

  /// No description provided for @rulesSuperseded.
  ///
  /// In en, this message translates to:
  /// **'superseded'**
  String get rulesSuperseded;

  /// No description provided for @rulesStatsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Used {used} times · sent unchanged {kept} times · edited {edited} times'**
  String rulesStatsTooltip(num used, num kept, num edited);

  /// No description provided for @rulesUsedTimes.
  ///
  /// In en, this message translates to:
  /// **'{count}×'**
  String rulesUsedTimes(num count);

  /// No description provided for @rulesDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Rule detail'**
  String get rulesDetailTitle;

  /// No description provided for @rulesKvCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get rulesKvCategory;

  /// No description provided for @rulesKvStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get rulesKvStatus;

  /// No description provided for @rulesStatusEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get rulesStatusEnabled;

  /// No description provided for @rulesStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get rulesStatusDisabled;

  /// No description provided for @rulesStatusSuperseded.
  ///
  /// In en, this message translates to:
  /// **'Superseded'**
  String get rulesStatusSuperseded;

  /// No description provided for @rulesKvVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get rulesKvVersion;

  /// No description provided for @rulesKvStats.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get rulesKvStats;

  /// No description provided for @rulesStatsDetail.
  ///
  /// In en, this message translates to:
  /// **'Used {used} · sent unchanged {kept} · edited {edited}'**
  String rulesStatsDetail(num used, num kept, num edited);

  /// No description provided for @rulesSourceSection.
  ///
  /// In en, this message translates to:
  /// **'Source (where this rule came from)'**
  String get rulesSourceSection;

  /// No description provided for @rulesKvType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get rulesKvType;

  /// No description provided for @rulesKvGeneratedBy.
  ///
  /// In en, this message translates to:
  /// **'Generated by'**
  String get rulesKvGeneratedBy;

  /// No description provided for @rulesKvCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get rulesKvCreatedAt;

  /// No description provided for @rulesHistorySection.
  ///
  /// In en, this message translates to:
  /// **'Version history'**
  String get rulesHistorySection;

  /// No description provided for @rulesChangeReason.
  ///
  /// In en, this message translates to:
  /// **'Change reason: {reason}'**
  String rulesChangeReason(String reason);

  /// No description provided for @rulesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete rule'**
  String get rulesDeleteTitle;

  /// No description provided for @rulesDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone (version history included). Delete?'**
  String get rulesDeleteContent;

  /// No description provided for @rulesKvDateRange.
  ///
  /// In en, this message translates to:
  /// **'Email date range'**
  String get rulesKvDateRange;

  /// No description provided for @rulesKvSourceMails.
  ///
  /// In en, this message translates to:
  /// **'Source emails'**
  String get rulesKvSourceMails;

  /// No description provided for @rulesSourceMailsDetail.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 email (Message-IDs are recorded in the learning state, no re-learning)} other{{count} emails (Message-IDs are recorded in the learning state, no re-learning)}}'**
  String rulesSourceMailsDetail(num count);

  /// No description provided for @rulesKvDoc.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get rulesKvDoc;

  /// No description provided for @rulesKvDocVersion.
  ///
  /// In en, this message translates to:
  /// **'Doc version'**
  String get rulesKvDocVersion;

  /// No description provided for @rulesKvUserPrompt.
  ///
  /// In en, this message translates to:
  /// **'User prompt'**
  String get rulesKvUserPrompt;

  /// No description provided for @rulesKvSourceDraft.
  ///
  /// In en, this message translates to:
  /// **'Source draft'**
  String get rulesKvSourceDraft;

  /// No description provided for @rulesKvChangeSummary.
  ///
  /// In en, this message translates to:
  /// **'Change summary'**
  String get rulesKvChangeSummary;

  /// No description provided for @rulesKvReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get rulesKvReason;

  /// No description provided for @rulesEditContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit rule content'**
  String get rulesEditContentTitle;

  /// No description provided for @inboxRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get inboxRefreshTooltip;

  /// No description provided for @inboxRefreshIncremental.
  ///
  /// In en, this message translates to:
  /// **'Refresh (new mail only)'**
  String get inboxRefreshIncremental;

  /// No description provided for @inboxRefreshFull.
  ///
  /// In en, this message translates to:
  /// **'Full refresh (rebuild cache)'**
  String get inboxRefreshFull;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No emails yet. Configure an account in Spaces and refresh'**
  String get inboxEmpty;

  /// No description provided for @inboxNoSelection.
  ///
  /// In en, this message translates to:
  /// **'Select a conversation to view the thread'**
  String get inboxNoSelection;

  /// No description provided for @inboxInternalConversation.
  ///
  /// In en, this message translates to:
  /// **'(internal to this space)'**
  String get inboxInternalConversation;

  /// No description provided for @inboxNoBody.
  ///
  /// In en, this message translates to:
  /// **'(no body)'**
  String get inboxNoBody;

  /// No description provided for @inboxForwardedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Contains forwarded mail; the original recipient is not an account in this space'**
  String get inboxForwardedTooltip;

  /// No description provided for @inboxRepliedBadge.
  ///
  /// In en, this message translates to:
  /// **'Replied'**
  String get inboxRepliedBadge;

  /// No description provided for @inboxMePrefix.
  ///
  /// In en, this message translates to:
  /// **'Me: {text}'**
  String inboxMePrefix(String text);

  /// No description provided for @inboxMessagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message (sent included)} other{{count} messages (sent included)}}'**
  String inboxMessagesCount(num count);

  /// No description provided for @inboxDraftsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 draft} other{{count} drafts}}'**
  String inboxDraftsCount(num count);

  /// No description provided for @inboxNoIncoming.
  ///
  /// In en, this message translates to:
  /// **'No incoming mail in this conversation; can\'t generate a draft'**
  String get inboxNoIncoming;

  /// No description provided for @inboxTapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Click an incoming bubble to enable draft generation'**
  String get inboxTapToSelect;

  /// No description provided for @inboxSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected: {subject}'**
  String inboxSelected(String subject);

  /// No description provided for @inboxGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get inboxGenerating;

  /// No description provided for @inboxGenerateDraft.
  ///
  /// In en, this message translates to:
  /// **'Generate draft from rules'**
  String get inboxGenerateDraft;

  /// No description provided for @inboxForwardedWarning.
  ///
  /// In en, this message translates to:
  /// **'Forward detected: the customer originally wrote to {recipients} (not an account in this space). Drafts will be sent via {account} with those addresses CC\'d by default; adjust on the draft page.'**
  String inboxForwardedWarning(String recipients, String account);

  /// No description provided for @inboxChipDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get inboxChipDraft;

  /// No description provided for @inboxChipSentManual.
  ///
  /// In en, this message translates to:
  /// **'Sent · marked manually'**
  String get inboxChipSentManual;

  /// No description provided for @inboxChipSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get inboxChipSent;

  /// No description provided for @inboxReplySubject.
  ///
  /// In en, this message translates to:
  /// **'Reply: {subject}'**
  String inboxReplySubject(String subject);

  /// No description provided for @inboxDraftPendingNote.
  ///
  /// In en, this message translates to:
  /// **'{date} · unsent drafts are not counted for future generation or learning'**
  String inboxDraftPendingNote(String date);

  /// No description provided for @inboxDraftCountedNote.
  ///
  /// In en, this message translates to:
  /// **'{date} · counted as a reference for future generation and learning'**
  String inboxDraftCountedNote(String date);

  /// No description provided for @inboxMarkSent.
  ///
  /// In en, this message translates to:
  /// **'Mark sent'**
  String get inboxMarkSent;

  /// No description provided for @inboxSentFallback.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get inboxSentFallback;

  /// No description provided for @inboxSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed'**
  String get inboxSendFailed;

  /// No description provided for @inboxMarkedSentFallback.
  ///
  /// In en, this message translates to:
  /// **'Marked as sent'**
  String get inboxMarkedSentFallback;

  /// No description provided for @inboxEmailDetails.
  ///
  /// In en, this message translates to:
  /// **'Email details'**
  String get inboxEmailDetails;

  /// No description provided for @inboxSentVia.
  ///
  /// In en, this message translates to:
  /// **'sent via {account}'**
  String inboxSentVia(String account);

  /// No description provided for @inboxReceivedVia.
  ///
  /// In en, this message translates to:
  /// **'received at {account}'**
  String inboxReceivedVia(String account);

  /// No description provided for @inboxAuthInfoMissing.
  ///
  /// In en, this message translates to:
  /// **'No sender authentication info found (the email may not include it, or the network is unavailable)'**
  String get inboxAuthInfoMissing;

  /// No description provided for @inboxAuthInfoLoading.
  ///
  /// In en, this message translates to:
  /// **'Fetching sender authentication info…'**
  String get inboxAuthInfoLoading;

  /// No description provided for @learnReset.
  ///
  /// In en, this message translates to:
  /// **'Reset learning history'**
  String get learnReset;

  /// No description provided for @learnResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset learning history'**
  String get learnResetTitle;

  /// No description provided for @learnResetContent.
  ///
  /// In en, this message translates to:
  /// **'This clears the \"consumed emails\" record; generated rules are kept. The next incremental learning run will re-read all history. Continue?'**
  String get learnResetContent;

  /// No description provided for @learnResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get learnResetConfirm;

  /// No description provided for @learnRunning.
  ///
  /// In en, this message translates to:
  /// **'Learning…'**
  String get learnRunning;

  /// No description provided for @learnStart.
  ///
  /// In en, this message translates to:
  /// **'Start incremental learning'**
  String get learnStart;

  /// No description provided for @learnIntro.
  ///
  /// In en, this message translates to:
  /// **'Distills reply rules from each account\'s \"{folders}\" and the last {months} months of inbox history (folder names vary by provider; set per account under \"Spaces\" → email account). While learning, customer mails and your replies are paired by thread to learn \"what was asked → how it was answered\" (accounts are learned one by one). Learned emails are never reused; mails are processed oldest-first with newer mails winning conflicts, so old mails never overwrite rules distilled from newer ones.'**
  String learnIntro(String folders, num months);

  /// No description provided for @learnProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get learnProcessing;

  /// No description provided for @learnFailedFoldersTitle.
  ///
  /// In en, this message translates to:
  /// **'Some learn folders failed to fetch'**
  String get learnFailedFoldersTitle;

  /// No description provided for @learnFailedFoldersHint.
  ///
  /// In en, this message translates to:
  /// **'On \"Spaces\" → email account → edit the account → history learn folders, use a folder name that actually exists on the server, or pick directly via \"Load folder list from server\"; common sent-folder names (Sent / Sent Messages / Sent Items / 已发送) match automatically, and when none match, learning falls back to the server\'s \\Sent flag.'**
  String get learnFailedFoldersHint;

  /// No description provided for @learnStatusSection.
  ///
  /// In en, this message translates to:
  /// **'Learning status'**
  String get learnStatusSection;

  /// No description provided for @learnConsumedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 email consumed} other{{count} emails consumed}}'**
  String learnConsumedCount(num count);

  /// No description provided for @learnLastRun.
  ///
  /// In en, this message translates to:
  /// **'Last learning run: {time}'**
  String learnLastRun(String time);

  /// No description provided for @learnNever.
  ///
  /// In en, this message translates to:
  /// **'Never learned'**
  String get learnNever;

  /// No description provided for @learnNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No learning history yet. Click \"Start incremental learning\" to distill rules from history.'**
  String get learnNoRecords;

  /// No description provided for @learnRecentSection.
  ///
  /// In en, this message translates to:
  /// **'Recently consumed emails (up to 200 shown)'**
  String get learnRecentSection;

  /// No description provided for @learnNoSubject.
  ///
  /// In en, this message translates to:
  /// **'(no subject)'**
  String get learnNoSubject;

  /// No description provided for @learnGeneratedRules.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 rule produced} other{{count} rules produced}}'**
  String learnGeneratedRules(num count);

  /// No description provided for @draftStatusEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get draftStatusEditing;

  /// No description provided for @draftStatusSentUnmodified.
  ///
  /// In en, this message translates to:
  /// **'Sent (unmodified)'**
  String get draftStatusSentUnmodified;

  /// No description provided for @draftStatusSentEdited.
  ///
  /// In en, this message translates to:
  /// **'Sent (edited)'**
  String get draftStatusSentEdited;

  /// No description provided for @draftStatusSentManually.
  ///
  /// In en, this message translates to:
  /// **'Sent (marked manually)'**
  String get draftStatusSentManually;

  /// No description provided for @draftStatusDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Discarded'**
  String get draftStatusDiscarded;

  /// No description provided for @draftConfirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get draftConfirmDeleteTitle;

  /// No description provided for @draftConfirmDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone (nothing will be sent).'**
  String get draftConfirmDeleteContent;

  /// No description provided for @draftMarkSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as sent'**
  String get draftMarkSentTitle;

  /// No description provided for @draftMarkSentContent.
  ///
  /// In en, this message translates to:
  /// **'Use this when you sent the draft outside this app (e.g. in the webmail).\nOnce marked, the content is counted as a reference for future generation and learning.'**
  String get draftMarkSentContent;

  /// No description provided for @draftMarkSentFeedback.
  ///
  /// In en, this message translates to:
  /// **'Compare my edits and improve rules'**
  String get draftMarkSentFeedback;

  /// No description provided for @draftMarkSentFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Uncheck if you changed the content again elsewhere'**
  String get draftMarkSentFeedbackHint;

  /// No description provided for @draftMarkSentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Mark'**
  String get draftMarkSentConfirm;

  /// No description provided for @draftConfirmSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm send'**
  String get draftConfirmSendTitle;

  /// No description provided for @draftSendCcNote.
  ///
  /// In en, this message translates to:
  /// **'CC: {ccs}'**
  String draftSendCcNote(String ccs);

  /// No description provided for @draftConfirmSendContent.
  ///
  /// In en, this message translates to:
  /// **'Will be sent to {to}{ccNote}\nSubject: Re: {subject}'**
  String draftConfirmSendContent(String to, String ccNote, String subject);

  /// No description provided for @draftSendKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get draftSendKeepEditing;

  /// No description provided for @draftsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If a draft was modified before sending, the change is analyzed automatically to improve the reply rules; unsent drafts are not counted for future generation or learning'**
  String get draftsSubtitle;

  /// No description provided for @draftsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No drafts yet — generate your first one from the inbox'**
  String get draftsEmpty;

  /// No description provided for @draftsTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{to} · {date} · based on {rules, plural, =1{1 rule} other{{rules} rules}}'**
  String draftsTileSubtitle(String to, String date, num rules);

  /// No description provided for @draftNotFound.
  ///
  /// In en, this message translates to:
  /// **'Draft not found'**
  String get draftNotFound;

  /// No description provided for @draftUnsentNote.
  ///
  /// In en, this message translates to:
  /// **'Unsent drafts are not counted for future generation or learning; only after sending or marking as sent does the content become a reference.'**
  String get draftUnsentNote;

  /// No description provided for @draftToLine.
  ///
  /// In en, this message translates to:
  /// **'To: {to}'**
  String draftToLine(String to);

  /// No description provided for @draftSenderMissing.
  ///
  /// In en, this message translates to:
  /// **'Send account: (no available send account in this space)'**
  String get draftSenderMissing;

  /// No description provided for @draftSenderLine.
  ///
  /// In en, this message translates to:
  /// **'Send account: {account}'**
  String draftSenderLine(String account);

  /// No description provided for @draftSenderFallbackNote.
  ///
  /// In en, this message translates to:
  /// **' (receive account can\'t send; using the default send account)'**
  String get draftSenderFallbackNote;

  /// No description provided for @draftGeneratedByLine.
  ///
  /// In en, this message translates to:
  /// **'Generated by: {model}'**
  String draftGeneratedByLine(String model);

  /// No description provided for @draftStatusLine.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String draftStatusLine(String status);

  /// No description provided for @draftEditHint.
  ///
  /// In en, this message translates to:
  /// **'The draft is generated from reply rules; edit directly or refine it via the AI chat on the right. On send, your edits are compared and the rules improve automatically.'**
  String get draftEditHint;

  /// No description provided for @draftCcLabel.
  ///
  /// In en, this message translates to:
  /// **'CC (original recipients auto-detected from forwarding; add or remove)'**
  String get draftCcLabel;

  /// No description provided for @draftAddCcHint.
  ///
  /// In en, this message translates to:
  /// **'Add a CC address'**
  String get draftAddCcHint;

  /// No description provided for @draftUsedRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply rules used ({count, plural, =1{1} other{{count}}})'**
  String draftUsedRulesTitle(num count);

  /// No description provided for @draftUsedRulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drafts are generated from rules only; anything the rules don\'t cover is never made up'**
  String get draftUsedRulesSubtitle;

  /// No description provided for @draftRuleSourceLine.
  ///
  /// In en, this message translates to:
  /// **'{category} · Source: {source}'**
  String draftRuleSourceLine(String category, String source);

  /// No description provided for @draftRuleUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rule improvements after sending'**
  String get draftRuleUpdatesTitle;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'AI refine'**
  String get chatTitle;

  /// No description provided for @chatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell the AI what to change; the updated body syncs to the editor on the left'**
  String get chatSubtitle;

  /// No description provided for @chatEmptyActive.
  ///
  /// In en, this message translates to:
  /// **'Chat with the AI to refine the draft, e.g.:\n\"Make the tone more sincere\" · \"Start by thanking them for the feedback\" · \"Drop the specific day-count promise\"'**
  String get chatEmptyActive;

  /// No description provided for @chatEmptyLocked.
  ///
  /// In en, this message translates to:
  /// **'This draft is finalized; chat is disabled'**
  String get chatEmptyLocked;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Tell the AI how to modify the draft…'**
  String get chatInputHint;

  /// No description provided for @chatSendButton.
  ///
  /// In en, this message translates to:
  /// **'Revise'**
  String get chatSendButton;

  /// No description provided for @chatCollapseBody.
  ///
  /// In en, this message translates to:
  /// **'Collapse body'**
  String get chatCollapseBody;

  /// No description provided for @chatExpandBody.
  ///
  /// In en, this message translates to:
  /// **'Body updated — click to view'**
  String get chatExpandBody;

  /// No description provided for @chatBusy.
  ///
  /// In en, this message translates to:
  /// **'AI is revising the draft…'**
  String get chatBusy;

  /// No description provided for @chatRefineFailed.
  ///
  /// In en, this message translates to:
  /// **'Revision failed: {error}'**
  String chatRefineFailed(String error);

  /// No description provided for @kbImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import .md / .txt documents'**
  String get kbImportButton;

  /// No description provided for @kbGenerateButton.
  ///
  /// In en, this message translates to:
  /// **'Generate rules for pending docs'**
  String get kbGenerateButton;

  /// No description provided for @kbSubtitle.
  ///
  /// In en, this message translates to:
  /// **'After-sales policies / FAQ / product info → distilled into reply rules; regenerate after a document changes (old rules are replaced)'**
  String get kbSubtitle;

  /// No description provided for @kbEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents yet. Import .md / .txt files to generate reply rules'**
  String get kbEmpty;

  /// No description provided for @kbDocSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Imported {time} · {size} KB · content {hash} · {status}'**
  String kbDocSubtitle(String time, String size, String hash, String status);

  /// No description provided for @kbStatusPending.
  ///
  /// In en, this message translates to:
  /// **'rules not generated yet'**
  String get kbStatusPending;

  /// No description provided for @kbStatusStale.
  ///
  /// In en, this message translates to:
  /// **'content changed, regeneration needed'**
  String get kbStatusStale;

  /// No description provided for @kbStatusFresh.
  ///
  /// In en, this message translates to:
  /// **'rules up to date'**
  String get kbStatusFresh;

  /// No description provided for @kbDeleteDoc.
  ///
  /// In en, this message translates to:
  /// **'Delete document'**
  String get kbDeleteDoc;

  /// No description provided for @commonEmpty.
  ///
  /// In en, this message translates to:
  /// **''**
  String get commonEmpty;

  /// No description provided for @commonRawError.
  ///
  /// In en, this message translates to:
  /// **'{text}'**
  String commonRawError(String text);

  /// No description provided for @commonErrorSeparator.
  ///
  /// In en, this message translates to:
  /// **'; '**
  String get commonErrorSeparator;

  /// No description provided for @llmReasonNoneConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configure an LLM in Settings first and assign it to the space'**
  String get llmReasonNoneConfigured;

  /// No description provided for @llmReasonNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'An LLM is configured in Settings; assign it to the current space on the Spaces page'**
  String get llmReasonNotAssigned;

  /// No description provided for @llmReasonDeleted.
  ///
  /// In en, this message translates to:
  /// **'The LLM assigned to this space has been deleted; reassign on the Spaces page'**
  String get llmReasonDeleted;

  /// No description provided for @llmReasonIncomplete.
  ///
  /// In en, this message translates to:
  /// **'The LLM assigned to this space is incomplete (missing API URL or model name); finish it in Settings'**
  String get llmReasonIncomplete;

  /// No description provided for @llmErrNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Fill in the Base URL and model name first'**
  String get llmErrNotConfigured;

  /// No description provided for @llmErrTruncated.
  ///
  /// In en, this message translates to:
  /// **'Output truncated by max_tokens (reasoning models\' thinking counts toward the budget); increase max tokens'**
  String get llmErrTruncated;

  /// No description provided for @llmErrEmptyPlain.
  ///
  /// In en, this message translates to:
  /// **'The model returned no content'**
  String get llmErrEmptyPlain;

  /// No description provided for @llmErrEmptyReason.
  ///
  /// In en, this message translates to:
  /// **'The model returned no content (finish_reason={reason})'**
  String llmErrEmptyReason(String reason);

  /// No description provided for @llmErrNotJson.
  ///
  /// In en, this message translates to:
  /// **'The model failed to output valid JSON after retries: {error}'**
  String llmErrNotJson(String error);

  /// No description provided for @llmErrHttp.
  ///
  /// In en, this message translates to:
  /// **'HTTP {status}: {detail}'**
  String llmErrHttp(String status, String detail);

  /// No description provided for @llmErrTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out ({seconds}s); increase the timeout in Settings'**
  String llmErrTimeout(num seconds);

  /// No description provided for @llmErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get llmErrNetwork;

  /// No description provided for @mailOpTimeout.
  ///
  /// In en, this message translates to:
  /// **'Mail operation did not complete within {seconds}s and was aborted (network unreachable or server unresponsive; try refreshing later)'**
  String mailOpTimeout(num seconds);

  /// No description provided for @mailOauthNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'This account signs in with OAuth2 (Outlook); complete Microsoft authorization in the account settings first'**
  String get mailOauthNotAuthorized;

  /// No description provided for @mailReceiveIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Receive configuration incomplete (address / IMAP server / password)'**
  String get mailReceiveIncomplete;

  /// No description provided for @mailSendIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Send configuration incomplete (address / SMTP server / password)'**
  String get mailSendIncomplete;

  /// No description provided for @mailConnectTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {host}:{port} timed out (auto-retried once): the server went silent after TLS, usually packet loss on a proxy/VPN node — switch nodes or disable the proxy temporarily and retry'**
  String mailConnectTimeout(String host, num port);

  /// No description provided for @mailTokenRefreshStall.
  ///
  /// In en, this message translates to:
  /// **'Microsoft token refresh stalled (two 22-second rounds with no progress): direct connections to login.microsoftonline.com are being blocked by the network — switch nodes, use global mode, or disable the proxy temporarily and retry'**
  String get mailTokenRefreshStall;

  /// No description provided for @mailFrTokenTimeout.
  ///
  /// In en, this message translates to:
  /// **'Cannot refresh the Microsoft token: direct connections to login.microsoftonline.com are blocked (usually a proxy/VPN issue). Switch nodes or use global mode in your proxy app and retry; it also recovers automatically once the network is back.'**
  String get mailFrTokenTimeout;

  /// No description provided for @mailFrInvalidGrant.
  ///
  /// In en, this message translates to:
  /// **'Microsoft authorization has expired ({raw}); sign in again in the account settings on the Spaces page'**
  String mailFrInvalidGrant(String raw);

  /// No description provided for @mailFrAuthRejected.
  ///
  /// In en, this message translates to:
  /// **'Login rejected by the server ({raw}). Personal Outlook accounts need IMAP enabled in the web settings: Settings → Mail → Sync email → POP and IMAP; for organizational accounts ask the admin to allow IMAP'**
  String mailFrAuthRejected(String raw);

  /// No description provided for @oauthBrowserFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the system browser; open this link manually to authorize:\n{url}'**
  String oauthBrowserFailed(String url);

  /// No description provided for @oauthWaitTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timed out waiting for browser authorization (5 minutes); try again'**
  String get oauthWaitTimeout;

  /// No description provided for @oauthStateMismatch.
  ///
  /// In en, this message translates to:
  /// **'Authorization callback validation failed (state mismatch); try again'**
  String get oauthStateMismatch;

  /// No description provided for @oauthAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'You canceled the authorization{detail}'**
  String oauthAccessDenied(String detail);

  /// No description provided for @oauthRejected.
  ///
  /// In en, this message translates to:
  /// **'Authorization denied: {error}{detail}'**
  String oauthRejected(String error, String detail);

  /// No description provided for @oauthNoCode.
  ///
  /// In en, this message translates to:
  /// **'Authorization callback is missing the code; try again'**
  String get oauthNoCode;

  /// No description provided for @oauthTokenTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timed out connecting to the Microsoft token service (no response in 20s): direct connections may be blocked by a proxy/VPN — check your proxy app (try switching nodes or global mode) and retry'**
  String get oauthTokenTimeout;

  /// No description provided for @oauthConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to the Microsoft token service: {error}'**
  String oauthConnectFailed(String error);

  /// No description provided for @oauthHttpError.
  ///
  /// In en, this message translates to:
  /// **'Microsoft token endpoint returned HTTP {status}: {detail}'**
  String oauthHttpError(String status, String detail);

  /// No description provided for @oauthNoBody.
  ///
  /// In en, this message translates to:
  /// **'no response body'**
  String get oauthNoBody;

  /// No description provided for @oauthTokenError.
  ///
  /// In en, this message translates to:
  /// **'Microsoft returned an authorization error: {error}{detail}'**
  String oauthTokenError(String error, String detail);

  /// No description provided for @oauthParseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse the token returned by Microsoft: {error}'**
  String oauthParseFailed(String error);

  /// No description provided for @learnFetchingHistory.
  ///
  /// In en, this message translates to:
  /// **'Fetching history emails…'**
  String get learnFetchingHistory;

  /// No description provided for @learnFetchingFolder.
  ///
  /// In en, this message translates to:
  /// **'Fetching {folder} of {email} (last {months} months)…'**
  String learnFetchingFolder(String email, String folder, num months);

  /// No description provided for @learnFetchingDetected.
  ///
  /// In en, this message translates to:
  /// **'Fetching {folder} of {email} (auto-detected)…'**
  String learnFetchingDetected(String email, String folder);

  /// No description provided for @learnFetchingInbox.
  ///
  /// In en, this message translates to:
  /// **'Fetching INBOX of {email} (pairing customer mails)…'**
  String learnFetchingInbox(String email);

  /// No description provided for @learnFailedNote.
  ///
  /// In en, this message translates to:
  /// **'; {count} accounts/folders failed to fetch (see warnings below)'**
  String learnFailedNote(num count);

  /// No description provided for @learnRecoveredNote.
  ///
  /// In en, this message translates to:
  /// **'; learn folders of {count} account(s) auto-detected and config updated'**
  String learnRecoveredNote(num count);

  /// No description provided for @learnNoNewEmails.
  ///
  /// In en, this message translates to:
  /// **'No new emails to learn (all consumed or outside the time range){failed}{recovered}'**
  String learnNoNewEmails(String failed, String recovered);

  /// No description provided for @learnDone.
  ///
  /// In en, this message translates to:
  /// **'Learning finished: {added} rules added, {updated} updated, {consumed} emails consumed{failed}{recovered}'**
  String learnDone(
    num added,
    num updated,
    num consumed,
    String failed,
    String recovered,
  );

  /// No description provided for @learnErrNeedSpace.
  ///
  /// In en, this message translates to:
  /// **'Create a space and configure email accounts on the Spaces page first'**
  String get learnErrNeedSpace;

  /// No description provided for @learnErrIncomplete.
  ///
  /// In en, this message translates to:
  /// **'No account in this space is fully configured (missing server or password)'**
  String get learnErrIncomplete;

  /// No description provided for @learnErrFailed.
  ///
  /// In en, this message translates to:
  /// **'Learning failed: {error}'**
  String learnErrFailed(String error);

  /// No description provided for @learnErrNoRulesArray.
  ///
  /// In en, this message translates to:
  /// **'The model output object contains no rules array'**
  String get learnErrNoRulesArray;

  /// No description provided for @learnErrNotRulesArray.
  ///
  /// In en, this message translates to:
  /// **'The model output is not a rules array ({type})'**
  String learnErrNotRulesArray(String type);

  /// No description provided for @learnStageAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing thread batch {index}/{total}'**
  String learnStageAnalyzing(num index, num total);

  /// No description provided for @learnStageMerging.
  ///
  /// In en, this message translates to:
  /// **'Merging rules (batch {index}/{total})'**
  String learnStageMerging(num index, num total);

  /// No description provided for @kbStageExtracting.
  ///
  /// In en, this message translates to:
  /// **'Extracting rules from \"{doc}\" (chunk {index}/{total})'**
  String kbStageExtracting(String doc, num index, num total);

  /// No description provided for @kbImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing documents…'**
  String get kbImporting;

  /// No description provided for @kbImported.
  ///
  /// In en, this message translates to:
  /// **'Import finished: {count} documents'**
  String kbImported(num count);

  /// No description provided for @kbImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String kbImportFailed(String error);

  /// No description provided for @kbPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing rule generation…'**
  String get kbPreparing;

  /// No description provided for @kbNoDocs.
  ///
  /// In en, this message translates to:
  /// **'No documents need rule generation'**
  String get kbNoDocs;

  /// No description provided for @kbGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated {rules} rules for {docs} documents'**
  String kbGenerated(num docs, num rules);

  /// No description provided for @kbGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Generation failed: {error}'**
  String kbGenerateFailed(String error);

  /// No description provided for @inboxPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing to sync…'**
  String get inboxPreparing;

  /// No description provided for @inboxSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing {email} {role}…'**
  String inboxSyncing(String email, String role);

  /// No description provided for @inboxErrNoSpace.
  ///
  /// In en, this message translates to:
  /// **'Create a space and configure email accounts on the Spaces page first'**
  String get inboxErrNoSpace;

  /// No description provided for @inboxErrNoReceiver.
  ///
  /// In en, this message translates to:
  /// **'No account in the current space has receiving enabled'**
  String get inboxErrNoReceiver;

  /// No description provided for @inboxErrIncomplete.
  ///
  /// In en, this message translates to:
  /// **'{email}: incomplete configuration ({reason})'**
  String inboxErrIncomplete(String email, String reason);

  /// No description provided for @inboxReasonNoImap.
  ///
  /// In en, this message translates to:
  /// **'missing IMAP server configuration'**
  String get inboxReasonNoImap;

  /// No description provided for @inboxReasonOauth.
  ///
  /// In en, this message translates to:
  /// **'Microsoft authorization not completed (sign in again in the account settings)'**
  String get inboxReasonOauth;

  /// No description provided for @inboxReasonNoPassword.
  ///
  /// In en, this message translates to:
  /// **'missing password (keychain returned no app password for this account)'**
  String get inboxReasonNoPassword;

  /// No description provided for @inboxErrSentMissing.
  ///
  /// In en, this message translates to:
  /// **'{email}: sent folder not found, skipped'**
  String inboxErrSentMissing(String email);

  /// No description provided for @inboxErrSyncFailedCached.
  ///
  /// In en, this message translates to:
  /// **'{email} {role}: sync failed (showing cache): {error}'**
  String inboxErrSyncFailedCached(String email, String role, String error);

  /// No description provided for @inboxErrSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'{email} {role}: {error}'**
  String inboxErrSyncFailed(String email, String role, String error);

  /// No description provided for @inboxErrInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Refresh interrupted: {error}'**
  String inboxErrInterrupted(String error);

  /// No description provided for @draftsErrNeedSpace.
  ///
  /// In en, this message translates to:
  /// **'Create a space first'**
  String get draftsErrNeedSpace;

  /// No description provided for @draftsMsgExisting.
  ///
  /// In en, this message translates to:
  /// **'An in-progress draft already exists for this email; opened it for you'**
  String get draftsMsgExisting;

  /// No description provided for @draftsErrRulesEmpty.
  ///
  /// In en, this message translates to:
  /// **'The rule library is empty: drafts are generated from reply rules only — generate rules first in Learning / Knowledge / Rules'**
  String get draftsErrRulesEmpty;

  /// No description provided for @draftsErrRulesDisabled.
  ///
  /// In en, this message translates to:
  /// **'All rules are currently disabled; enable rules in the rule library first'**
  String get draftsErrRulesDisabled;

  /// No description provided for @draftsErrRulesEmptyGen.
  ///
  /// In en, this message translates to:
  /// **'The rule library is empty; generate reply rules from history emails, the knowledge base, or a custom prompt first'**
  String get draftsErrRulesEmptyGen;

  /// No description provided for @draftsErrGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Draft generation failed: {error}'**
  String draftsErrGenerateFailed(String error);

  /// No description provided for @draftsErrNoSender.
  ///
  /// In en, this message translates to:
  /// **'No account in this space can send (enable sending for an account in Spaces)'**
  String get draftsErrNoSender;

  /// No description provided for @draftsErrSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed: {error}'**
  String draftsErrSendFailed(String error);

  /// No description provided for @draftsErrNoBody.
  ///
  /// In en, this message translates to:
  /// **'The model did not return a revised body'**
  String get draftsErrNoBody;

  /// No description provided for @draftsFbSent.
  ///
  /// In en, this message translates to:
  /// **'Sent. {feedback}'**
  String draftsFbSent(String feedback);

  /// No description provided for @draftsFbModifiedNoAdjust.
  ///
  /// In en, this message translates to:
  /// **'Edits detected; rules optimized: no adjustments needed this time'**
  String get draftsFbModifiedNoAdjust;

  /// No description provided for @draftsFbModifiedUpdates.
  ///
  /// In en, this message translates to:
  /// **'Edits detected; rules optimized: {updates}'**
  String draftsFbModifiedUpdates(String updates);

  /// No description provided for @draftsFbUnmodified.
  ///
  /// In en, this message translates to:
  /// **'The draft was sent unmodified; related rules got positive feedback'**
  String get draftsFbUnmodified;

  /// No description provided for @draftsFbFailed.
  ///
  /// In en, this message translates to:
  /// **', but rule feedback learning failed: {error}'**
  String draftsFbFailed(String error);

  /// No description provided for @draftsFbSkipped.
  ///
  /// In en, this message translates to:
  /// **'(no LLM configured; rule feedback learning skipped)'**
  String get draftsFbSkipped;

  /// No description provided for @draftsMarkedPlain.
  ///
  /// In en, this message translates to:
  /// **'Marked as sent manually. The content is counted as a reference for future generation and learning.'**
  String get draftsMarkedPlain;

  /// No description provided for @draftsMarkedWithFeedback.
  ///
  /// In en, this message translates to:
  /// **'Marked as sent manually. {feedback}'**
  String draftsMarkedWithFeedback(String feedback);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
