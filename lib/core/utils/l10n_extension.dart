import 'package:flutter/widgets.dart';
import 'package:moodtrack/l10n/app_localizations.dart';

extension L10nExtension on BuildContext {
  /// A quick global helper to access AppLocalizations
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
