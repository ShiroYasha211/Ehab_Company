// File: lib/features/products/presentation/screens/bulk_price_editor_screen.dart

import 'package:ehab_company_admin/features/categories/presentation/controllers/category_controller.dart';
import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BulkPriceEditorScreen extends StatefulWidget {
  const BulkPriceEditorScreen({super.key});

  @override
  State<BulkPriceEditorScreen> createState() => _BulkPriceEditorScreenState();
}

class _BulkPriceEditorScreenState extends State<BulkPriceEditorScreen> {
  // GetX Controllers
  final ProductController _productController = Get.find<ProductController>();
  final CategoryController _categoryController = Get.find<CategoryController>();

  // State Variables for UI
  String _scope = 'all'; // 'all' or 'category'
  String? _selectedCategory;
  String _targetPrice = 'salePrice'; // 'salePrice' or 'purchasePrice'
  String _operationType = '+'; // '+' or '-'
  String _calculationMethod = 'amount'; // 'amount', 'percentage', 'currency'

  // Text Editing Controllers for inputs
  final _value1Controller = TextEditingController();
  final _value2Controller = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _value1Controller.dispose();
    _value2Controller.dispose();
    super.dispose();
  }

  void _applyChanges() {
    if (_formKey.currentState!.validate()) {
      Get.defaultDialog(
        title: '⚠️ تأكيد الإجراء',
        middleText:
        'أنت على وشك تحديث أسعار مجموعة من المنتجات. هذا الإجراء نهائي ولا يمكن التراجع عنه بسهولة. هل أنت متأكد من المتابعة؟',
        textConfirm: 'نعم، قم بالتطبيق',
        textCancel: 'إلغاء',
        confirmTextColor: Colors.white,
        onConfirm: () {
          Get.back(); // Close confirmation dialog
          // Call the controller to perform the update
          _productController.applyBulkPriceUpdate(
            scope: _scope,
            category: _selectedCategory,
            targetPriceField: _targetPrice,
            operationType: _operationType,
            calculationMethod: _calculationMethod,
            value1: double.tryParse(_value1Controller.text) ?? 0.0,
            value2: double.tryParse(_value2Controller.text),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الأسعار الشامل'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('1. تحديد نطاق المنتجات'),
              _buildScopeSelector(),
              if (_scope == 'category') _buildCategorySelector(),
              const SizedBox(height: 24),
              _buildSectionTitle('2. تحديد السعر المستهدف ونوع العملية'),
              _buildTargetPriceSelector(),
              if (_calculationMethod != 'currency') _buildOperationTypeSelector(),
              const SizedBox(height: 24),
              _buildSectionTitle('3. تحديد طريقة وقيمة الحساب'),
              _buildCalculationMethodSelector(),
              const SizedBox(height: 16),
              _buildValueInputFields(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _applyChanges,
                  icon: const Icon(Icons.published_with_changes),
                  label: const Text('تطبيق التغييرات'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets for building the UI ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildScopeSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'all', label: Text('كل المنتجات'), icon: Icon(Icons.select_all)),
        ButtonSegment(value: 'category', label: Text('قسم معين'), icon: Icon(Icons.folder_open)),
      ],
      selected: {_scope},
      onSelectionChanged: (newSelection) {
        setState(() {
          _scope = newSelection.first;
        });
      },
    );
  }

  Widget _buildCategorySelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Obx(() => DropdownButtonFormField<String>(
        value: _selectedCategory,
        items: _categoryController.categories.map((cat) {
          return DropdownMenuItem<String>(value: cat.name, child: Text(cat.name));
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategory = value;
          });
        },
        decoration: const InputDecoration(labelText: 'اختر القسم', border: OutlineInputBorder()),
        validator: (value) => value == null ? 'يجب اختيار قسم' : null,
      )),
    );
  }

  Widget _buildTargetPriceSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'salePrice', label: Text('سعر البيع')),
        ButtonSegment(value: 'purchasePrice', label: Text('سعر الشراء')),
      ],
      selected: {_targetPrice},
      onSelectionChanged: (newSelection) {
        setState(() {
          _targetPrice = newSelection.first;
        });
      },
    );
  }

  Widget _buildOperationTypeSelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: SegmentedButton<String>(
        style: SegmentedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        segments: const [
          ButtonSegment(value: '+', label: Text('زيادة'), icon: Icon(Icons.add)),
          ButtonSegment(value: '-', label: Text('نقصان'), icon: Icon(Icons.remove)),
        ],
        selected: {_operationType},
        onSelectionChanged: (newSelection) {
          setState(() {
            _operationType = newSelection.first;
          });
        },
      ),
    );
  }

  Widget _buildCalculationMethodSelector() {
    return DropdownButtonFormField<String>(
      value: _calculationMethod,
      items: const [
        DropdownMenuItem(value: 'amount', child: Text('مبلغ ثابت')),
        DropdownMenuItem(value: 'percentage', child: Text('نسبة مئوية (%)')),
        DropdownMenuItem(value: 'currency', child: Text('فارق سعر الصرف')),
      ],
      onChanged: (value) {
        setState(() {
          _calculationMethod = value!;
          _value1Controller.clear();
          _value2Controller.clear();
        });
      },
      decoration: const InputDecoration(labelText: 'طريقة الحساب', border: OutlineInputBorder()),
    );
  }

  Widget _buildValueInputFields() {
    switch (_calculationMethod) {
      case 'amount':
        return TextFormField(
          controller: _value1Controller,
          decoration: const InputDecoration(labelText: 'أدخل المبلغ', prefixIcon: Icon(Icons.attach_money)),
          keyboardType: TextInputType.number,
          validator: (value) => (value == null || value.isEmpty) ? 'هذا الحقل مطلوب' : null,
        );
      case 'percentage':
        return TextFormField(
          controller: _value1Controller,
          decoration: const InputDecoration(labelText: 'أدخل النسبة المئوية', prefixIcon: Icon(Icons.percent)),
          keyboardType: TextInputType.number,
          validator: (value) => (value == null || value.isEmpty) ? 'هذا الحقل مطلوب' : null,
        );
      case 'currency':
        return Column(
          children: [
            TextFormField(
              controller: _value1Controller,
              decoration: const InputDecoration(labelText: 'سعر الصرف القديم', helperText: 'السعر الذي تم الشراء به'),
              keyboardType: TextInputType.number,
              validator: (value) => (value == null || value.isEmpty) ? 'هذا الحقل مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _value2Controller,
              decoration: const InputDecoration(labelText: 'سعر الصرف الجديد', helperText: 'السعر الحالي للصرف'),
              keyboardType: TextInputType.number,
              validator: (value) => (value == null || value.isEmpty) ? 'هذا الحقل مطلوب' : null,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
