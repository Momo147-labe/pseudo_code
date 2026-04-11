import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';

/// Service de notifications pour afficher la progression des téléchargements
class LocalNotificationService {
  static final LocalNotificationService instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Ouvrir');

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          linux: initializationSettingsLinux,
        );

    await plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (details.payload != null &&
            details.payload!.startsWith('install:')) {
          final path = details.payload!.replaceFirst('install:', '');
          await OpenFilex.open(path);
        }
      },
    );

    if (Platform.isAndroid) {
      final androidImplementation = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImplementation?.requestNotificationsPermission();
    }

    _isInitialized = true;
    debugPrint('LocalNotificationService initialisé.');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'app_updates',
          'Mises à jour',
          channelDescription: 'Notifications relatives aux mises à jour',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await plugin.show(id, title, body, platformDetails, payload: payload);
  }

  Future<void> showProgressNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'app_updates_progress',
          'Téléchargements',
          channelDescription: 'Progression des téléchargements',
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          showProgress: true,
          maxProgress: maxProgress,
          progress: progress,
          ongoing: true,
        );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await plugin.show(id, title, body, platformDetails);
  }

  Future<void> cancel(int id) async {
    await plugin.cancel(id);
  }
}
