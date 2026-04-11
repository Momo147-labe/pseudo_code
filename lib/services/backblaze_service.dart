import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour intéragir avec Backblaze B2 (Stockage Cloud)
class BackblazeService {
  static final BackblazeService instance = BackblazeService._init();
  BackblazeService._init();

  String? _authToken;
  String? _apiUrl;
  String? _downloadUrl;

  final String _keyId = dotenv.get('BACKBLAZE_keyID');
  final String _applicationKey = dotenv.get('BACKBLAZE_applicationKey');
  final String _bucketId = dotenv.get('BACKBLAZE_BUCKET_ID');

  static const String _fileListCacheKey = 'b2_file_list_cache';
  List<Map<String, dynamic>>? _cachedFiles;

  Future<void> _authorize() async {
    if (_authToken != null) return;

    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$_keyId:$_applicationKey'))}';
    final response = await http.get(
      Uri.parse('https://api.backblazeb2.com/b2api/v2/b2_authorize_account'),
      headers: {'Authorization': basicAuth},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _authToken = data['authorizationToken'];
      _apiUrl = data['apiUrl'];
      _downloadUrl = data['downloadUrl'];
    } else {
      throw Exception('B2 Authorization failed: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> listFiles({
    bool forceRefresh = false,
  }) async {
    await _authorize();

    if (!forceRefresh && _cachedFiles != null) return _cachedFiles!;

    final prefs = await SharedPreferences.getInstance();
    if (!forceRefresh) {
      final cachedData = prefs.getString(_fileListCacheKey);
      if (cachedData != null) {
        try {
          _cachedFiles = List<Map<String, dynamic>>.from(
            jsonDecode(cachedData),
          );
          return _cachedFiles!;
        } catch (e) {
          // Cache invalide
        }
      }
    }

    final response = await http.post(
      Uri.parse('$_apiUrl/b2api/v2/b2_list_file_names'),
      headers: {'Authorization': _authToken!},
      body: jsonEncode({'bucketId': _bucketId, 'maxFileCount': 1000}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _cachedFiles = List<Map<String, dynamic>>.from(data['files']);
      await prefs.setString(_fileListCacheKey, jsonEncode(_cachedFiles));
      return _cachedFiles!;
    } else {
      throw Exception('Failed to list B2 files: ${response.body}');
    }
  }

  Future<String?> getFileIdByName(String fileName) async {
    final files = await listFiles();
    try {
      final file = files.firstWhere((f) => f['fileName'] == fileName);
      return file['fileId'] as String?;
    } catch (e) {
      debugPrint('Fichier $fileName non trouvé sur Backblaze B2');
      return null;
    }
  }

  String getDownloadUrlById(String fileId) {
    if (_downloadUrl == null) {
      throw Exception(
        'Service non autorisé. Appelez authorize ou listFiles d\'abord.',
      );
    }
    return '$_downloadUrl/b2api/v2/b2_download_file_by_id?fileId=$fileId';
  }

  Map<String, String> getDownloadHeaders() {
    return {'Authorization': _authToken!};
  }

  Future<String> getLocalPath(String fileName) async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/updates';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return '$path/$fileName';
  }

  Future<void> downloadFile(
    String fileId,
    String fileName,
    Function(double) onProgress,
  ) async {
    await _authorize();

    final localPath = await getLocalPath(fileName);
    final file = File(localPath);
    int currentSize = 0;
    if (await file.exists()) {
      currentSize = await file.length();
    }

    final url = getDownloadUrlById(fileId);
    final request = http.Request('GET', Uri.parse(url));
    request.headers.addAll(getDownloadHeaders());

    // Reprise du téléchargement si possible
    if (currentSize > 0) {
      request.headers['Range'] = 'bytes=$currentSize-';
      debugPrint('Reprise du téléchargement à $currentSize octets');
    }

    final client = http.Client();
    try {
      final response = await client.send(request);

      final isResuming = response.statusCode == 206;
      final totalToDownload = response.contentLength ?? 0;
      final fullSize = isResuming
          ? totalToDownload + currentSize
          : totalToDownload;
      int downloadedSoFar = isResuming ? currentSize : 0;

      final IOSink sink = file.openWrite(
        mode: isResuming ? FileMode.append : FileMode.write,
      );

      await response.stream
          .listen(
            (chunk) {
              downloadedSoFar += chunk.length;
              if (fullSize > 0) {
                onProgress(downloadedSoFar / fullSize);
              }
              sink.add(chunk);
            },
            onDone: () async {
              await sink.close();
              client.close();
            },
            onError: (e) async {
              await sink.close();
              client.close();
              throw e;
            },
            cancelOnError: true,
          )
          .asFuture();
    } catch (e) {
      client.close();
      rethrow;
    }
  }
}
