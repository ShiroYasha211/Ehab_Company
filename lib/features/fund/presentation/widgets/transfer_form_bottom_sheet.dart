// File: lib/features/fund/presentation/widgets/transfer_form_bottom_sheet.dart

import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';
import 'package:ehab_company_admin/features/fund/presentation/controllers/fund_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransferFormBottomSheet extends StatefulWidget {
  final int? initialSourceFundId;
  const TransferFormBottomSheet({super.key, this.initialSourceFundId});

  @override
  State<TransferFormBottomSheet> createState() => _TransferFormBottomSheetState();
}

class _TransferFormBottomSheetState extends State<TransferFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final FundController _fundController = Get.find();
  
  FundType _sourceType = FundType.cash;
  FundType _targetType = FundType.cash;
  
  FundModel? _sourceFund;
  FundModel? _targetFund;
  
  final _amountController = TextEditingController();
  final _feesController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    if (widget.initialSourceFundId != null) {
      _sourceFund = _fundController.subFunds.firstWhereOrNull((f) => f.id == widget.initialSourceFundId);
      if (_sourceFund != null) {
        _sourceType = _sourceFund!.fundType;
      }
    } else {
       _sourceFund = _fundController.getFundsByType(FundType.cash).firstOrNull;
    }
    
    _targetFund = _fundController.subFunds.firstWhereOrNull((f) => f.id != _sourceFund?.id);
    if (_targetFund != null) {
      _targetType = _targetFund!.fundType;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _feesController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_sourceFund == null || _targetFund == null) {
      Get.snackbar('تنبيه', 'يرجى اختيار الصندوق المصدر والهدف', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    if (_sourceFund!.id == _targetFund!.id) {
       Get.snackbar('تنبيه', 'لا يمكن التحويل إلى نفس الصندوق', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (_formKey.currentState!.validate()) {
      _fundController.transferFunds(
        sourceFundId: _sourceFund!.id,
        targetFundId: _targetFund!.id,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        description: _descriptionController.text,
        fees: double.tryParse(_feesController.text) ?? 0.0,
        transferNumber: _referenceController.text.isNotEmpty ? _referenceController.text : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 10, 25, 25),
          child: Form(
            key: _formKey,
            child: Column(
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
                
                _buildPremiumHeader(),
                const SizedBox(height: 25),
                
                _buildPremiumSourceTargetSection(),

                const SizedBox(height: 30),
                const Divider(height: 1),
                const SizedBox(height: 25),

                _buildPremiumFinancialSection(),
                
                const SizedBox(height: 20),
                _buildPremiumInput(
                  controller: _descriptionController,
                  label: 'البيان (وصف التحويل) *',
                  icon: Icons.description_outlined,
                  validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال البيان' : null,
                ),
                const SizedBox(height: 15),
                _buildPremiumInput(
                  controller: _referenceController,
                  label: 'رقم المرجع / العملية (اختياري)',
                  icon: Icons.tag_rounded,
                ),
                
                const SizedBox(height: 35),
                _buildPremiumSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
          child: const Icon(Icons.swap_horiz_rounded, color: Colors.blue, size: 24),
        ),
        const SizedBox(width: 15),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تحويل بين الصناديق',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                'مناقلة الأرصدة المالية بنظام آمن',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.close, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildPremiumSourceTargetSection() {
    return Column(
      children: [
        _buildPremiumFundPicker(
          title: 'تحويل من (المصدر)',
          type: _sourceType,
          selectedFund: _sourceFund,
          onTypeChanged: (type) {
            setState(() {
              _sourceType = type;
              _sourceFund = _fundController.getFundsByType(type).firstOrNull;
            });
          },
          onFundChanged: (fund) => setState(() => _sourceFund = fund),
          excludeFundId: _targetFund?.id,
          accentColor: Colors.red.shade400,
        ),
        const SizedBox(height: 15),
        Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.keyboard_double_arrow_down_rounded, color: Colors.blue, size: 20),
          ),
        ),
        const SizedBox(height: 15),
        _buildPremiumFundPicker(
          title: 'تحويل إلى (الهدف)',
          type: _targetType,
          selectedFund: _targetFund,
          onTypeChanged: (type) {
            setState(() {
              _targetType = type;
              _targetFund = _fundController.getFundsByType(type).firstOrNull;
            });
          },
          onFundChanged: (fund) => setState(() => _targetFund = fund),
          excludeFundId: _sourceFund?.id,
          accentColor: Colors.green.shade400,
        ),
      ],
    );
  }

  Widget _buildPremiumFundPicker({
    required String title,
    required FundType type,
    required FundModel? selectedFund,
    required Function(FundType) onTypeChanged,
    required Function(FundModel?) onFundChanged,
    required Color accentColor,
    int? excludeFundId,
  }) {
    final funds = _fundController.getFundsByType(type).where((f) => f.id != excludeFundId).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
              Row(
                children: [
                   _buildMiniTypeChip('كاش', FundType.cash, type == FundType.cash, onTypeChanged),
                   const SizedBox(width: 4),
                   _buildMiniTypeChip('بنك', FundType.bank, type == FundType.bank, onTypeChanged),
                   const SizedBox(width: 4),
                   _buildMiniTypeChip('حوالة', FundType.transfer, type == FundType.transfer, onTypeChanged),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<FundModel>(
                value: selectedFund != null && funds.any((f) => f.id == selectedFund.id) ? selectedFund : null,
                isExpanded: true,
                icon: const Icon(Icons.expand_more_rounded, color: Colors.blue),
                hint: const Text('اختر الصندوق', style: TextStyle(fontSize: 13)),
                items: funds.map((f) => DropdownMenuItem(
                  value: f,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.account_balance_wallet_rounded, size: 14, color: accentColor),
                      ),
                      const SizedBox(width: 12),
                      Text(f.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${f.balance.toStringAsFixed(0)} ريال', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                )).toList(),
                onChanged: onFundChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTypeChip(String label, FundType type, bool isSelected, Function(FundType) onTypeChanged) {
    return GestureDetector(
      onTap: () => onTypeChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? Colors.white : Colors.grey.shade400,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFinancialSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildPremiumInput(
                controller: _amountController,
                label: 'المبلغ المراد تحويله *',
                icon: Icons.attach_money_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildPremiumInput(
                controller: _feesController,
                label: 'رسوم التحويل',
                icon: Icons.money_off_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        _buildPremiumTotalPreview(),
      ],
    );
  }

  Widget _buildPremiumTotalPreview() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final fees = double.tryParse(_feesController.text) ?? 0.0;
    if (fees == 0 && amount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                children: [
                  const TextSpan(text: 'سيتم خصم '),
                  TextSpan(
                    text: '${(amount + fees).toStringAsFixed(2)} ريال',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red),
                  ),
                  const TextSpan(text: ' من الصندوق المصادر.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_calls_rounded),
            const SizedBox(width: 12),
            Text(
              'تأكيد المـناقلة الآن',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
