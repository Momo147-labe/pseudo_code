import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'backblaze_service.dart';
import 'local_notification_service.dart';

/// Service central de gestion des mises à jour (Android & Windows)
class UpdateService {
  static final UpdateService instance = UpdateService._internal();
  factory UpdateService() => instance;
  UpdateService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isChecking = false;

  /// Vérifie si une nouvelle version est disponible sur Supabase
  Future<void> checkForUpdate(
    BuildContext context, {
    bool isManual = false,
  }) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      debugPrint("Vérification des mises à jour...");
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      final platform = Platform.isAndroid
          ? 'android'
          : (Platform.isWindows
                ? 'windows'
                : (Platform.isLinux ? 'linux' : null));
      if (platform == null) return;

      final response = await _supabase
          .from('pseudo_code_app_versions')
          .select()
          .eq('platform', platform)
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final latestVersionCode = response['version_code'] as int;
        final fileName = response['file_url'] as String;
        final isForced = response['is_forced'] as bool;
        final releaseNotes = response['release_notes'] as String?;

        if (latestVersionCode > currentVersionCode) {
          debugPrint("Nouvelle version détectée : $latestVersionCode");
          if (context.mounted) {
            _showUpdateDialog(context, fileName, isForced, releaseNotes);
          }
        } else if (isManual && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "L'application est déjà à jour (v${packageInfo.version}+$currentVersionCode)",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (isManual && context.mounted) {
        // Aucune version trouvée dans la table pour cette plateforme
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Aucune mise à jour disponible pour cette plateforme.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur lors de la vérification de mise à jour: $e");
      if (isManual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur de connexion : $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isChecking = false;
    }
  }

  void _showUpdateDialog(
    BuildContext context,
    String fileName,
    bool isForced,
    String? releaseNotes,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !isForced,
      builder: (context) {
        bool isDownloading = false;
        double progress = 0;
        return StatefulBuilder(
          builder: (context, setState) {
            return PopScope(
              canPop: !isForced,
              child: AlertDialog(
                title: Text(
                  isDownloading
                      ? 'Téléchargement...'
                      : 'Mise à jour disponible',
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isDownloading) ...[
                      Text(
                        'Une nouvelle version est disponible.${isForced ? "\n\nCette mise à jour est obligatoire." : ""}',
                      ),
                      if (releaseNotes != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Notes : $releaseNotes',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ] else ...[
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 10),
                      Text('${(progress * 100).toInt()}%'),
                    ],
                  ],
                ),
                actions: [
                  if (!isDownloading) ...[
                    if (!isForced)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Plus tard'),
                      ),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() => isDownloading = true);
                        try {
                          await _executeUpgrade(
                            fileName,
                            onProgress: (p) => setState(() => progress = p),
                          );
                          if (context.mounted && !isForced)
                            Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted)
                            setState(() => isDownloading = false);
                        }
                      },
                      child: const Text('Mettre à jour'),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _executeUpgrade(
    String fileName, {
    required Function(double) onProgress,
  }) async {
    final b2 = BackblazeService.instance;
    final fileId = await b2.getFileIdByName(fileName);
    if (fileId == null) throw Exception("Fichier introuvable sur B2");

    final localPath = await b2.getLocalPath(fileName);

    // Téléchargement
    await b2.downloadFile(fileId, fileName, (p) {
      onProgress(p);
      if (Platform.isAndroid) {
        LocalNotificationService.instance.showProgressNotification(
          id: 999,
          title: "Mise à jour...",
          body: "${(p * 100).toInt()}%",
          progress: (p * 100).toInt(),
          maxProgress: 100,
        );
      }
    });

    if (Platform.isAndroid) {
      LocalNotificationService.instance.cancel(999);
      await OpenFilex.open(localPath);
    } else if (Platform.isWindows) {
      // Sur Windows, on lance l'exécutable et on ferme l'app
      await Process.start(localPath, []);
      exit(0);
    } else if (Platform.isLinux) {
      // Sur Linux, on rend le fichier exécutable et on le lance
      await Process.run('chmod', ['+x', localPath]);
      await Process.start(localPath, []);
      exit(0);
    }
  }
}
