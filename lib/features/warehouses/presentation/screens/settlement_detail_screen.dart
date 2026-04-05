// File: lib/features/warehouses/presentation/screens/settlement_detail_screen.dart

import 'package:flutter/material.dart';

/// شاشة تفاصيل تسوية المندوب (للطباعة والمشاركة في المستقبل)
/// حالياً التسوية مدمجة في settlement_screen.dart
/// هذا الملف محجوز للتوسع المستقبلي (طباعة PDF، مشاركة التقرير.)
class SettlementDetailScreen extends StatelessWidget {
  final Map<String, dynamic> settlementData;
  final String repName;

  const SettlementDetailScreen({
    super.key,
    required this.settlementData,
    required this.repName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تقرير تسوية: $repName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: مشاركة التقرير كملف PDF
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('سيتم تطوير هذه الشاشة لاحقاً (طباعة التقرير)'),
      ),
    );
  }
}
