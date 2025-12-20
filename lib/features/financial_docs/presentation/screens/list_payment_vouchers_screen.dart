// File: lib/features/financial_docs/presentation/screens/list_payment_vouchers_screen.dart

import 'package:ehab_company_admin/features/financial_docs/presentation/controllers/payment_vouchers_controller.dart';
import 'package:ehab_company_admin/features/financial_docs/presentation/screens/transaction_details_screen.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class ListPaymentVouchersScreen extends StatelessWidget {
  const ListPaymentVouchersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PaymentVouchersController controller =
    Get.put(PaymentVouchersController());
    final formatCurrency =
    intl.NumberFormat.currency(locale: 'ar_SA', symbol: ' ريال');

    return Scaffold(
      appBar: AppBar(
        title: const Text('أرشيف سندات الدفع'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off_outlined),
            tooltip: 'مسح الفلاتر',
            onPressed: controller.clearFilters,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130.0),
          child: _buildFilters(context, controller),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.isTrue) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.vouchers.isEmpty) {
          return const Center(
            child: Text('لا توجد سندات دفع تطابق بحثك.',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: controller.vouchers.length,
          itemBuilder: (context, index) {
            final voucher = controller.vouchers[index];
            return _buildVoucherCard(voucher, formatCurrency);
          },
        );
      }),
    );
  }

  /// ودجت بناء فلاتر الشاشة
  Widget _buildFilters(
      BuildContext context, PaymentVouchersController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // فلتر المورد
          Obx(() => DropdownButtonFormField<SupplierModel?>(
            value: controller.selectedSupplier.value,
            items: [
              const DropdownMenuItem<SupplierModel?>(
                value: null,
                child: Text('كل الموردين'),
              ),
              ...controller.supplierController.filteredSuppliers
                  .map((supplier) {
                return DropdownMenuItem<SupplierModel?>(
                  value: supplier,
                  child: Text(supplier.name),
                );
              }).toList(),
            ],
            onChanged: (value) {
              controller.selectedSupplier.value = value;
            },
            decoration: InputDecoration(
              hintText: 'فلترة حسب المورد',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          )),
          const SizedBox(height: 10),
          // فلاتر التاريخ
          Row(
            children: [
              Expanded(
                child: _buildDateField(context, controller, isFromDate: true),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateField(context, controller, isFromDate: false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ودجت بناء حقل التاريخ
  Widget _buildDateField(
      BuildContext context, PaymentVouchersController controller,
      {required bool isFromDate}) {
    return Obx(() {
      final date =
      isFromDate ? controller.fromDate.value : controller.toDate.value;
      return TextFormField(
        readOnly: true,
        controller: TextEditingController(
          text: date == null ? '' : intl.DateFormat('yyyy-MM-dd').format(date),
        ),
        onTap: () => controller.selectDate(context, isFromDate: isFromDate),
        decoration: InputDecoration(
          labelText: isFromDate ? 'من تاريخ' : 'إلى تاريخ',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
      );
    });
  }

  /// ودجت بناء بطاقة عرض السند
  Widget _buildVoucherCard(
      SupplierTransactionModel voucher, intl.NumberFormat formatCurrency) {
    final isOpeningBalance = voucher.type == SupplierTransactionType.OPENING_BALANCE;
    final icon = isOpeningBalance ? Icons.play_for_work_rounded : Icons.upload_file_rounded;
    final color = isOpeningBalance ? Colors.orange.shade700 : Colors.blue.shade700;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          voucher.supplierName ?? 'مورد غير محدد',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'تاريخ: ${intl.DateFormat('yyyy-MM-dd').format(voucher.transactionDate)}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: Text(
          formatCurrency.format(voucher.amount),
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
        onTap: () {
           Get.to(() => TransactionDetailsScreen(transaction: voucher));
        },
      ),
    );
  }
}
