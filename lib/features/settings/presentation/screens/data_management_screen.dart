import 'package:ehab_company_admin/core/services/backup_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DataManagementScreen extends StatelessWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // حقن الخدمة
    final BackupService backupService = Get.put(BackupService());

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة البيانات')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.settings_backup_restore_rounded,
                size: 100,
                color: Colors.teal,
              ),
              const SizedBox(height: 30),
              _buildActionButton(
                context,
                icon: Icons.upload_file,
                label: 'إنشاء نسخة احتياطية',
                color: Colors.blue.shade700,
                onPressed: () => backupService.createBackup(),
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                context,
                icon: Icons.download_for_offline_outlined,
                label: 'استعادة نسخة احتياطية',
                color: Colors.orange.shade800,
                onPressed: () => backupService.restoreBackup(),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'تنبيه: استعادة نسخة احتياطية سيؤدي إلى مسح جميع البيانات الحالية واستبدالها.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
