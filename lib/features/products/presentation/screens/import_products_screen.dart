// File: lib/features/products/presentation/screens/import_products_screen.dart

import 'dart:io';
import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImportProductsScreen extends StatefulWidget {
  const ImportProductsScreen({super.key});

  @override
  State<ImportProductsScreen> createState() => _ImportProductsScreenState();
}

class _ImportProductsScreenState extends State<ImportProductsScreen> {
  final ProductController _productController = Get.find();
  File? _selectedFile;

  /// دالة لاختيار ملف اكسل من الجهاز
  Future<void> _pickExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'], // السماح فقط بملفات اكسل الحديثة
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    } else {
      // المستخدم ألغى عملية الاختيار
      Get.snackbar('تم الإلغاء', 'لم يتم اختيار أي ملف.');
    }
  }

  /// دالة لبدء عملية الاستيراد
  void _startImport() {
    if (_selectedFile == null) {
      Get.snackbar('خطأ', 'الرجاء اختيار ملف Excel أولاً.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    // استدعاء الدالة من الكنترولر
    _productController.importProducts(_selectedFile!.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استيراد المنتجات من Excel'),
      ),
      body: SafeArea(
        child: Obx(() {
          // عرض شاشة تحميل أثناء عملية الاستيراد
          if (_productController.isImporting.isTrue) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('جاري استيراد البيانات...', style: TextStyle(fontSize: 16)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'قد تستغرق هذه العملية عدة دقائق حسب حجم الملف.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }
        
          // الواجهة الرئيسية
          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // قسم التعليمات وزر تنزيل القالب
              _buildInstructionsCard(context),
        
              const SizedBox(height: 32),
        
              // زر اختيار الملف
              OutlinedButton.icon(
                onPressed: _pickExcelFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('1. اختيار ملف Excel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
        
              // عرض معلومات الملف المختار
              if (_selectedFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Card(
                    color: Colors.green.shade50,
                    child: ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green.shade700),
                      title: const Text(
                        'تم اختيار الملف بنجاح',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _selectedFile!.path.split(Platform.pathSeparator).last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
        
              const SizedBox(height: 16),
        
              // زر بدء الاستيراد
              ElevatedButton.icon(
                // تعطيل الزر إذا لم يتم اختيار ملف
                onPressed: _selectedFile == null ? null : _startImport,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('2. بدء عملية الاستيراد'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// ودجت جديد لعرض التعليمات وزر تنزيل القالب
  Widget _buildInstructionsCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تعليمات هامة قبل الاستيراد',
              style: textTheme.titleLarge?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            RichText(
              text: TextSpan(
                style: textTheme.bodyLarge?.copyWith(height: 1.5),
                children: [
                  const TextSpan(text: '1. تأكد من أن قيم أعمدة '),
                  TextSpan(
                    text: 'category (القسم)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' و '),
                  TextSpan(
                    text: 'unit (الوحدة)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' في ملف الإكسل موجودة بالفعل داخل التطبيق. '),
                  TextSpan(
                    text: 'أي قسم أو وحدة غير معرفة مسبقًا في التطبيق ستسبب خطأ.',
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // --- بداية الإضافة: تنبيه تنسيق التاريخ ---
            RichText(
              text: TextSpan(
                  style: textTheme.bodyLarge?.copyWith(height: 1.5),
                  children: [
                    const TextSpan(text: '2. يجب أن يكون تنسيق التاريخ في أعمدة '),
                    TextSpan(
                      text: 'productionDate',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                    const TextSpan(text: ' و '),
                    TextSpan(
                      text: 'expiryDate',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                    const TextSpan(text: ' مطابقاً للصيغة الدولية (YYYY-MM-DD). مثال: '),
                    TextSpan(
                      text: '2025-12-31',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Colors.blue),
                    )
                  ]
              ),
            ),
            // --- نهاية الإضافة ---
            const SizedBox(height: 8),
            const Text('3. تأكد من أن الملف بصيغة (.xlsx).'),
            const SizedBox(height: 8),
            const Text('4. يجب أن يحتوي الصف الأول على رؤوس الأعمدة (سيتم تجاهله).'),
            const SizedBox(height: 8),
            const Text('5. يجب أن تكون الأعمدة بالترتيب التالي:'),
            const Padding(
              padding: EdgeInsets.only(top: 8.0, right: 16.0),
              child: Text(
                // --- بداية التعديل: تحديث قائمة الأعمدة ---
                'A: name (إجباري)\n'
                    'B: code\n'
                    'C: quantity\n'
                    'D: purchasePrice\n'
                    'E: salePrice\n'
                    'F: category\n'
                    'G: unit\n'
                    'H: minStockLevel\n'
                    'I: productionDate (مثال: 2025-05-20)\n'
                    'J: expiryDate (مثال: 2026-05-20)',
                // --- نهاية التعديل ---
                style: TextStyle(fontFamily: 'monospace', height: 1.5, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: () => _productController.downloadTemplate(),
                icon: const Icon(Icons.download_for_offline_rounded),
                label: const Text('تنزيل قالب Excel جاهز'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
