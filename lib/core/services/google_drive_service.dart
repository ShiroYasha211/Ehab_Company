import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class GoogleDriveService extends GetxService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope, // الوصول فقط للملفات التي ينشئها التطبيق
      drive.DriveApi.driveAppdataScope, // أو استخدام مجلد البيانات المخفي
    ],
  );

  Rx<GoogleSignInAccount?> currentUser = Rx<GoogleSignInAccount?>(null);

  @override
  void onInit() {
    super.onInit();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      currentUser.value = account;
    });
    _googleSignIn.signInSilently();
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      print('Google Sign-In Error: $error');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient == null) return null;
    return drive.DriveApi(httpClient);
  }

  /// رفع ملف قاعدة البيانات إلى Google Drive
  Future<bool> uploadBackup(File file) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final String fileName = 'ehab_backup_$timestamp.db';

      final driveFile = drive.File();
      driveFile.name = fileName;
      driveFile.mimeType = 'application/x-sqlite3'; // تحديد النوع بشكل صريح
      // driveFile.parents = ['appDataFolder']; // اختيار مجلد البيانات المخفي

      final media = drive.Media(file.openRead(), file.lengthSync());
      
      await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      return true;
    } catch (e) {
      print('Upload to Drive Error: $e');
      return false;
    }
  }

  /// جلب قائمة النسخ الاحتياطية الموجودة في الدرايف
  Future<List<drive.File>> getBackupsList() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return [];

      final fileList = await driveApi.files.list(
        q: "name contains 'ehab_backup_'", // إزالة فلتر النوع لزيادة الدقة في العثور على كل الملفات
        orderBy: 'createdTime desc',
        spaces: 'drive',
      );

      return fileList.files ?? [];
    } catch (e) {
      print('List Drive Backups Error: $e');
      return [];
    }
  }

  /// تحميل نسخة احتياطية من الدرايف إلى ملف محلي
  Future<File?> downloadBackup(String fileId, String localPath) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      drive.Media response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.metadata,
      ) as drive.Media; // This might be wrong in some versions, normally it's alt=media

      // Correct way to download media in newer googleapis:
      final drive.Media media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataStore = [];
      await for (final data in media.stream) {
        dataStore.addAll(data);
      }

      final File file = File(localPath);
      await file.writeAsBytes(dataStore);
      return file;
    } catch (e) {
      print('Download from Drive Error: $e');
      return null;
    }
  }
}
