import 'package:ehab_company_admin/core/services/printing/warehouse_pdf_service.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';
import 'package:ehab_company_admin/features/fund/data/repositories/fund_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../data/models/custody_model.dart';
import '../../data/repositories/custody_repository.dart';

class SettlementDetailScreen extends StatelessWidget {
  final CustodySettlementModel settlement;

  const SettlementDetailScreen({super.key, required this.settlement});

  @override
  Widget build(BuildContext context) {
    final future = _loadDetail();

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل التسوية #${settlement.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'طباعة التسوية',
            onPressed: () async {
              final detail = await future;
              await WarehousePdfService.printCustodySettlementDocument(
                settlement: settlement,
                items: detail.items,
                fund: detail.fund,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<_SettlementDetailBundle>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('تعذر تحميل تفاصيل التسوية: ${snapshot.error}'),
            );
          }

          final detail = snapshot.data!;
          final items = detail.items;
          final fund = detail.fund;
          final theme = Theme.of(context);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withBlue(160),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'تقرير تسوية عهدة',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _statusBadge(settlement.settlementDifference),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        settlement.warehouseName ?? 'مندوب',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        intl.DateFormat(
                          'yyyy/MM/dd - hh:mm a',
                          'ar',
                        ).format(settlement.settlementDate),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _headerInfoCard(
                              title: 'طريقة التحصيل',
                              value: _paymentMethodLabel(
                                settlement.paymentMethod,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _headerInfoCard(
                              title: 'الصندوق / الحساب',
                              value: fund?.name ?? 'غير محدد',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        label: 'المباع',
                        value: settlement.totalSoldValue,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summaryCard(
                        label: 'المستلم',
                        value: settlement.receivedAmount,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        label: 'فرق التسوية',
                        value: settlement.settlementDifference,
                        color: settlement.settlementDifference > 0
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summaryCard(
                        label: 'الرصيد الجديد',
                        value: settlement.newBalance,
                        color: settlement.newBalance > 0
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الملخص المالي',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _moneyRow('الرصيد السابق', settlement.previousBalance),
                      _moneyRow(
                        'إجمالي قيمة المباع',
                        settlement.totalSoldValue,
                      ),
                      _moneyRow('المبلغ المستلم', settlement.receivedAmount),
                      _moneyRow(
                        'فرق التسوية',
                        settlement.settlementDifference,
                        emphasize: true,
                      ),
                      _moneyRow(
                        'الرصيد بعد التسوية',
                        settlement.newBalance,
                        emphasize: true,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                if ((settlement.notes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ملاحظات',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(settlement.notes!),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'تفاصيل الأصناف',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${items.length} صنف',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: Text('لا توجد أصناف ضمن هذه التسوية.'),
                          ),
                        )
                      else
                        ...items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Container(
                            margin: EdgeInsets.only(
                              bottom: index == items.length - 1 ? 0 : 10,
                            ),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: theme.primaryColor
                                          .withOpacity(0.12),
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.transferDate != null
                                                ? 'من سند تحويل #${item.transferId} - ${intl.DateFormat('yyyy/MM/dd', 'ar').format(item.transferDate!)}'
                                                : 'من عهدة جارية',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      item.soldValue.toStringAsFixed(2),
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _qtyTile(
                                        'المتاح',
                                        item.availableQty,
                                        Colors.indigo,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _qtyTile(
                                        'المباع',
                                        item.soldQty,
                                        Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _qtyTile(
                                        'المرتجع',
                                        item.returnedQty,
                                        Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _qtyTile(
                                        'المتبقي',
                                        item.remainingQty,
                                        Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'سعر التسوية: ${item.salePricePerBaseUnit.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<_SettlementDetailBundle> _loadDetail() async {
    final repository = CustodyRepository();
    final fundRepository = FundRepository();
    final items = await repository.getSettlementItems(settlement.id!);
    FundModel? fund;
    if (settlement.fundId != null) {
      fund = await fundRepository.getFundById(settlement.fundId!);
    }
    return _SettlementDetailBundle(items: items, fund: fund);
  }

  Widget _panel({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _statusBadge(double difference) {
    final isDebt = difference > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isDebt ? Colors.red : Colors.green).withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isDebt ? 'نتج عجز' : 'رصيد متوازن/دائن',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _headerInfoCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(
    String label,
    double value, {
    bool emphasize = false,
    bool isLast = false,
  }) {
    final color = value > 0 ? Colors.red.shade700 : Colors.green.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
              color: emphasize ? color : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyTile(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _paymentMethodLabel(String? method) {
    switch (method) {
      case 'cash':
        return 'نقد';
      case 'bank':
        return 'بنك';
      case 'transfer':
        return 'حوالة';
      default:
        return 'غير محدد';
    }
  }
}

class _SettlementDetailBundle {
  final List<CustodySettlementItemModel> items;
  final FundModel? fund;

  const _SettlementDetailBundle({required this.items, required this.fund});
}
