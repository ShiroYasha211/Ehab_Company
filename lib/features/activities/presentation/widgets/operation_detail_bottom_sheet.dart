import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/models/operation_model.dart';

class OperationDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> details;

  const OperationDetailBottomSheet({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final OperationModel operation = details['operation'] as OperationModel;
    final List<dynamic> items = details['items'] as List<dynamic>;
    final Map<String, dynamic> relatedData = details['relatedData'] as Map<String, dynamic>;
    
    final theme = Theme.of(context);
    final color = _getOperationColor(operation.type);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // مقبض السحب
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24, top: 8),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
          ),

          // Header: النوع والمبلغ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(operation.typeLabel, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
                  Text(DateFormat('yyyy-MM-dd | hh:mm a').format(operation.date), style: theme.textTheme.bodySmall),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  operation.amount.toStringAsFixed(2),
                  style: theme.textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 48),

          // محتوى التفاصيل
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'معلومات العملية'),
                  _buildDetailRow('الرقم المرجعي', '#${operation.referenceId}'),
                  _buildDetailRow('الموظف المسؤول', operation.userName ?? 'النظام'),
                  if (relatedData.isNotEmpty && operation.type == OperationType.expense) ...[
                    _buildDetailRow('فئة المصروف', relatedData['categoryName'] ?? 'غير محدد'),
                    _buildDetailRow('الصندوق المستخدم', relatedData['fundName'] ?? 'غير محدد'),
                    if (relatedData['supplierName'] != null)
                      _buildDetailRow('المورد', relatedData['supplierName']),
                  ],
                  const SizedBox(height: 24),

                  if (items.isNotEmpty) ...[
                    _buildSectionTitle(context, 'الأصناف المتضمنة'),
                    const SizedBox(height: 8),
                    _buildItemsTable(context, items),
                    const SizedBox(height: 24),
                  ],

                  if (operation.details != null && operation.details!.isNotEmpty) ...[
                    _buildSectionTitle(context, 'ملاحظات إضافية'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Text(operation.details!, style: const TextStyle(height: 1.5)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),

          // الأزرار السفلية
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('إغلاق'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.snackbar('تحت التطوير', 'ميزة تصدير PDF ستتوفر قريباً');
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('نسخة PDF'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildItemsTable(BuildContext context, List<dynamic> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1.5),
          },
          border: TableBorder.symmetric(inside: BorderSide(color: Colors.grey.shade200)),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade50),
              children: const [
                Padding(padding: EdgeInsets.all(12), child: Text('المنتج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(padding: EdgeInsets.all(12), child: Text('كمية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(padding: EdgeInsets.all(12), child: Text('سعر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
            ...items.map((item) => TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(12), child: Text(item['productName'] ?? 'منتج غير معرف', style: const TextStyle(fontSize: 12))),
                Padding(padding: const EdgeInsets.all(12), child: Text('${item['quantity']}', style: const TextStyle(fontSize: 12))),
                Padding(padding: const EdgeInsets.all(12), child: Text('${item['unitPrice']}', style: const TextStyle(fontSize: 12))),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Color _getOperationColor(OperationType type) {
    switch (type) {
      case OperationType.sale: return Colors.green;
      case OperationType.purchase: return Colors.blue;
      case OperationType.expense: return Colors.red;
      case OperationType.transfer: return Colors.orange;
      case OperationType.returnSale: return Colors.teal;
      case OperationType.returnPurchase: return Colors.indigo;
      default: return Colors.grey;
    }
  }
}
