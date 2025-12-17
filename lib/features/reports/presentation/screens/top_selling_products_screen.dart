// File: lib/features/reports/presentation/screens/top_selling_products_screen.dart

import 'package:ehab_company_admin/features/reports/presentation/controllers/top_selling_products_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class TopSellingProductsScreen extends StatelessWidget {
  const TopSellingProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TopSellingProductsController controller =
    Get.put(TopSellingProductsController());
    final formatCurrency =
    intl.NumberFormat.currency(locale: 'ar_SA', symbol: ' ريال');

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير أفضل المنتجات مبيعًا'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120.0),
          child: _buildFilters(context, controller),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.isTrue) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.topProducts.isEmpty) {
          return const Center(
            child: Text('لا توجد بيانات مبيعات في الفترة المحددة.',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: controller.topProducts.length,
          itemBuilder: (context, index) {
            final productData = controller.topProducts[index];
            return _buildProductCard(
                productData, index + 1, formatCurrency, controller.orderBy.value);
          },
        );
      }),
    );
  }

  /// ودجت بناء فلاتر التقرير
  Widget _buildFilters(
      BuildContext context, TopSellingProductsController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
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
          const SizedBox(height: 10),
          // فلتر نوع الترتيب
          Obx(() => SegmentedButton<TopSellingOrderBy>(
            segments: const [
              ButtonSegment(
                  value: TopSellingOrderBy.totalQuantity,
                  label: Text('الأكثر مبيعًا (كمية)')),
              ButtonSegment(
                  value: TopSellingOrderBy.totalRevenue,
                  label: Text('الأعلى إيرادًا')),
            ],
            selected: {controller.orderBy.value},
            onSelectionChanged: (newSelection) {
              controller.orderBy.value = newSelection.first;
            },
          )),
        ],
      ),
    );
  }

  /// ودجت بناء حقل التاريخ
  Widget _buildDateField(
      BuildContext context, TopSellingProductsController controller,
      {required bool isFromDate}) {
    return Obx(() {
      final date = isFromDate ? controller.fromDate.value : controller.toDate.value;
      return TextFormField(
        readOnly: true,
        controller: TextEditingController(
          text: intl.DateFormat('yyyy-MM-dd', 'en').format(date),
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

  /// ودجت بناء بطاقة المنتج في التقرير
  Widget _buildProductCard(Map<String, dynamic> productData, int rank,
      intl.NumberFormat formatCurrency, TopSellingOrderBy orderBy) {
    final bool isByQuantity = orderBy == TopSellingOrderBy.totalQuantity;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Get.theme.primaryColor,
          foregroundColor: Colors.white,
          child: Text(rank.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(productData['name'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          isByQuantity
              ? 'إجمالي الإيراد: ${formatCurrency.format(productData['totalRevenue'])}'
              : 'الكمية المباعة: ${(productData['totalQuantity'] as num).toInt()} قطعة',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: Text(
          isByQuantity
              ? '${(productData['totalQuantity'] as num).toInt()}\nقطعة'
              : formatCurrency.format(productData['totalRevenue']),
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Get.theme.colorScheme.secondary),
        ),
      ),
    );
  }
}
