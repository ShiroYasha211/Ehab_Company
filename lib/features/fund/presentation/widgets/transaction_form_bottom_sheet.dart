// File: lib/features/fund/presentation/widgets/transaction_form_bottom_sheet.dart

import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';
import 'package:ehab_company_admin/features/fund/presentation/controllers/fund_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:image_picker/image_picker.dart';

class TransactionFormBottomSheet extends StatefulWidget {
  final int fundId;
  final FundType fundType;
  final String fundName;
  final bool initialIsDeposit;

  const TransactionFormBottomSheet({
    super.key,
    required this.fundId,
    required this.fundType,
    required this.fundName,
    this.initialIsDeposit = true,
  });

  @override
  State<TransactionFormBottomSheet> createState() => _TransactionFormBottomSheetState();
}

class _TransactionFormBottomSheetState extends State<TransactionFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final FundController _fundController = Get.find();
  
  late bool _isDeposit;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _feesController = TextEditingController(text: '0');
  final _referenceController = TextEditingController(); // رقم المرجع / رقم الحوالة
  final _senderNameController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _transferCompanyController = TextEditingController();
  final _personNameController = TextEditingController(); // للكاش
  
  final _dateController = TextEditingController();
  late DateTime _selectedDate;
  String? _attachmentPath;

  @override
  void initState() {
    super.initState();
    _isDeposit = widget.initialIsDeposit;
    _selectedDate = DateTime.now();
    _dateController.text = intl.DateFormat('yyyy-MM-dd • hh:mm a', 'ar').format(_selectedDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _feesController.dispose();
    _referenceController.dispose();
    _senderNameController.dispose();
    _receiverNameController.dispose();
    _transferCompanyController.dispose();
    _personNameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      setState(() {
        _attachmentPath = image.path;
      });
    }
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ar'),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
          _dateController.text = intl.DateFormat('yyyy-MM-dd • hh:mm a', 'ar').format(_selectedDate);
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final fees = double.tryParse(_feesController.text) ?? 0.0;
      final description = _descriptionController.text;

      if (_isDeposit) {
        _fundController.makeDeposit(
          fundId: widget.fundId,
          amount: amount,
          description: description,
          fees: fees,
          transactionDate: _selectedDate,
          attachmentPath: _attachmentPath,
          transferNumber: widget.fundType != FundType.cash ? _referenceController.text : null,
          senderName: widget.fundType == FundType.transfer ? _senderNameController.text : (widget.fundType == FundType.cash ? _personNameController.text : null),
          receiverName: widget.fundType == FundType.transfer ? _receiverNameController.text : null,
          transferCompany: widget.fundType == FundType.transfer ? _transferCompanyController.text : null,
          referenceType: widget.fundType == FundType.transfer ? 'HAWALA' : (widget.fundType == FundType.bank ? 'BANK' : 'CASH'),
        );
      } else {
        _fundController.makeWithdrawal(
          fundId: widget.fundId,
          amount: amount,
          description: description,
          fees: fees,
          transactionDate: _selectedDate,
          attachmentPath: _attachmentPath,
          transferNumber: widget.fundType != FundType.cash ? _referenceController.text : null,
          senderName: widget.fundType == FundType.transfer ? _senderNameController.text : (widget.fundType == FundType.cash ? _personNameController.text : null),
          receiverName: widget.fundType == FundType.transfer ? _receiverNameController.text : null,
          transferCompany: widget.fundType == FundType.transfer ? _transferCompanyController.text : null,
          referenceType: widget.fundType == FundType.transfer ? 'HAWALA' : (widget.fundType == FundType.bank ? 'BANK' : 'CASH'),
        );
      }
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
                
                _buildPremiumHeader(),
                const SizedBox(height: 25),
                
                _buildPremiumTypeToggle(),
                const SizedBox(height: 25),

                _buildPremiumAmountField(),
                const SizedBox(height: 20),

                _buildMainPremiumFields(),
                
                _buildContextualPremiumFields(),

                const SizedBox(height: 20),
                _buildPremiumAttachmentSection(),
                
                const SizedBox(height: 30),
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
          decoration: BoxDecoration(
            color: (_isDeposit ? Colors.green : Colors.red).withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            _isDeposit ? Icons.keyboard_double_arrow_down_rounded : Icons.keyboard_double_arrow_up_rounded,
            color: _isDeposit ? Colors.green : Colors.red,
            size: 24,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isDeposit ? 'إيداع نقدي جديد' : 'سحب نقدي جديد',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                widget.fundName,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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

  Widget _buildPremiumTypeToggle() {
    return Container(
      height: 55,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPremiumToggleItem(
              title: 'إيـداع (وارد)',
              isActive: _isDeposit,
              onTap: () => setState(() => _isDeposit = true),
              activeColor: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPremiumToggleItem(
              title: 'سحـب (صادر)',
              isActive: !_isDeposit,
              onTap: () => setState(() => _isDeposit = false),
              activeColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumToggleItem({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isActive ? [
            BoxShadow(
              color: activeColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade500,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 8, bottom: 8),
          child: Text('المبلغ الـمخصص للحركة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
          textAlign: TextAlign.center,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(color: Colors.grey.shade200),
            filled: true,
            fillColor: Colors.grey.shade50,
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.blue, size: 20),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'يرجى إدخال المبلغ';
            if (double.tryParse(v) == null || double.parse(v) <= 0) return 'مبلغ غير صحيح';
            return null;
          },
        ),
        _buildPremiumTotalPreview(),
      ],
    );
  }

  Widget _buildPremiumTotalPreview() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final fees = double.tryParse(_feesController.text) ?? 0.0;
    if (fees == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, size: 16, color: Colors.orange),
          const SizedBox(width: 10),
          Text(
            'الإجمالي مع الرسوم: ',
            style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            '${(amount + fees).toStringAsFixed(2)} ريال',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.orange.shade900),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPremiumFields() {
    return Column(
      children: [
        _buildPremiumInput(
          controller: _descriptionController,
          label: 'البيان (وصف العملية) *',
          icon: Icons.description_outlined,
          validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال البيان' : null,
        ),
        const SizedBox(height: 15),
        _buildPremiumInput(
          controller: _dateController,
          label: 'تاريخ وتوقيت الحركة',
          icon: Icons.calendar_today_rounded,
          readOnly: true,
          onTap: _selectDateTime,
        ),
      ],
    );
  }

  Widget _buildContextualPremiumFields() {
    return Column(
      children: [
        const SizedBox(height: 15),
        if (widget.fundType == FundType.bank) _buildPremiumBankFields(),
        if (widget.fundType == FundType.transfer) _buildPremiumTransferFields(),
        if (widget.fundType == FundType.cash) _buildPremiumCashFields(),
      ],
    );
  }

  Widget _buildPremiumBankFields() {
    return Column(
      children: [
        _buildPremiumInput(
          controller: _referenceController,
          label: 'رقم العملية / المرجع البنكي',
          icon: Icons.tag_rounded,
        ),
        const SizedBox(height: 15),
        _buildPremiumInput(
          controller: _feesController,
          label: 'رسوم العملية (إن وجدت)',
          icon: Icons.money_off_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildPremiumTransferFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildPremiumInput(
                controller: _referenceController,
                label: 'رقم الحوالة',
                icon: Icons.tag_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPremiumInput(
                controller: _feesController,
                label: 'العمولة',
                icon: Icons.receipt_long_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildPremiumInput(
          controller: _senderNameController,
          label: 'اسم المرسل',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 15),
        _buildPremiumInput(
          controller: _receiverNameController,
          label: 'اسم المستلم',
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 15),
        _buildPremiumInput(
          controller: _transferCompanyController,
          label: 'شركة التحويل',
          icon: Icons.business_rounded,
        ),
      ],
    );
  }

  Widget _buildPremiumCashFields() {
    return _buildPremiumInput(
      controller: _personNameController,
      label: _isDeposit ? 'اسم المُسلم (المورد)' : 'اسم المُستلم (العميل)',
      icon: Icons.person_pin_rounded,
    );
  }

  Widget _buildPremiumInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
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
          readOnly: readOnly,
          onTap: onTap,
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

  Widget _buildPremiumAttachmentSection() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _attachmentPath != null ? Colors.blue.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _attachmentPath != null ? Colors.blue.withOpacity(0.2) : Colors.grey.shade100,
            style: BorderStyle.solid
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (_attachmentPath != null ? Colors.blue : Colors.grey.shade400).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)
              ),
              child: Icon(
                _attachmentPath != null ? Icons.image_rounded : Icons.camera_alt_rounded,
                color: _attachmentPath != null ? Colors.blue : Colors.grey.shade400,
                size: 20
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                _attachmentPath != null ? 'تم إرفاق صورة السند ✅' : 'إرفاق صورة المستند / السند',
                style: TextStyle(
                  color: _attachmentPath != null ? Colors.blue.shade700 : Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            if (_attachmentPath != null)
              GestureDetector(
                onTap: () => setState(() => _attachmentPath = null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: Colors.red),
                ),
              )
            else
              Icon(Icons.add_circle_outline_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSubmitButton() {
    final color = _isDeposit ? Colors.green : Colors.red;
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isDeposit ? Icons.check_circle_rounded : Icons.outbox_rounded),
            const SizedBox(width: 12),
            Text(
              _isDeposit ? 'تأكيد عملية الإيداع' : 'تأكيد عملية السحب',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
