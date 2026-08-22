import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import 'failure.dart';

String localizeFailure(BuildContext c, Failure f) {
  final l = AppLocalizations.of(c);
  switch (f.code) {
    case 'auth':
      return "Session expired";
    case 'network':
      return "Server unavailable";
    default:
      return "Unknown error";
  }
}
