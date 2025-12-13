// File: lib/features/fund/presentation/screens/fund_screen.dart

import 'package:ehab_company_admin/features/fund/presentation/controllers/fund_controller.dart';
import 'package:ehab_company_admin/features/fund/presentation/widgets/add_transaction_dialog.dart';
import 'package:ehab_company_admin/features/fund/presentation/widgets/balance_card.dart';
import 'package:ehab_company_admin/features/fund/presentation/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FundScreen extends StatelessWidget {
  const FundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدام Get.put() لتهيئة الكنترولر ليكون متاحاً
    final FundController controller = Get.put(FundController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('حركة الصندوق'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadFundData(), // زر لتحديث البيانات
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.isTrue) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // 1. بطاقة عرض الرصيد الحالي
            BalanceCard(balance: controller.currentFund.value?.balance ?? 0.0),

            // 2. عنوان قائمة الحركات
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أحدث الحركات',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('${controller.transactions.length} حركة'),
                ],
              ),
            ),

            // 3. قائمة الحركات
            Expanded(
              child: controller.transactions.isEmpty
                  ? const Center(
                child: Text(
                  'لا توجد حركات مسجلة حتى الآن.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: controller.transactions.length,
                itemBuilder: (context, index) {
                  final transaction = controller.transactions[index];
                  return TransactionListItem(transaction: transaction);
                },
              ),
            ),
          ],
        );
      }),
      // 4. أزرار الإضافة (توريد وصرف)
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'deposit_fab', // يجب أن يكون لكل زر Tag فريد
            onPressed: () {
              Get.dialog(const AddTransactionDialog(isDeposit: true));
            },
            label: const Text('توريد نقدي'),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.green,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'withdrawal_fab',
            onPressed: () {
              Get.dialog(const AddTransactionDialog(isDeposit: false));
            },
            label: const Text('صرف نقدي'),
            icon: const Icon(Icons.remove),
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
