// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Interpréteur Pseudo-Code';

  @override
  String get openFileToStart => 'Ouvrez un fichier pour commencer';

  @override
  String get errorFileExtension =>
      'Impossible d\'exécuter ce fichier. L\'extension doit être \'.alg\'.';

  @override
  String get searchHint => 'Rechercher...';

  @override
  String get replaceHint => 'Remplacer...';

  @override
  String get replaceAll => 'Tout';

  @override
  String get replaceCurrent => 'Un';

  @override
  String get close => 'Fermer';

  @override
  String get run => 'Exécuter';

  @override
  String get debug => 'Déboguer';

  @override
  String get console => 'Console';

  @override
  String get explorer => 'Explorateur';
}
