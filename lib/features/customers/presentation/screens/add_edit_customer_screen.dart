// File: lib/features/customers/presentation/screens/add_edit_customer_screen.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final CustomerModel? customer; // لاستخدامه في وضع التعديل

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditMode;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController(); // حقل إضافي للعميل
  final _notesController = TextEditingController();

  final CustomerController _customerController = Get.find<CustomerController>();

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.customer != null;

    if (_isEditMode) {
      // ملء الحقول في وضع التعديل
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone ?? '';
      _addressController.text = widget.customer!.address ?? '';
      _companyController.text = widget.customer!.company ?? '';
      _emailController.text = widget.customer!.email ?? '';
      _notesController.text = widget.customer!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_isEditMode) {
        _customerController.updateCustomer(
          id: widget.customer!.id!,
          createdAt: widget.customer!.createdAt, // تمرير البيانات القديمة
          balance: widget.customer!.balance, // تمرير البيانات القديمة
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          company: _companyController.text,
          email: _emailController.text,
          notes: _notesController.text,
        );
      } else {
        _customerController.addCustomer(
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          company: _companyController.text,
          email: _emailController.text,
          notes: _notesController.text,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'تعديل بيانات العميل' : 'إضافة عميل جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTextField(
                controller: _nameController,
                label: 'اسم العميل',
                icon: Icons.person,
                isRequired: true),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _phoneController,
                label: 'رقم الهاتف',
                icon: Icons.phone,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _companyController,
                label: 'الشركة (اختياري)',
                icon: Icons.business),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _addressController,
                label: 'العنوان (اختياري)',
                icon: Icons.location_on_outlined),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _emailController,
                label: 'البريد الإلكتروني (اختياري)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _notesController,
                label: 'ملاحظات',
                icon: Icons.notes,
                maxLines: 3),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _submitForm,
              icon: Icon(_isEditMode
                  ? Icons.edit_outlined
                  : Icons.save_alt_outlined),
              label: Text(_isEditMode ? 'حفظ التعديلات' : 'حفظ العميل'),
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
        alignLabelWithHint: true,
        border: const OutlineInputBorder(), // إضافة حدود للحقول
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
