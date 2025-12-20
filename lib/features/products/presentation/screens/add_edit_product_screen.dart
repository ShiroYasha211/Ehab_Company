// File: lib/features/products/presentation/screens/add_edit_product_screen.dart

import 'dart:io';
import 'package:ehab_company_admin/features/categories/presentation/controllers/category_controller.dart';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:ehab_company_admin/features/units/presentation/controllers/unit_controller.dart'; // <-- إضافة جديدة
import 'package:ehab_company_admin/features/units/presentation/screens/units_screen.dart'; // <-- إضافة جديدة
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:mobile_scanner/mobile_scanner.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Text Editing Controllers ---
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _productionDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _minStockLevelController = TextEditingController();

  // --- State Variables ---
  DateTime? _productionDate;
  DateTime? _expiryDate;
  File? _selectedImage;
  String? _selectedCategory;
  String? _selectedUnit; // <-- متغير جديد للوحدة المختارة
  final ImagePicker _picker = ImagePicker();

  // --- GetX Controllers ---
  final ProductController _productController = Get.find<ProductController>();
  final CategoryController _categoryController = Get.find<CategoryController>();
  final UnitController _unitController = Get.find<UnitController>(); // <-- جلب كنترولر الوحدات

  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.product != null;

    // التأكد من جلب البيانات عند فتح الشاشة
    _categoryController.fetchAllCategories();
    _unitController.fetchAllUnits().then((_) {
      // بعد جلب الوحدات، قم بضبط القيمة الافتراضية
      if (!_isEditMode && _unitController.units.isNotEmpty) {
        setState(() {
          _selectedUnit = _unitController.units.first.name;
        });
      }
    });

    if (_isEditMode) {
      // ملء الحقول في وضع التعديل
      _nameController.text = widget.product!.name;
      _codeController.text = widget.product!.code ?? '';
      _quantityController.text = widget.product!.quantity.toString();
      _purchasePriceController.text = widget.product!.purchasePrice.toString();
      _salePriceController.text = widget.product!.salePrice.toString();
      _selectedCategory = widget.product!.category;
      _selectedUnit = widget.product!.unit; // <-- تحديث
      _minStockLevelController.text = widget.product!.minStockLevel.toString();

      if (widget.product!.productionDate != null) {
        _productionDate = widget.product!.productionDate;
        _productionDateController.text = intl.DateFormat('yyyy-MM-dd').format(_productionDate!);
      }
      if (widget.product!.expiryDate != null) {
        _expiryDate = widget.product!.expiryDate;
        _expiryDateController.text = intl.DateFormat('yyyy-MM-dd').format(_expiryDate!);
      }
      if (widget.product!.imageUrl != null && widget.product!.imageUrl!.isNotEmpty) {
        _selectedImage = File(widget.product!.imageUrl!);
      }
    } else {
      // القيم الافتراضية في وضع الإضافة
      _minStockLevelController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _quantityController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _productionDateController.dispose();
    _expiryDateController.dispose();
    _minStockLevelController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    await Get.dialog(
      Scaffold(
        appBar: AppBar(title: const Text('امسح الباركود')),
        body: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String code = barcodes.first.rawValue ?? "خطأ في قراءة الكود";
              _codeController.text = code;
              Get.back();
            }
          },
        ),
      ),
    );
  }

  // --- 1. بداية التعديل: تحديث دالة اختيار الصورة ---
  Future<void> _pickImage() async {
    // عرض ديالوج أو BottomSheet للاختيار
    await Get.dialog(
      SimpleDialog(
        title: const Text('اختيار مصدر الصورة'),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: () {
              Get.back(); // إغلاق الديالوج
              _getImage(ImageSource.camera); // استدعاء دالة الالتقاط من الكاميرا
            },
            padding: const EdgeInsets.all(20),
            child: const Row(
              children: [
                Icon(Icons.camera_alt_outlined),
                SizedBox(width: 16),
                Text('التقاط صورة بالكاميرا'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Get.back(); // إغلاق الديالوج
              _getImage(ImageSource.gallery); // استدعاء دالة الاختيار من المعرض
            },
            padding: const EdgeInsets.all(20),
            child: const Row(
              children: [
                Icon(Icons.photo_library_outlined),
                SizedBox(width: 16),
                Text('اختيار صورة من المعرض'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. بداية الإضافة: دالة مساعدة جديدة لجلب الصورة ---
  Future<void> _getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }
  // --- نهاية الإضافة ---


  Future<void> _selectDate(BuildContext context, {required bool isProductionDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ar'),
    );

    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          final selectedDateTime = DateTime(picked.year, picked.month, picked.day, pickedTime.hour, pickedTime.minute);
          final formattedDate = intl.DateFormat('yyyy-MM-dd').format(selectedDateTime);
          if (isProductionDate) {
            _productionDate = selectedDateTime;
            _productionDateController.text = formattedDate;
          } else {
            _expiryDate = selectedDateTime;
            _expiryDateController.text = formattedDate;
          }
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_isEditMode) {
        _productController.updateProduct(
          id: widget.product!.id!,
          createdAt: widget.product!.createdAt,
          name: _nameController.text,
          code: _codeController.text.isNotEmpty ? _codeController.text : null,
          quantity: double.tryParse(_quantityController.text) ?? 0.0,
          purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
          salePrice: double.tryParse(_salePriceController.text) ?? 0.0,
          category: _selectedCategory,
          unit: _selectedUnit, // <-- تحديث
          productionDate: _productionDate,
          expiryDate: _expiryDate,
          imageUrl: _selectedImage?.path,
          minStockLevel: double.tryParse(_minStockLevelController.text) ?? 0.0,
        );
      } else {
        _productController.addNewProduct(
          name: _nameController.text,
          code: _codeController.text.isNotEmpty ? _codeController.text : null,
          quantity: double.tryParse(_quantityController.text) ?? 0.0,
          purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
          salePrice: double.tryParse(_salePriceController.text) ?? 0.0,
          category: _selectedCategory,
          unit: _selectedUnit, // <-- تحديث
          productionDate: _productionDate,
          expiryDate: _expiryDate,
          imageUrl: _selectedImage?.path,
          minStockLevel: double.tryParse(_minStockLevelController.text) ?? 0.0,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'تعديل المنتج' : 'إضافة منتج جديد'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              _buildImageAndBarcodeField(),
              const SizedBox(height: 16),
              _buildTextField(controller: _nameController, label: 'اسم المنتج', icon: Icons.shopping_bag_outlined, isRequired: true),
              const SizedBox(height: 16),
              Obx(() => DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categoryController.categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat.name,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'القسم',
                  prefixIcon: Icon(Icons.folder_open_outlined),
                ),
                hint: const Text('اختر قسمًا'),
              )),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(controller: _salePriceController, label: 'سعر البيع', icon: Icons.attach_money, keyboardType: TextInputType.number, isRequired: true,isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(controller: _purchasePriceController, label: 'التكلفة (شراء)', icon: Icons.money_off, keyboardType: TextInputType.number, isRequired: true, isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // --- بداية التعديل: حقل الوحدة ---
                  Expanded(
                    flex: 3,
                    child: Obx(() => DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      items: _unitController.units.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit.name,
                          child: Text(unit.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'الوحدة *',
                        prefixIcon: Icon(Icons.all_inbox_outlined),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'الرجاء اختيار وحدة' : null,
                    )),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Theme.of(context).primaryColor),
                    onPressed: () async {
                      await Get.to(() => const UnitsScreen());
                      // تحديث قائمة الوحدات بعد العودة من شاشة الإدارة
                      _unitController.fetchAllUnits();
                    },
                    tooltip: 'إدارة الوحدات',
                  ),
                  // --- نهاية التعديل ---
                  const SizedBox(width: 1),
                  Expanded(flex: 2, child: _buildTextField(controller: _quantityController, label: 'الكمية', icon: Icons.format_list_numbered, keyboardType: TextInputType.number, isRequired: true, isNumber: true)),
                ],
              ),
              const SizedBox(height: 24),
              _buildDateField(controller: _productionDateController, label: 'تاريخ الإنتاج (اختياري)', onTap: () => _selectDate(context, isProductionDate: true)),
              const SizedBox(height: 16),
              _buildDateField(controller: _expiryDateController, label: 'تاريخ الانتهاء (اختياري)', onTap: () => _selectDate(context, isProductionDate: false)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: Icon(_isEditMode ? Icons.edit_outlined : Icons.save),
                label: Text(_isEditMode ? 'حفظ التعديلات' : 'حفظ المنتج'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageAndBarcodeField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              image: _selectedImage != null
                  ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                  : null,
            ),
            child: _selectedImage == null
                ? Icon(Icons.camera_alt_outlined, color: Theme.of(context).primaryColor, size: 35)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildTextField(
                controller: _codeController,
                label: 'باركود',
                icon: Icons.qr_code,
                keyboardType: TextInputType.number,
                isRequired: true,
                isNumber: true,
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: _scanBarcode,
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: const Text('مسح بالكاميرا'),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    bool isNumber = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      textDirection: isNumber? TextDirection.ltr : TextDirection.rtl,
      controller: controller,

      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon, size: 22),

      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 22),
      ),
    );
  }
}
