import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pseudo_code/interpreteur/linter.dart'; // Import pour LintIssue

class AppFile {
  String path; // Changed from final to support rename
  String content;
  bool isModified;

  AppFile({required this.path, required this.content, this.isModified = false});

  String get name => path.split(Platform.pathSeparator).last;
  String get extension => name.split('.').last;
}

class FileProvider with ChangeNotifier {
  final List<AppFile> _openFiles = [];
  int _activeTabIndex = -1;
  String? _selectedFileInExplorer;
  String _currentDirectory = "";
  final List<String> _expandedFolders = [];
  String? _proposedCode;
  bool _isReviewMode = false;

  String? get proposedCode => _proposedCode;
  bool get isReviewMode => _isReviewMode;

  List<LintIssue> _anomalies = [];
  List<LintIssue> get anomalies => _anomalies;

  List<AppFile> get openFiles => _openFiles;
  int get activeTabIndex => _activeTabIndex;
  String? get selectedFileInExplorer => _selectedFileInExplorer;
  String get currentDirectory => _currentDirectory;
  List<String> get expandedFolders => _expandedFolders;

  AppFile? get activeFile =>
      _activeTabIndex != -1 && _activeTabIndex < _openFiles.length
      ? _openFiles[_activeTabIndex]
      : null;

  FileProvider({List<String>? initialFiles}) {
    _currentDirectory = Directory.current.path;
    _initDefaultDirectory();
    if (initialFiles != null && initialFiles.isNotEmpty) {
      handleExternalFiles(initialFiles);
    }
  }

  void handleExternalFiles(List<String> paths) {
    for (final path in paths) {
      openFile(path);
    }
  }

  Future<void> _initDefaultDirectory() async {
    try {
      String? targetPath;

      if (Platform.isAndroid || Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        targetPath = p.join(directory.path, "Algorithme");
      } else {
        String? home;
        if (Platform.isWindows) {
          home = Platform.environment['USERPROFILE'];
        } else {
          home = Platform.environment['HOME'];
        }

        if (home != null) {
          String? desktopPath;
          final List<String> desktopNames = ['Desktop', 'Bureau'];
          for (final name in desktopNames) {
            final path = p.join(home, name);
            if (await Directory(path).exists()) {
              desktopPath = path;
              break;
            }
          }
          desktopPath ??= home;
          targetPath = p.join(desktopPath, "Algorithme");
        }
      }

      if (targetPath != null) {
        final algoDir = Directory(targetPath);
        if (!await algoDir.exists()) {
          await algoDir.create(recursive: true);
          debugPrint("Dossier Algorithme créé : $targetPath");
        }

        // --- Bundling demo files ---
        await _copyAssetToFile("Exemple(alg).alg", targetPath);
        await _copyAssetToFile("Exemple(CSI).csi", targetPath);

        setDirectory(targetPath);
      }
    } catch (e) {
      debugPrint("Erreur initialisation dossier par défaut: $e");
    }
  }

  Future<void> _copyAssetToFile(String assetName, String targetDir) async {
    try {
      final targetPath = p.join(targetDir, assetName);
      final file = File(targetPath);
      if (!await file.exists()) {
        final data = await rootBundle.load('assets/$assetName');
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await file.writeAsBytes(bytes);
        debugPrint("Asset $assetName copié vers $targetPath");
      }
    } catch (e) {
      debugPrint("Erreur lors de la copie de l'asset $assetName : $e");
    }
  }

  void setDirectory(String path) {
    _currentDirectory = path;
    _expandedFolders.clear();
    _selectedFileInExplorer = null;
    notifyListeners();
  }

  Future<void> pickDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choisir un dossier de travail',
      );

      if (selectedDirectory != null) {
        setDirectory(selectedDirectory);
      }
    } catch (e) {
      debugPrint("Erreur lors de la sélection du dossier: $e");
    }
  }

  void toggleFolder(String path) {
    if (_expandedFolders.contains(path)) {
      _expandedFolders.remove(path);
    } else {
      _expandedFolders.add(path);
    }
    notifyListeners();
  }

  void selectFileInExplorer(String? path) {
    _selectedFileInExplorer = path;
    notifyListeners();
  }

  void createFile(String parentPath, String name) async {
    try {
      final fullPath = p.join(parentPath, name);
      final file = File(fullPath);
      if (!await file.exists()) {
        await file.create();
        openFile(fullPath);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erreur creation fichier: $e");
    }
  }

  void createDirectory(String parentPath, String name) async {
    try {
      final fullPath = p.join(parentPath, name);
      final dir = Directory(fullPath);
      if (!await dir.exists()) {
        await dir.create();
        toggleFolder(fullPath);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erreur creation dossier: $e");
    }
  }

  Future<void> renameFile(String oldPath, String newName) async {
    try {
      final dir = p.dirname(oldPath);
      final newPath = p.join(dir, newName);
      final file = File(oldPath);
      if (await file.exists()) {
        await file.rename(newPath);

        // Update open files
        for (var openFile in _openFiles) {
          if (openFile.path == oldPath) {
            openFile.path = newPath;
          }
        }
        if (_selectedFileInExplorer == oldPath) {
          _selectedFileInExplorer = newPath;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erreur renommage fichier: $e");
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();

        // Close if open
        final index = _openFiles.indexWhere((f) => f.path == path);
        if (index != -1) {
          closeFile(index);
        }
        if (_selectedFileInExplorer == path) {
          _selectedFileInExplorer = null;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erreur suppression fichier: $e");
    }
  }

  Future<void> renameDirectory(String oldPath, String newName) async {
    try {
      final parent = p.dirname(oldPath);
      final newPath = p.join(parent, newName);
      final dir = Directory(oldPath);
      if (await dir.exists()) {
        await dir.rename(newPath);

        // Update all open files within this directory
        for (var openFile in _openFiles) {
          if (p.isWithin(oldPath, openFile.path)) {
            openFile.path = openFile.path.replaceFirst(oldPath, newPath);
          }
        }

        if (_selectedFileInExplorer != null &&
            p.isWithin(oldPath, _selectedFileInExplorer!)) {
          _selectedFileInExplorer = _selectedFileInExplorer!.replaceFirst(
            oldPath,
            newPath,
          );
        }

        // Update expanded folders
        for (int i = 0; i < _expandedFolders.length; i++) {
          if (_expandedFolders[i] == oldPath ||
              p.isWithin(oldPath, _expandedFolders[i])) {
            _expandedFolders[i] = _expandedFolders[i].replaceFirst(
              oldPath,
              newPath,
            );
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erreur renommage dossier: $e");
    }
  }

  Future<void> deleteDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);

        // Close all open files within this directory
        _openFiles.removeWhere((file) => p.isWithin(path, file.path));
        if (_activeTabIndex >= _openFiles.length) {
          _activeTabIndex = _openFiles.length - 1;
        }

        if (_selectedFileInExplorer != null &&
            p.isWithin(path, _selectedFileInExplorer!)) {
          _selectedFileInExplorer = null;
        }

        _expandedFolders.removeWhere((f) => f == path || p.isWithin(path, f));

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erreur suppression dossier: $e");
    }
  }

  void openFile(String path) async {
    final existingIndex = _openFiles.indexWhere((f) => f.path == path);
    if (existingIndex != -1) {
      _activeTabIndex = existingIndex;
      notifyListeners();
      return;
    }

    try {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        _openFiles.add(AppFile(path: path, content: content));
        _activeTabIndex = _openFiles.length - 1;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erreur lors de l'ouverture du fichier: $e");
    }
  }

  void proposeCodeChange(String newCode) {
    if (activeFile != null && newCode.trim().isNotEmpty) {
      _proposedCode = newCode;
      _isReviewMode = true;
      notifyListeners();
    }
  }

  void acceptChange() {
    if (activeFile != null && _proposedCode != null) {
      updateContent(_proposedCode!);
      _proposedCode = null;
      _isReviewMode = false;
      notifyListeners();
    }
  }

  void discardChange() {
    _proposedCode = null;
    _isReviewMode = false;
    notifyListeners();
  }

  void setActiveTab(int index) {
    if (index >= 0 && index < _openFiles.length) {
      // Si on change d'onglet, on abandonne le mode review en cours
      _proposedCode = null;
      _isReviewMode = false;
      _activeTabIndex = index;
      notifyListeners();
    }
  }

  void closeFile(int index) {
    if (index >= 0 && index < _openFiles.length) {
      _openFiles.removeAt(index);
      if (_activeTabIndex >= _openFiles.length) {
        _activeTabIndex = _openFiles.length - 1;
      }
      notifyListeners();
    }
  }

  void updateContent(String newContent) {
    if (activeFile != null) {
      if (activeFile!.content != newContent) {
        activeFile!.content = newContent;
        activeFile!.isModified = true;
        lancerAnalyseStatique(newContent);
        notifyListeners();
      }
    }
  }

  void lancerAnalyseStatique(String code) {
    _anomalies = Linter.analyser(code);
    notifyListeners();
  }

  Future<void> saveCurrentFile() async {
    if (activeFile != null) {
      try {
        final file = File(activeFile!.path);
        await file.writeAsString(activeFile!.content);
        activeFile!.isModified = false;
        notifyListeners();
      } catch (e) {
        debugPrint("Erreur lors de la sauvegarde: $e");
      }
    }
  }

  final _insertRequestController = StreamController<String>.broadcast();
  Stream<String> get insertRequests => _insertRequestController.stream;

  void requestInsertion(String snippet) {
    if (activeFile != null) {
      _insertRequestController.add(snippet);
    }
  }

  void insertText(String text) {
    // Rediriger vers le nouveau flux de requête pour bénéficier de la review
    requestInsertion(text);
  }

  void insertCode(String code) {
    // Rediriger vers le nouveau flux de requête
    requestInsertion(code);
  }
}
