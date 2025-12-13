// File: lib/features/suppliers/presentation/screens/add_edit_supplier_screen.dart

import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddEditSupplierScreen extends StatefulWidget {
  final SupplierModel? supplier; // لاستخدامه في وضع التعديل لاحقًا

  const AddEditSupplierScreen({super.key, this.supplier});

  @override
  State<AddEditSupplierScreen> createState() => _AddEditSupplierScreenState();
}

class _AddEditSupplierScreenState extends State<AddEditSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditMode;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _companyController = TextEditingController();
  final _recordController = TextEditingController();
  final _notesController = TextEditingController();

  final SupplierController _supplierController = Get.find<SupplierController>();

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.supplier != null;

    if (_isEditMode) {
      // ملء الحقول في وضع التعديل
      _nameController.text = widget.supplier!.name;
      _phoneController.text = widget.supplier!.phone ?? '';
      _addressController.text = widget.supplier!.address ?? '';
      _companyController.text = widget.supplier!.company ?? '';
      _recordController.text = widget.supplier!.commercialRecord ?? '';
      _notesController.text = widget.supplier!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _companyController.dispose();
    _recordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // يمكنك استخدام نفس الدالة للتعديل لاحقًا
      if (_isEditMode) {
        _supplierController.updateSupplier(
          id: widget.supplier!.id!,
          createdAt: widget.supplier!.createdAt, // تمرير البيانات القديمة التي لا تتغير
          balance: widget.supplier!.balance,   // تمرير البيانات القديمة التي لا تتغير
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          company: _companyController.text,
          commercialRecord: _recordController.text,
          notes: _notesController.text,
        );
      } else {
        _supplierController.addSupplier(
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          company: _companyController.text,
          commercialRecord: _recordController.text,
          notes: _notesController.text,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'تعديل بيانات المورد' : 'إضافة مورد جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTextField(controller: _nameController, label: 'اسم المورد', icon: Icons.person, isRequired: true),
            const SizedBox(height: 16),
            _buildTextField(controller: _phoneController, label: 'رقم الهاتف', icon: Icons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField(controller: _companyController, label: 'الشركة (اختياري)', icon: Icons.business),
            const SizedBox(height: 16),
            _buildTextField(controller: _addressController, label: 'العنوان (اختياري)', icon: Icons.location_on_outlined),
            const SizedBox(height: 16),
            _buildTextField(controller: _recordController, label: 'رقم السجل التجاري (اختياري)', icon: Icons.article_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(controller: _notesController, label: 'ملاحظات', icon: Icons.notes, maxLines: 3),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _submitForm,
              icon: Icon(_isEditMode ? Icons.edit_outlined : Icons.save_alt_outlined),
              label: Text(_isEditMode ? 'حفظ التعديلات' : 'حفظ المورد'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon),
        alignLabelWithHint: true, // مهم للحقول متعددة الأسطر
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
    );
  }
}
