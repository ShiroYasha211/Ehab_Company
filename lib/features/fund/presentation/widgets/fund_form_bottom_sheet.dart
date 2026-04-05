// File: lib/features/fund/presentation/widgets/fund_form_bottom_sheet.dart

import 'package:ehab_company_admin/core/theme/app_theme.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';
import 'package:ehab_company_admin/features/fund/presentation/controllers/fund_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FundFormBottomSheet extends StatefulWidget {
  final FundType fundType;
  final FundModel? fundToEdit;

  const FundFormBottomSheet({
    super.key,
    required this.fundType,
    this.fundToEdit,
  });

  @override
  State<FundFormBottomSheet> createState() => _FundFormBottomSheetState();
}

class _FundFormBottomSheetState extends State<FundFormBottomSheet> {
  final FundController controller = Get.find<FundController>();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _initialBalanceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fundToEdit?.name ?? '');
    _bankNameController = TextEditingController(text: widget.fundToEdit?.bankName ?? '');
    _accountNumberController = TextEditingController(text: widget.fundToEdit?.accountNumber ?? '');
    _initialBalanceController = TextEditingController(
      text: widget.fundToEdit?.initialBalance.toString() ?? '0.0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final String name = _nameController.text.trim();
      final double initialBalance = double.tryParse(_initialBalanceController.text) ?? 0.0;

      if (widget.fundToEdit != null) {
        final updatedFund = widget.fundToEdit!.copyWith(
          name: name,
          bankName: widget.fundType == FundType.cash ? null : _bankNameController.text.trim(),
          accountNumber: widget.fundType == FundType.cash ? null : _accountNumberController.text.trim(),
          initialBalance: initialBalance,
          balance: widget.fundToEdit!.balance - widget.fundToEdit!.initialBalance + initialBalance,
        );
        controller.updateSubFund(updatedFund);
      } else {
        controller.createSubFund(
          name: name,
          type: widget.fundType,
          bankName: widget.fundType == FundType.cash ? null : _bankNameController.text.trim(),
          accountNumber: widget.fundType == FundType.cash ? null : _accountNumberController.text.trim(),
          initialBalance: initialBalance,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = '';
    IconData titleIcon;

    switch (widget.fundType) {
      case FundType.cash:
        title = widget.fundToEdit != null ? 'تعديل صندوق النقدي' : 'إضافة فرع / صندوق نقدي';
        titleIcon = Icons.money;
        break;
      case FundType.bank:
        title = widget.fundToEdit != null ? 'تعديل حساب بنكي' : 'إضافة حساب بنكي جديد';
        titleIcon = Icons.account_balance;
        break;
      case FundType.transfer:
        title = widget.fundToEdit != null ? 'تعديل شركة حوالات' : 'إضافة شركة حوالات جديدة';
        titleIcon = Icons.send;
        break;
    }

    // محاكاة آلية قسم المبيعات تماماً
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 25),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
                ),
              ),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                    child: Icon(titleIcon, color: AppTheme.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 15),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 30),

              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPremiumTextField(
                      controller: _nameController,
                      label: 'الاسم التعريفي',
                      hint: 'مثال: نقدية المحل، حساب الإنماء...',
                      icon: Icons.label_important_outline,
                      validator: (v) => v == null || v.isEmpty ? 'هذا الحقل مطلوب' : null,
                    ),
                    const SizedBox(height: 20),

                    if (widget.fundType == FundType.bank || widget.fundType == FundType.transfer) ...[
                      _buildPremiumTextField(
                        controller: _bankNameController,
                        label: widget.fundType == FundType.bank ? 'اسم البنك' : 'اسم الشركة',
                        hint: widget.fundType == FundType.bank ? 'مثال: بنك الراجحي' : 'مثال: شركة النجم',
                        icon: Icons.business_outlined,
                        validator: (v) => v == null || v.isEmpty ? 'هذا الحقل مطلوب' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildPremiumTextField(
                        controller: _accountNumberController,
                        label: widget.fundType == FundType.bank ? 'رقم الحساب' : 'رقم الاشتراك',
                        hint: 'أدخل الرقم هنا للتوثيق',
                        icon: Icons.credit_card_outlined,
                      ),
                      const SizedBox(height: 20),
                    ],

                    _buildPremiumTextField(
                      controller: _initialBalanceController,
                      label: 'الرصيد الافتتاحي',
                      hint: '0.0',
                      icon: Icons.account_balance_wallet_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.fundToEdit != null ? Icons.save_rounded : Icons.add_rounded),
                      const SizedBox(width: 12),
                      Text(
                        widget.fundToEdit != null ? 'حفظ التعديلات' : 'إنشاء الصندوق الآن',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }
}
