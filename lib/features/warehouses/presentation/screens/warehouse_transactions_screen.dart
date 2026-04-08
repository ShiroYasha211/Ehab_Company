// File: lib/features/warehouses/presentation/screens/warehouse_transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ehab_company_admin/features/warehouses/data/models/warehouse_model.dart';
import 'package:ehab_company_admin/features/warehouses/data/models/settlement_model.dart';
import 'package:ehab_company_admin/features/warehouses/data/repositories/settlement_repository.dart';

class WarehouseTransactionsScreen extends StatefulWidget {
  final WarehouseModel warehouse;
  const WarehouseTransactionsScreen({super.key, required this.warehouse});

  @override
  State<WarehouseTransactionsScreen> createState() =>
      _WarehouseTransactionsScreenState();
}

class _WarehouseTransactionsScreenState
    extends State<WarehouseTransactionsScreen> {
  final SettlementRepository _repository = SettlementRepository();
  List<WarehouseTransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final txs = await _repository.getWarehouseTransactions(
        widget.warehouse.id!,
      );
      setState(() => _transactions = txs);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب الحركات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = widget.warehouse.balance;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // رأس الصفحة المطور مع عرض الرصيد
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withBlue(150),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Text(
                      'إجمالي المديونية الحالية',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${balance.toStringAsFixed(2)} ريال',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.warehouse.salesRepName ?? 'مندوب مبيعات',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            title: const Text(
              'كشف حساب المندوب',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),

          // سجل العمليات
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            sliver: _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _transactions.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 70,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'لا توجد عمليات مسجلة حالياً لهذا المندوب',
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final tx = _transactions[index];
                      final isSettlement =
                          tx.type == 'settlement' ||
                          tx.type == 'custody_settlement';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSettlement
                                  ? Colors.orange.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isSettlement
                                  ? Icons.receipt_long
                                  : Icons.account_balance_wallet_rounded,
                              color: isSettlement
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            isSettlement ? 'تسوية عهدة ميدانية' : 'حركة مالية',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${tx.transactionDate.year}/${tx.transactionDate.month}/${tx.transactionDate.day}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              if (tx.notes != null && tx.notes!.isNotEmpty)
                                Text(
                                  tx.notes!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${tx.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: tx.amount > 0
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                ),
                              ),
                              Text(
                                tx.amount > 0 ? 'مدين' : 'دائن',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: tx.amount > 0
                                      ? Colors.red.shade300
                                      : Colors.green.shade300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: _transactions.length),
                  ),
          ),
        ],
      ),
    );
  }
}
