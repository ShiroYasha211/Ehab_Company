// File: lib/features/warehouses/presentation/screens/add_edit_warehouse_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/warehouse_model.dart';
import '../controllers/warehouse_controller.dart';

class AddEditWarehouseScreen extends StatefulWidget {
  final WarehouseModel? warehouse;

  const AddEditWarehouseScreen({super.key, this.warehouse});

  @override
  State<AddEditWarehouseScreen> createState() => _AddEditWarehouseScreenState();
}

class _AddEditWarehouseScreenState extends State<AddEditWarehouseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repNameController = TextEditingController();
  final _repPhoneController = TextEditingController();
  final _creditLimitController = TextEditingController(text: '0');

  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.warehouse != null;
    if (_isEditMode) {
      _repNameController.text = widget.warehouse!.salesRepName ?? '';
      _repPhoneController.text = widget.warehouse!.salesRepPhone ?? '';
      _creditLimitController.text = widget.warehouse!.creditLimit.toString();
    }
  }

  @override
  void dispose() {
    _repNameController.dispose();
    _repPhoneController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final controller = Get.find<WarehouseController>();

    final repName = _repNameController.text.trim();
    final warehouseName = 'عهدة: $repName';

    if (_isEditMode) {
      controller.updateWarehouse(widget.warehouse!.copyWith(
        name: warehouseName,
        salesRepName: repName,
        salesRepPhone: _repPhoneController.text.trim(),
        creditLimit: double.tryParse(_creditLimitController.text) ?? 0.0,
      ));
    } else {
      controller.addWarehouse(
        name: warehouseName,
        type: 'rep',
        salesRepName: repName,
        salesRepPhone: _repPhoneController.text.trim(),
        creditLimit: double.tryParse(_creditLimitController.text) ?? 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'تعديل المخزن الفرعي' : 'إنشاء مخزن فرعي جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // أيقونة توضيحية
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Column(
                children: [
                  Icon(Icons.local_shipping_rounded, size: 48, color: Colors.orange.shade700),
                  const SizedBox(height: 12),
                  const Text(
                    'مخزن فرعي لمندوب مبيعات',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'سيتم إنشاء مخزن مرتبط بالمندوب لتتبع العُهد والتسويات',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // اسم المندوب
            TextFormField(
              controller: _repNameController,
              decoration: const InputDecoration(
                labelText: 'اسم مندوب المبيعات *',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم المندوب' : null,
            ),
            const SizedBox(height: 16),

            // هاتف المندوب
            TextFormField(
              controller: _repPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف (اختياري)',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // حد الائتمان
            TextFormField(
              controller: _creditLimitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'حد الائتمان (اختياري)',
                prefixIcon: Icon(Icons.credit_score_outlined),
                border: OutlineInputBorder(),
                helperText: 'الحد الأقصى لقيمة العُهد المسموح صرفها للمندوب',
              ),
            ),
            const SizedBox(height: 32),

            // زر الحفظ
            ElevatedButton.icon(
              onPressed: _submit,
              icon: Icon(_isEditMode ? Icons.save : Icons.add_business),
              label: Text(_isEditMode ? 'حفظ التعديلات' : 'إنشاء المخزن'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
