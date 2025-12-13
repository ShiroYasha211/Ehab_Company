// File: lib/core/services/import_service.dart

import 'dart:io';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/data/repositories/product_repository.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';

class ImportService {
  final ProductRepository _productRepository = ProductRepository();

  // ... (دالة importProductsFromExcel تبقى كما هي)
  Future<Map<String, int>> importProductsFromExcel(String filePath) async {
    // ... الكود هنا لا يتغير
    int successCount = 0;
    int failureCount = 0;

    var bytes = File(filePath).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    var sheet = excel.tables.keys.first;
    var table = excel.tables[sheet]!;

    for (var i = 1; i < table.maxRows; i++) {
      var row = table.row(i);

      try {
        final String name = row[0]?.value?.toString() ?? '';
        final String? code = row[1]?.value?.toString();
        final double quantity = double.tryParse(row[2]?.value?.toString() ?? '0') ?? 0.0;
        final double purchasePrice = double.tryParse(row[3]?.value?.toString() ?? '0') ?? 0.0;
        final double salePrice = double.tryParse(row[4]?.value?.toString() ?? '0') ?? 0.0;
        final String? category = row[5]?.value?.toString();
        final String? unit = row[6]?.value?.toString();
        final double minStockLevel = double.tryParse(row[7]?.value?.toString() ?? '0') ?? 0.0;
        final String? prodDateString = row[8]?.value?.toString();
        final String? expDateString = row[9]?.value?.toString();
        final DateTime? productionDate = prodDateString != null ? DateTime.tryParse(prodDateString) : null;
        final DateTime? expiryDate = expDateString != null ? DateTime.tryParse(expDateString) : null;

        if (name.isEmpty) {
          failureCount++;
          continue;
        }

        final product = ProductModel(
          name: name,
          code: code,
          quantity: quantity,
          purchasePrice: purchasePrice,
          salePrice: salePrice,
          category: category,
          unit: unit,
          minStockLevel: minStockLevel,
          createdAt: DateTime.now(),
          productionDate: productionDate,
          expiryDate: expiryDate,
        );

        await _productRepository.addProduct(product);
        successCount++;
      } catch (e) {
        print('Failed to import row $i: $e');
        failureCount++;
      }
    }

    return {'success': successCount, 'failure': failureCount};
  }

  // --- بداية التعديلات ---
  Future<void> createExcelTemplate() async {

    // 2. إذا تم منح الإذن، استكمل باقي الكود كالمعتاد
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    List<String> headers = [
      'name', 'code', 'quantity', 'purchasePrice', 'salePrice',
      'category', 'unit', 'minStockLevel',
      'productionDate', 'expiryDate'
    ];
    sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

    List<dynamic> exampleRow = [
      'منتج تجريبي', '123456789', 100.0, 50.0, 75.0,
      'قسم رئيسي', 'قطعة', 10.0,
      '2025-01-20', '2026-01-20'
    ];
    sheetObject.appendRow(exampleRow.map((e) => TextCellValue(e.toString())).toList());

    final directory = await getTemporaryDirectory();
    final fileName = 'EhabCompany_Products_Template.xlsx';
    final filePath = '${directory.path}/$fileName';

    List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        throw Exception('لم يتم العثور على تطبيق لفتح ملفات Excel. الخطأ: ${result.message}');
      }
    } else {
      throw Exception('فشل في إنشاء ملف Excel.');
    }
  }
// --- نهاية التعديلات ---
}

