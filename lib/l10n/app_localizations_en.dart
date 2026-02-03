// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pseudo-Code Interpreter';

  @override
  String get openFileToStart => 'Open a file to start';

  @override
  String get errorFileExtension =>
      'Cannot execute this file. Extension must be \'.alg\'.';

  @override
  String get searchHint => 'Search...';

  @override
  String get replaceHint => 'Replace...';

  @override
  String get replaceAll => 'All';

  @override
  String get replaceCurrent => 'One';

  @override
  String get close => 'Close';

  @override
  String get run => 'Run';

  @override
  String get debug => 'Debug';

  @override
  String get console => 'Console';

  @override
  String get explorer => 'Explorer';
}
