// File: lib/features/fund/presentation/widgets/transaction_list_item.dart

import 'package:ehab_company_admin/features/fund/data/models/fund_transaction_model.dart';
import 'package:ehab_company_admin/features/fund/presentation/widgets/transaction_details_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/services/settings_service.dart';

class TransactionListItem extends StatelessWidget {
  final FundTransactionModel transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<SettingsService>();
    final bool isDeposit = transaction.type == TransactionType.DEPOSIT;
    final bool isTransfer = transaction.type == TransactionType.TRANSFER;
    
    Color color;
    IconData icon;
    String prefix;

    if (isTransfer) {
      color = Colors.orange;
      icon = Icons.swap_horiz_rounded;
      prefix = '→';
    } else if (isDeposit) {
      color = Colors.green;
      icon = Icons.add_rounded;
      prefix = '+';
    } else {
      color = Colors.red;
      icon = Icons.remove_rounded;
      prefix = '-';
    }

    final formatCurrency = intl.NumberFormat.currency(
      locale: 'ar_SA',
      symbol: currency.primaryCurrency.value.symbol,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Get.bottomSheet(
          TransactionDetailsBottomSheet(transaction: transaction),
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          intl.DateFormat('yyyy-MM-dd • hh:mm a', 'ar').format(transaction.transactionDate),
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                        ),
                        if (transaction.transferNumber != null && transaction.transferNumber!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 6,
                              children: [
                                _buildPremiumTag(transaction.transferNumber!, Icons.tag, Colors.blue),
                                if (transaction.transferCompany != null) 
                                  _buildPremiumTag(transaction.transferCompany!, Icons.business, Colors.indigo),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$prefix ${formatCurrency.format(transaction.amount)}',
                        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      if (transaction.fees > 0)
                        Text(
                          'رسوم: ${transaction.fees}',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 9),
                        ),
                      if (transaction.balanceAfter != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'الرصيد: ${formatCurrency.format(transaction.balanceAfter!)}',
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 9),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (transaction.userName != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFF5F5F5)),
                ),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'بواسطة: ${transaction.userName}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color.withOpacity(0.6)),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 9, color: color.withOpacity(0.8), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
