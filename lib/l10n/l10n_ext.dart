import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// UI 层取文案的快捷入口：`context.l10n.navInbox`。
extension L10nContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
