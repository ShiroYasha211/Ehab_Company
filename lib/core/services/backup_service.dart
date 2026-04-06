import 'dart:io';

import 'package:ehab_company_admin/core/database/database_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BackupService extends GetxService {
  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 30) {
        // Android 11+
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
        return status.isGranted;
      } else {
        // Android < 11
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
    }
    return true;
  }

  Future<void> createBackup() async {
    try {
      // طلب الصلاحيات
      if (!await _requestPermission()) {
        Get.snackbar(
          'تصريح مرفوض',
          'يجب منح صلاحية الوصول للملفات لإتمام النسخ الاحتياطي.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, 'ehab_company.db');
      final File dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        Get.snackbar('خطأ', 'لم يتم العثور على ملف قاعدة البيانات.');
        return;
      }

      // اختيار مجلد الحفظ
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        // المستخدم ألغى العملية
        return;
      }

      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final backupFileName = 'backup_ehab_company_$timestamp.db';
      final backupPath = join(selectedDirectory, backupFileName);

      await dbFile.copy(backupPath);

      Get.snackbar(
        'تم بنجاح',
        'تم إنشاء النسخة الاحتياطية بنجاح:\n$backupFileName',
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء إنشاء النسخة الاحتياطية: $e');
      print('Backup Error: $e');
    }
  }

  Future<void> restoreBackup() async {
    try {
      // طلب الصلاحيات
      if (!await _requestPermission()) {
        Get.snackbar(
          'تصريح مرفوض',
          'يجب منح صلاحية الوصول للملفات لاستعادة النسخة.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // اختيار ملف النسخة الاحتياطية
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'اختر ملف النسخة الاحتياطية (.db)',
        type: FileType.any, // Android limitations mainly, deskop is fine
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final String selectedPath = result.files.single.path!;

      if (!selectedPath.endsWith('.db')) {
        Get.snackbar('خطأ', 'الرجاء اختيار ملف قاعدة بيانات صالح (.db)');
        return;
      }

      // تأكيد الاستعادة
      final bool confirm =
          await Get.defaultDialog(
            title: 'تنبيه هام جداً',
            middleText:
                'استعادة النسخة الاحتياطية سيقوم بحذف جميع البيانات الحالية واستبدالها بالبيانات الموجودة في الملف المختار.\n\nهل أنت متأكد من المتابعة؟',
            textConfirm: 'نعم، استعادة',
            textCancel: 'إلغاء',
            confirmTextColor: Get.theme.canvasColor,
            buttonColor: Get.theme.primaryColor,
            onConfirm: () => Get.back(result: true),
            onCancel: () => Get.back(result: false),
          ) ??
          false;

      if (!confirm) return;

      // إغلاق الاتصال بقاعدة البيانات الحالية
      await DatabaseService().close();

      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, 'ehab_company.db');
      final File dbFile = File(dbPath);

      // نسخ الملف المختار فوق قاعدة البيانات الحالية
      final File backupFile = File(selectedPath);
      await backupFile.copy(dbPath);

      // إعادة التشغيل أو إشعار المستخدم
      Get.defaultDialog(
        title: 'تمت الاستعادة بنجاح',
        middleText: 'يجب إعادة تشغيل التطبيق لتطبيق التغييرات بشكل صحيح.',
        textConfirm: 'حسناً',
        confirmTextColor: Get.theme.canvasColor,
        buttonColor: Get.theme.primaryColor,
        onConfirm: () {
          // في تطبيقات فلاتر، إعادة التشغيل الكاملة صعبة برمجياً
          // لذا سنطلب من المستخدم إغلاق التطبيق يدوياً أو نعيده للشاشة الرئيسية
          Get.offAllNamed('/'); // العودة للشاشة الرئيسية كحل مؤقت
        },
        barrierDismissible: false,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء استعادة النسخة الاحتياطية: $e');
      print('Restore Error: $e');
    }
  }

  /// استعادة قاعدة البيانات من ملف محدد (يستخدم برمجياً، مثلاً عند التحميل من السحاب)
  Future<void> restoreBackupFromFile(String filePath) async {
    try {
      // إغلاق الاتصال بقاعدة البيانات الحالية
      await DatabaseService().close();

      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, 'ehab_company.db');

      // استبدال الملف الحالي بالملف الجديد
      final File backupFile = File(filePath);
      await backupFile.copy(dbPath);

      // إشعار المستخدم بالنجاح
      if (Get.isDialogOpen!) Get.back(); // إغلاق "جاري التحميل" إذا كان مفتوحاً
      
      Get.defaultDialog(
        title: 'تمت الاستعادة بنجاح',
        middleText: 'تمت استعادة النسخة الاحتياطية بنجاح. يجب إعادة تشغيل التطبيق.',
        textConfirm: 'حسناً',
        onConfirm: () => Get.offAllNamed('/'),
        barrierDismissible: false,
      );
    } catch (e) {
      if (Get.isDialogOpen!) Get.back();
      Get.snackbar('خطأ', 'فشل في استبدال قاعدة البيانات: $e');
    }
  }
}
