import 'dart:io';
import 'package:ehab_company_admin/core/services/backup_service.dart';
import 'package:ehab_company_admin/core/services/google_drive_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DataManagementScreen extends StatelessWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // حقن الخدمات
    final BackupService backupService = Get.put(BackupService());
    final GoogleDriveService driveService = Get.put(GoogleDriveService());

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة البيانات والنسخ')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('النسخ الاحتياطي المحلي', Icons.storage_rounded),
              const SizedBox(height: 15),
              _buildLocalBackupSection(context, backupService),
              
              const SizedBox(height: 30),
              _buildSectionTitle('النسخ الاحتياطي السحابي', Icons.cloud_done_rounded),
              const SizedBox(height: 15),
              _buildCloudBackupSection(context, driveService, backupService),
              
              const SizedBox(height: 40),
              _buildWarningSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
      ],
    );
  }

  Widget _buildLocalBackupSection(BuildContext context, BackupService backupService) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildActionButton(
              context,
              icon: Icons.save_alt_rounded,
              label: 'إنشاء نسخة احتياطية محلية',
              color: Colors.blue.shade700,
              onPressed: () => backupService.createBackup(),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              icon: Icons.settings_backup_restore_rounded,
              label: 'استعادة من ملف محلي',
              color: Colors.orange.shade800,
              onPressed: () => backupService.restoreBackup(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudBackupSection(BuildContext context, GoogleDriveService driveService, BackupService backupService) {
    return Obx(() {
      final user = driveService.currentUser.value;
      
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: user == null 
            ? _buildGoogleSignInPrompt(driveService)
            : _buildGoogleUserActions(context, driveService, user),
        ),
      );
    });
  }

  Widget _buildGoogleSignInPrompt(GoogleDriveService driveService) {
    return Column(
      children: [
        const Text(
          'قم بربط حسابك في Google Drive لتخزين بياناتك بأمان في السحاب والوصول إليها من أي جهاز.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.login_rounded),
          label: const Text('تسجيل الدخول باستخدام Google'),
          onPressed: () => driveService.signIn(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleUserActions(BuildContext context, GoogleDriveService driveService, GoogleSignInAccount user) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null ? const Icon(Icons.person) : null,
          ),
          title: Text(user.displayName ?? 'مستخدم جوجل'),
          subtitle: Text(user.email, style: const TextStyle(fontSize: 11)),
          trailing: TextButton(
            onPressed: () => driveService.signOut(),
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ),
        const Divider(),
        const SizedBox(height: 10),
        _buildActionButton(
          context,
          icon: Icons.cloud_upload_rounded,
          label: 'نسخ إلى Google Drive',
          color: Colors.teal.shade700,
          onPressed: () async {
            Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
            try {
              final dbPath = await getDatabasesPath();
              final backupFile = File(p.join(dbPath, 'ehab_company.db'));
              final success = await driveService.uploadBackup(backupFile);
              Get.back();
              if (success) {
                Get.snackbar('نجاح', 'تم رفع النسخة الاحتياطية للسحاب بنجاح');
              } else {
                Get.snackbar('خطأ', 'فشل رفع النسخة السحابية');
              }
            } catch (e) {
              Get.back();
              Get.snackbar('خطأ', 'حدث خطأ غير متوقع: $e');
            }
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          icon: Icons.cloud_download_rounded,
          label: 'استعادة من Google Drive',
          color: Colors.deepPurple.shade700,
          onPressed: () => _showCloudBackupsDialog(context, driveService),
        ),
      ],
    );
  }

  void _showCloudBackupsDialog(BuildContext context, GoogleDriveService driveService) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    final backups = await driveService.getBackupsList();
    Get.back();

    if (backups.isEmpty) {
      Get.snackbar('تنبيه', 'لم يتم العثور على أي نسخ احتياطية في حسابك.');
      return;
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر النسخة المستعادة من السحاب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: backups.length,
                itemBuilder: (context, index) {
                  final file = backups[index];
                  return ListTile(
                    leading: const Icon(Icons.description_rounded, color: Colors.blue),
                    title: Text(file.name ?? 'نسخة غير معروفة'),
                    subtitle: Text('تاريخ الرفع: ${file.createdTime?.toLocal().toString().split('.')[0] ?? 'غير معروف'}'),
                    onTap: () async {
                      Get.back(); // إغلاق القائمة
                      _confirmCloudRestore(file, driveService);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCloudRestore(drive.File driveFile, GoogleDriveService driveService) async {
    final bool confirm = await Get.defaultDialog(
      title: 'تأكيد الاستعادة السحابية',
      middleText: 'استعادة هذه النسخة سيحذف كافة البيانات الحالية. هل أنت متأكد؟',
      textConfirm: 'نعم، ابدأ',
      textCancel: 'إلغاء',
      onConfirm: () => Get.back(result: true),
    ) ?? false;

    if (!confirm) return;

    Get.dialog(
      const Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 10),
          Text('جاري تحميل واستعادة البيانات...'),
        ],
      )),
      barrierDismissible: false,
    );

    try {
      final dbPath = await getDatabasesPath();
      final targetPath = p.join(dbPath, 'ehab_company.db_temp');
      
      // 1. تحميل الملف
      final downloadedFile = await driveService.downloadBackup(driveFile.id!, targetPath);
      
      if (downloadedFile != null) {
        // 2. استدعاء منطق الاستبدال من BackupService
        await Get.find<BackupService>().restoreBackupFromFile(downloadedFile.path);
      } else {
        Get.back();
        Get.snackbar('خطأ', 'فشل تحميل الملف من السحاب');
      }
    } catch (e) {
      if (Get.isDialogOpen!) Get.back();
      Get.snackbar('خطأ', 'فشل عملية الاستعادة السحابية: $e');
    }
  }

  Widget _buildWarningSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: const Row(
        children: [
          Icon(Icons.report_problem_rounded, color: Colors.red),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'تنبيه: استعادة نسخة احتياطية (سواء محلية أو سحابية) سيؤدي إلى مسح جميع البيانات الحالية واستبدالها بالنسخة القديمة.',
              style: TextStyle(fontSize: 11, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
