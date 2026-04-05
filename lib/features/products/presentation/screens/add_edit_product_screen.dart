// File: lib/features/products/presentation/screens/add_edit_product_screen.dart

import 'dart:io';
import 'package:ehab_company_admin/features/categories/presentation/controllers/category_controller.dart';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:ehab_company_admin/features/units/presentation/controllers/unit_controller.dart'; // <-- إضافة جديدة
import 'package:ehab_company_admin/features/units/presentation/screens/units_screen.dart'; // <-- إضافة جديدة
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int? _selectedUnitId;
  final Map<int, TextEditingController> _smartQuantityControllers = {};
  final Set<int> _allowedUnitIds = {}; // تتبع الوحدات المسموح بالبيع بها
  bool _isSyncing = false;
  bool _isSalesStopped = false; // <-- إضافة
  final ImagePicker _picker = ImagePicker();

  // --- GetX Controllers ---
  final ProductController _productController = Get.find<ProductController>();
  final CategoryController _categoryController = Get.find<CategoryController>();
  final UnitController _unitController =
      Get.find<UnitController>(); // <-- جلب كنترولر الوحدات

  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.product != null;

    // إضافة مستمعات لتحديث واجهة الأسعار الهيكلية عند الكتابة
    _purchasePriceController.addListener(() => setState(() {}));
    _salePriceController.addListener(() => setState(() {}));
    _quantityController.addListener(() => setState(() {}));

    // التأكد من جلب البيانات عند فتح الشاشة
    _categoryController.fetchAllCategories();
    _unitController.fetchAllUnits().then((_) {
      // بعد جلب الوحدات، قم بضبط القيمة الافتراضية
      if (!_isEditMode && _unitController.units.isNotEmpty) {
        setState(() {
          _selectedUnitId = _unitController.units.first.id;
        });
      }

      // تهيئة الخانات الذكية إذا كان هناك وحدة مختارة
      if (_selectedUnitId != null) {
        _initializeSmartControllers();
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
      _selectedUnitId = widget.product!.unitId; // <-- تحديث
      _minStockLevelController.text = widget.product!.minStockLevel.toInt().toString();

      if (widget.product!.productionDate != null) {
        _productionDate = widget.product!.productionDate;
        _productionDateController.text = intl.DateFormat(
          'yyyy-MM-dd',
        ).format(_productionDate!);
      }
      if (widget.product!.expiryDate != null) {
        _expiryDate = widget.product!.expiryDate;
        _expiryDateController.text = intl.DateFormat(
          'yyyy-MM-dd',
        ).format(_expiryDate!);
      }
      if (widget.product!.allowedUnits != null) {
        _allowedUnitIds.clear();
        _allowedUnitIds.addAll(widget.product!.allowedUnits!);
      }

      if (widget.product!.imageUrl != null &&
          widget.product!.imageUrl!.isNotEmpty) {
        _selectedImage = File(widget.product!.imageUrl!);
      }
      _isSalesStopped = widget.product!.isSalesStopped; // <-- إضافة
      _initializeSmartControllers();
    } else {
      // القيم الافتراضية في وضع الإضافة
      _minStockLevelController.text = '0';
    }
  }

  void _initializeSmartControllers({bool keepOldAllowedUnits = false}) {
    if (_selectedUnitId == null) return;

    // تنظيف المتحكمات القديمة
    _smartQuantityControllers.forEach((_, ctrl) => ctrl.dispose());
    _smartQuantityControllers.clear();

    final levels = _unitController.getUnitLevels(_selectedUnitId!);
    final totalQty = double.tryParse(_quantityController.text) ?? 0.0;

    // تفعيل كل الوحدات افتراضياً عند تغيير السلسلة
    // إلا إذا طلبنا الاحتفاظ بالاختيارات القديمة (عند فتح المنتج للتعديل)
    if (!keepOldAllowedUnits) {
      _allowedUnitIds.clear();
      for (var level in levels) {
        _allowedUnitIds.add(level.id!);
      }
    }

    // تفكيك الكمية الإجمالية إلى (رئيسي + بواقي)
    // المستوى الأول هو الرئيسي، والباقي هم زوائد (Extras)
    double remaining = totalQty;
    for (int i = 0; i < levels.length; i++) {
      final level = levels[i];
      double val;
      if (i == 0) {
        val = remaining.floorToDouble();
        remaining = (remaining - val) * level.conversionFactor;
      } else if (i == levels.length - 1) {
        val = remaining;
      } else {
        val = remaining.floorToDouble();
        remaining = (remaining - val) * level.conversionFactor;
      }

      final ctrl = TextEditingController(
        text: val
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'\.00$'), '')
            .replaceAll(RegExp(r'\.0$'), ''),
      );
      _smartQuantityControllers[level.id!] = ctrl;

      // إضافة مستمع للتزامن الهرمي
      ctrl.addListener(() => _syncHierarchicalQuantities());
    }
    if (mounted) setState(() {});
  }

  void _syncHierarchicalQuantities() {
    if (_isSyncing || _selectedUnitId == null) return;
    _isSyncing = true;

    try {
      final levels = _unitController.getUnitLevels(_selectedUnitId!);

      // 1. تجميع القيم الحالية (من الأسفل للأعلى للترقية)
      Map<int, double> currentVals = {};
      for (var level in levels) {
        currentVals[level.id!] =
            double.tryParse(
              _smartQuantityControllers[level.id!]?.text ?? '0',
            ) ??
            0.0;
      }

      // حساب الإجمالي بوحدة "الوحدة الكبرى"
      double finalTotalMain = _unitController.recomposeTotal(
        _selectedUnitId!,
        currentVals,
      );
      _quantityController.text = finalTotalMain.toString();

      // 2. الترقية التلقائية (Promotion Logic)
      // إذا وصلت الزوائد لنصاب الوحدة الأعلى، يتم ترفيعها
      double tempTotal = finalTotalMain;
      final normalizedBreakdown = _unitController.decomposeAmount(
        _selectedUnitId!,
        tempTotal,
      );

      // 3. تحديث الخانات فقط إذا لزم الأمر لمنع الـ Loop
      normalizedBreakdown.forEach((id, val) {
        final ctrl = _smartQuantityControllers[id];
        final newText = val
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'\.00$'), '')
            .replaceAll(RegExp(r'\.0$'), '');
        if (ctrl != null && ctrl.text != newText) {
          // تحديث النص دون إثارة المستمع (عبر إيقاف الـ isSyncing)
          ctrl.text = newText;
        }
      });
      // تحديث الواجهة لتفعيل/تعطيل الحقول التالية بناءً على المدخلات الحالية
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Sync Error: $e");
    } finally {
      _isSyncing = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _quantityController.dispose();
    _smartQuantityControllers.forEach((_, ctrl) => ctrl.dispose());
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
              final String code =
                  barcodes.first.rawValue ?? "خطأ في قراءة الكود";
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
              _getImage(
                ImageSource.camera,
              ); // استدعاء دالة الالتقاط من الكاميرا
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

  Future<void> _selectDate(
    BuildContext context, {
    required bool isProductionDate,
  }) async {
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
          final selectedDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          final formattedDate = intl.DateFormat(
            'yyyy-MM-dd',
          ).format(selectedDateTime);
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
          unitId: _selectedUnitId,
          productionDate: _productionDate,
          expiryDate: _expiryDate,
          imageUrl: _selectedImage?.path,
          minStockLevel: double.tryParse(_minStockLevelController.text) ?? 0.0,
          allowedUnits: _allowedUnitIds.toList(),
          isSalesStopped: _isSalesStopped,
        );
      } else {
        _productController.addNewProduct(
          name: _nameController.text,
          code: _codeController.text.isNotEmpty ? _codeController.text : null,
          quantity: double.tryParse(_quantityController.text) ?? 0.0,
          purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
          salePrice: double.tryParse(_salePriceController.text) ?? 0.0,
          category: _selectedCategory,
          unitId: _selectedUnitId,
          productionDate: _productionDate,
          expiryDate: _expiryDate,
          imageUrl: _selectedImage?.path,
          minStockLevel: double.tryParse(_minStockLevelController.text) ?? 0.0,
          allowedUnits: _allowedUnitIds.toList(),
          isSalesStopped: _isSalesStopped,
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
              _buildTextField(
                controller: _nameController,
                label: 'اسم المنتج',
                icon: Icons.shopping_bag_outlined,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              Obx(
                () => DropdownButtonFormField<String>(
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
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _salePriceController,
                      label: 'سعر البيع',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      isRequired: true,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _purchasePriceController,
                      label: 'التكلفة (شراء)',
                      icon: Icons.money_off,
                      keyboardType: TextInputType.number,
                      isRequired: true,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 1. اختيار الوحدة (عرض كامل)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() {
                          final unitIds = _unitController.units
                              .map((u) => u.id)
                              .toList();
                          if (_selectedUnitId != null &&
                              !unitIds.contains(_selectedUnitId)) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                _selectedUnitId = null;
                              });
                            });
                          }

                          return DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: _selectedUnitId,
                            items: _unitController.units.map((unit) {
                              final chainText = _unitController
                                  .getPackagingChain(unit.id);
                              return DropdownMenuItem<int>(
                                value: unit.id,
                                child: Text(
                                  chainText.replaceAll(' ⬅️ ', ' | '),
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedUnitId = value;
                                _initializeSmartControllers(
                                  keepOldAllowedUnits: false,
                                );
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'سلسلة الوحدة *',
                              prefixIcon: Icon(Icons.all_inbox_outlined),
                            ),
                            validator: (value) =>
                                value == null ? 'الرجاء اختيار وحدة' : null,
                          );
                        }),
                        TextButton.icon(
                          onPressed: () => UnitsScreen.showUnitDialog(
                            context,
                            _unitController,
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: const Text(
                            'إضافة وحدة جديدة؟',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // استدعاء نظام الإدخال الهيكلي الجديد في مكانه الصحيح
              _buildSmartQuantityFields(),
              const SizedBox(height: 24),
              _buildDateField(
                controller: _productionDateController,
                label: 'تاريخ الإنتاج (اختياري)',
                onTap: () => _selectDate(context, isProductionDate: true),
              ),
              const SizedBox(height: 16),
              _buildDateField(
                controller: _expiryDateController,
                label: 'تاريخ الانتهاء (اختياري)',
                onTap: () => _selectDate(context, isProductionDate: false),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _minStockLevelController,
                label: 'الحد الأدنى للتنبيه (إجمالي)',
                icon: Icons.notifications_active_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                isNumber: true,
              ),
              const SizedBox(height: 16),
              _buildSuspensionToggle(), // <-- إضافة الزر الجديد هنا
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: Icon(_isEditMode ? Icons.edit_outlined : Icons.save),
                label: Text(_isEditMode ? 'حفظ التعديلات' : 'حفظ المنتج'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                  ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _selectedImage == null
                ? Icon(
                    Icons.camera_alt_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 35,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildTextField(
                controller: _codeController,
                label: 'باركود (اختياري)',
                icon: Icons.qr_code,
                keyboardType: TextInputType.number,
                isRequired: false,
                isNumber: true,
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: _scanBarcode,
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: const Text('مسح بالكاميرا'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmartQuantityFields() {
    if (_selectedUnitId == null || _smartQuantityControllers.isEmpty) {
      return _buildTextField(
        controller: _quantityController,
        label: 'الكمية الإجمالية (تلقائي)',
        icon: Icons.format_list_numbered,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        enabled: false,
      );
    }

    final levels = _unitController.getUnitLevels(_selectedUnitId!);
    final theme = Theme.of(context);

    // حساب الإجمالي لكل مستوى للمعلومات
    final totalQty = double.tryParse(_quantityController.text) ?? 0.0;
    final mainSalePrice = double.tryParse(_salePriceController.text) ?? 0.0;
    final mainPurchasePrice =
        double.tryParse(_purchasePriceController.text) ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.layers_outlined,
                  size: 20,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'توزيع الكميات والأسعار الهيكلي',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: levels.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final level = levels[index];
              final isMain = index == 0;
              final ctrl = _smartQuantityControllers[level.id!];

              // حساب المعامل العكسي للسعر: السعر الإجمالي / المعامل
              double priceDivisor = 1.0;
              for (int k = 0; k < index; k++) {
                priceDivisor *= levels[k].conversionFactor;
              }
              final levelSalePrice = mainSalePrice / priceDivisor;
              final levelPurchasePrice = mainPurchasePrice / priceDivisor;

              // حساب المعادل الإجمالي للكمية
              final equivalentTotal = totalQty * priceDivisor;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (!isMain)
                                Text(
                                  'الإجمالي: ${equivalentTotal.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            controller: ctrl!,
                            label: isMain ? 'الكمية' : 'زائد (+)',
                            icon: isMain
                                ? Icons.inventory_2_outlined
                                : Icons.add_box_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            isNumber: true,
                            isRequired: isMain,
                            enabled:
                                isMain ||
                                (_smartQuantityControllers[levels[index - 1]
                                            .id!]
                                        ?.text
                                        .isNotEmpty ??
                                    false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // تفاصيل السعر وخيار البيع
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              runSpacing: 8,
                              spacing: 8,
                              children: [
                                _buildPriceItem(
                                  icon: Icons.sell_outlined,
                                  label: 'بيع: ',
                                  value: levelSalePrice,
                                  color: Colors.green.shade700,
                                ),
                                _buildPriceItem(
                                  icon: Icons.shopping_cart_outlined,
                                  label: 'شراء: ',
                                  value: levelPurchasePrice,
                                  color: Colors.orange.shade700,
                                ),
                                _buildPriceItem(
                                  icon: Icons.monetization_on_outlined,
                                  label: 'ربح: ',
                                  value: (levelSalePrice - levelPurchasePrice),
                                  color: Colors.blue.shade700,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // خيار "مسموح بالبيع"
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (_allowedUnitIds.contains(level.id)) {
                                _allowedUnitIds.remove(level.id);
                              } else {
                                _allowedUnitIds.add(level.id!);
                              }
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'بيع؟',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Checkbox(
                                value: _allowedUnitIds.contains(level.id),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _allowedUnitIds.add(level.id!);
                                    } else {
                                      _allowedUnitIds.remove(level.id);
                                    }
                                  });
                                },
                                activeColor: theme.primaryColor,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    bool isNumber = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
  }) {
    return TextFormField(
      enabled: enabled,
      textDirection: isNumber ? TextDirection.ltr : TextDirection.rtl,
      controller: controller,
      onTap: () {
        if (isNumber) {
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        }
      },

      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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

  Widget _buildSuspensionToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _isSalesStopped ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSalesStopped ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          _isSalesStopped ? 'تم إيقاف بيع هذا المنتج' : 'المنتج متاح للبيع',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _isSalesStopped ? Colors.red.shade900 : Colors.green.shade900,
          ),
        ),
        subtitle: const Text('عند الإيقاف، لن يظهر المنتج في شاشة المبيعات ولن يتمكن الموظفون من بيعه.'),
        secondary: Icon(
          _isSalesStopped ? Icons.block : Icons.check_circle_outline,
          color: _isSalesStopped ? Colors.red : Colors.green,
        ),
        value: _isSalesStopped,
        onChanged: (val) {
          setState(() {
            _isSalesStopped = val;
          });
        },
      ),
    );
  }

  Widget _buildPriceItem({
    required IconData icon,
    required String label,
    required double value,
    required Color color,
  }) {
    // تنسيق الأرقام: حذف .00 إذا كان الرقم صحيحاً لتوفير مساحة
    final String formattedValue = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$label$formattedValue',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
