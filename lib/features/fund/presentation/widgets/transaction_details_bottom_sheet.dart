// File: lib/features/fund/presentation/widgets/transaction_details_bottom_sheet.dart

import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_transaction_model.dart';
import 'package:ehab_company_admin/features/fund/presentation/controllers/fund_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:io';
import 'package:printing/printing.dart';
import '../../../../core/services/settings_service.dart';

class TransactionDetailsBottomSheet extends StatelessWidget {
  final FundTransactionModel transaction;

  const TransactionDetailsBottomSheet({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<SettingsService>();
    final controller = Get.find<FundController>();
    
    final bool isDeposit = transaction.type == TransactionType.DEPOSIT;
    final bool isTransfer = transaction.type == TransactionType.TRANSFER;
    final Color mainColor = isTransfer ? Colors.orange : (isDeposit ? Colors.green : Colors.red);
    
    final formatCurrency = intl.NumberFormat.currency(
      locale: 'ar_SA',
      symbol: currency.primaryCurrency.value.symbol,
    );

    final fund = controller.subFunds.firstWhereOrNull((f) => f.id == transaction.fundId);
    final fundName = fund?.name ?? 'صندوق رقم #${transaction.fundId}';
    final fundTypeName = _getFundTypeName(fund?.fundType);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 10, 25, 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 25),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
                ),
              ),

              _buildPremiumHeader(mainColor, isDeposit, isTransfer, formatCurrency),
              
              const SizedBox(height: 30),
              
              _buildPremiumInfoGrid(fundName, fundTypeName, formatCurrency),

              const SizedBox(height: 30),
              
              if (transaction.attachmentPath != null && transaction.attachmentPath!.isNotEmpty)
                _buildPremiumAttachmentSection(context),

              if (transaction.attachmentPath != null && transaction.attachmentPath!.isNotEmpty)
                const SizedBox(height: 30),
              
              if (transaction.description.isNotEmpty)
                _buildPremiumNoteSection('البيان الرئيسي', transaction.description),

              if (transaction.notes != null && transaction.notes!.isNotEmpty)
                const SizedBox(height: 15),
              
              if (transaction.notes != null && transaction.notes!.isNotEmpty)
                _buildPremiumNoteSection('ملاحظات إضافية / تفاصيل الدفع', transaction.notes!),

              const SizedBox(height: 35),

              _buildPremiumActionButtons(context, mainColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(Color mainColor, bool isDeposit, bool isTransfer, intl.NumberFormat formatCurrency) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: mainColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isTransfer ? Icons.swap_horiz_rounded : (isDeposit ? Icons.south_rounded : Icons.north_rounded),
            color: mainColor,
            size: 40,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          '${isDeposit ? '+' : '-'} ${formatCurrency.format(transaction.amount)}',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: mainColor, letterSpacing: -1),
        ),
        Text(
          _getTypeLabel(),
          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
          child: Text(
            '#${transaction.id}',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumInfoGrid(String fundName, String fundTypeName, intl.NumberFormat formatCurrency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildPremiumInfoRow(Icons.account_balance_wallet_rounded, 'الصندوق المـتأثر', fundName, Colors.blue),
          _buildPremiumInfoRow(Icons.category_rounded, 'نوع الحساب', fundTypeName, Colors.indigo),
          _buildPremiumInfoRow(
            Icons.access_time_filled_rounded, 
            'التاريخ والوقت', 
            intl.DateFormat('yyyy-MM-dd • hh:mm a', 'ar').format(transaction.transactionDate),
            Colors.orange
          ),
          
          if (transaction.fees > 0)
            _buildPremiumInfoRow(Icons.money_off_csred_rounded, 'الرسوم / العمولات', '${transaction.fees} ريال', Colors.red),
          
          if (transaction.fees > 0)
            _buildPremiumInfoRow(
              Icons.summarize_rounded, 
              'المبلغ الإجمالي', 
              '${(transaction.amount + transaction.fees).toStringAsFixed(2)} ريال',
              Colors.green,
              isBold: true
            ),

          if (transaction.transferNumber != null && transaction.transferNumber!.isNotEmpty)
            _buildPremiumInfoRow(Icons.tag_rounded, 'رقم المرجع / الحوالة', transaction.transferNumber!, Colors.teal),
          
          if (transaction.transferCompany != null && transaction.transferCompany!.isNotEmpty)
            _buildPremiumInfoRow(Icons.business_rounded, 'الجهة / الشركة', transaction.transferCompany!, Colors.blueGrey),

          if (transaction.senderName != null && transaction.senderName!.isNotEmpty)
            _buildPremiumInfoRow(Icons.person_pin_rounded, 'اسم المرسل', transaction.senderName!, Colors.purple),
          
          if (transaction.receiverName != null && transaction.receiverName!.isNotEmpty)
            _buildPremiumInfoRow(Icons.person_rounded, 'اسم المستلم', transaction.receiverName!, Colors.deepPurple),

          // حقول البنك (جديد V26)
          if (transaction.bankName != null && transaction.bankName!.isNotEmpty)
            _buildPremiumInfoRow(Icons.account_balance_rounded, 'اسم البنك', transaction.bankName!, Colors.indigo),
          
          if (transaction.bankReference != null && transaction.bankReference!.isNotEmpty)
            _buildPremiumInfoRow(Icons.confirmation_number_rounded, 'رقم المرجع البنكي', transaction.bankReference!, Colors.blueGrey),

          // تفاصيل الموظف والرقابة (V37)
          if (transaction.userName != null)
            _buildPremiumInfoRow(Icons.person_rounded, 'بواسطة الموظف', transaction.userName!, Colors.blue),
          
          if (transaction.customerId != null)
            _buildPremiumInfoRow(Icons.person_pin_rounded, 'معرف العميل المرتبط', '#${transaction.customerId}', Colors.indigo),

          if (transaction.balanceAfter != null)
            _buildPremiumInfoRow(
              Icons.account_balance_wallet_rounded, 
              'الرصيد بعد الحركة', 
              formatCurrency.format(transaction.balanceAfter), 
              Colors.green,
              isBold: true
            ),

          if (transaction.originalInvoiceId != null)
            _buildPremiumInfoRow(Icons.history_rounded, 'الفاتورة الأصلية', '#${transaction.originalInvoiceId}', Colors.orange),

          if (transaction.returnReason != null && transaction.returnReason!.isNotEmpty)
            _buildPremiumInfoRow(Icons.help_outline_rounded, 'سبب الإرجاع', transaction.returnReason!, Colors.red),
        ],
      ),
    );
  }

  Widget _buildPremiumInfoRow(IconData icon, String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 15),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, 
              fontSize: isBold ? 14 : 13, 
              color: isBold ? Colors.black : Colors.black87
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAttachmentSection(BuildContext context) {
    final file = File(transaction.attachmentPath!);
    if (!file.existsSync()) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attachment_rounded, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text('سند الحركة المرفق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700)),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showFullScreenImage(context),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade100),
              image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      children: [
                        Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('انقر للتكبير', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context) {
    Get.dialog(
      Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.file(File(transaction.attachmentPath!), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Get.back()),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  onPressed: () async {
                    final bytes = await File(transaction.attachmentPath!).readAsBytes();
                    await Printing.sharePdf(bytes: bytes, filename: 'receipt_${transaction.id}.jpg');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      useSafeArea: false,
    );
  }

  Widget _buildPremiumNoteSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notes_rounded, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumActionButtons(BuildContext context, Color mainColor) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton.icon(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.close_rounded),
        label: const Text('إغلاق وتجاوز', style: TextStyle(fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade200),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  String _getTypeLabel() {
    if (transaction.type == TransactionType.TRANSFER) return 'حوالة / مناقلة مالية';
    if (transaction.type == TransactionType.DEPOSIT) return 'إيداع نقدي مباشر';
    return 'سحب نقدي مباشر';
  }

  String _getFundTypeName(FundType? type) {
    if (type == null) return 'غير محدد';
    switch (type) {
      case FundType.cash: return 'صندوق نقدي (فروع)';
      case FundType.bank: return 'حساب بنكي (مصارف)';
      case FundType.transfer: return 'شركة حوالات (صرافة)';
    }
  }
}
