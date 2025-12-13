// File: lib/features/fund/presentation/widgets/transaction_list_item.dart

import 'package:ehab_company_admin/features/fund/data/models/fund_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class TransactionListItem extends StatelessWidget {
  final FundTransactionModel transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final bool isDeposit = transaction.type == TransactionType.DEPOSIT;
    final Color amountColor = isDeposit ? Colors.green.shade700 : Colors.red.shade700;
    final IconData icon = isDeposit ? Icons.arrow_upward : Icons.arrow_downward;
    final String prefix = isDeposit ? '+' : '-';
    final formatCurrency = intl.NumberFormat.currency(locale: 'ar_SA', symbol: 'ريال');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: amountColor.withOpacity(0.15),
          child: Icon(icon, color: amountColor),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          intl.DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(transaction.transactionDate),
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        trailing: Text(
          '$prefix ${formatCurrency.format(transaction.amount)}',
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
