// File: lib/features/purchases/presentation/screens/purchase_returns_list_screen.dart

import 'package:ehab_company_admin/core/services/settings_service.dart';
import 'package:ehab_company_admin/features/purchases/data/services/purchase_return_report_service.dart';
import 'package:ehab_company_admin/features/purchases/presentation/controllers/purchase_returns_controller.dart';
import 'package:ehab_company_admin/features/purchases/presentation/screens/purchase_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:fl_chart/fl_chart.dart';

class PurchaseReturnsListScreen extends StatelessWidget {
  const PurchaseReturnsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PurchaseReturnsController());
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('إدارة مرتجعات المشتريات'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              onPressed: () => PurchaseReturnReportService.generateAndPreviewReport(
                returns: controller.returns,
                startDate: controller.startDate.value,
                endDate: controller.endDate.value,
                supplierName: controller.selectedSupplier.value?.name,
              ),
              tooltip: 'تحميل تقرير PDF المشتريات',
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: controller.fetchReturns,
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.inventory_2_rounded, size: 20), text: 'قائمة المرتجعات'),
              Tab(icon: Icon(Icons.analytics_outlined, size: 20), text: 'التحليل المالي'),
            ],
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            indicatorSize: TabBarIndicatorSize.label,
          ),
        ),
        body: Column(
          children: [
            // 1. لوحة الإحصائيات السريعة
            _buildSummaryDashboard(controller, theme),
            
            // 2. شريط الفلاتر
            _buildFilterBar(context, controller, theme),

            // 3. المحتوى
            Expanded(
              child: TabBarView(
                children: [
                  _buildResultsList(controller, theme),
                  _buildStatisticsTab(controller, theme),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showQuickReturnDialog(context),
          label: const Text('إرجاع مشتريات'),
          icon: const Icon(Icons.assignment_return_rounded),
          backgroundColor: theme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildResultsList(PurchaseReturnsController controller, ThemeData theme) {
    return Obx(() {
      if (controller.isLoading.isTrue) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.returns.isEmpty) {
        return _buildEmptyState(theme, controller);
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: controller.returns.length,
        itemBuilder: (context, index) {
          final item = controller.returns[index];
          return _buildPremiumReturnCard(context, item, theme);
        },
      );
    });
  }

  Widget _buildStatisticsTab(PurchaseReturnsController controller, ThemeData theme) {
    return Obx(() {
      if (controller.isLoading.isTrue) return const Center(child: CircularProgressIndicator());
      if (controller.returns.isEmpty) return _buildEmptyState(theme, controller);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _buildSectionTitle('توزيع أسباب إرجاع المشتريات', Icons.pie_chart_rounded),
             _buildReasonPieChart(controller, theme),
             
             const SizedBox(height: 32),
             
             _buildSectionTitle('كبار الموردين المرتجعين', Icons.business_rounded),
             _buildTopReturnersList(controller, theme),
             
             const SizedBox(height: 100),
          ],
        ),
      );
    });
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildReasonPieChart(PurchaseReturnsController controller, ThemeData theme) {
    final reasons = controller.returnsByReason;
    final colors = [Colors.indigo, Colors.orange, Colors.redAccent, Colors.teal, Colors.deepPurple, Colors.amber];

    if (reasons.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    if (!event.isInterestedForInteractions || 
                        pieTouchResponse == null || 
                        pieTouchResponse.touchedSection == null) {
                      controller.touchedIndex.value = -1;
                      return;
                    }
                    controller.touchedIndex.value = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: reasons.entries.toList().asMap().entries.map((entry) {
                  final i = entry.key;
                  final val = entry.value;
                  final isTouched = i == controller.touchedIndex.value;
                  final fontSize = isTouched ? 18.0 : 12.0;
                  final radius = isTouched ? 70.0 : 60.0;

                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: val.value,
                    title: isTouched ? '${((val.value / controller.totalReturnsValue) * 100).toStringAsFixed(1)}%' : '',
                    radius: radius,
                    titleStyle: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Obx(() {
             final touchedIdx = controller.touchedIndex.value;
             if (touchedIdx == -1) {
                return Text('المس أي جزء لمعرفة الأسباب', style: TextStyle(color: Colors.grey.shade400, fontSize: 13));
             }
             final entry = reasons.entries.toList()[touchedIdx];
             return Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: colors[touchedIdx % colors.length].withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Text('${entry.key}: ${entry.value.toStringAsFixed(2)}', style: TextStyle(color: colors[touchedIdx % colors.length], fontWeight: FontWeight.bold)),
             );
          }),
        ],
      ),
    );
  }

  Widget _buildTopReturnersList(PurchaseReturnsController controller, ThemeData theme) {
    final top = controller.topReturners;
    final settings = Get.find<SettingsService>();
    final symbol = settings.primaryCurrency.value.symbol;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: top.map((item) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: Colors.orange.shade50, child: Text(item['name'].substring(0, 1), style: const TextStyle(color: Colors.orange))),
          title: Text(item['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          trailing: Text('${(item['value'] as double).toStringAsFixed(0)} $symbol', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        )).toList(),
      ),
    );
  }

  Widget _buildSummaryDashboard(PurchaseReturnsController controller, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: theme.primaryColor,
      child: Obx(() {
        final settings = Get.find<SettingsService>();
        final symbol = settings.primaryCurrency.value.symbol;
        return Row(
          children: [
            _buildStatCard('إجمالي المرتجعات', '${controller.totalReturnsValue.toStringAsFixed(2)} $symbol', Icons.assignment_return_rounded),
            const SizedBox(width: 12),
            _buildStatCard('عدد العمليات', '${controller.returnsCount}', Icons.tag_rounded),
            const SizedBox(width: 12),
            _buildStatCard('متوسط العملية', '${controller.averageReturnPrice.toStringAsFixed(0)} $symbol', Icons.show_chart_rounded),
          ],
        );
      }),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1),
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, PurchaseReturnsController controller, ThemeData theme) {
    return Container(
      height: 60,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Obx(() => _buildHeaderFilterChip(
            label: controller.startDate.value == null ? 'الفترة' : '${intl.DateFormat('MM/dd').format(controller.startDate.value!)} - ...',
            icon: Icons.date_range_rounded,
            isSelected: controller.startDate.value != null,
            onTap: () async {
              final range = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now());
              if (range != null) { controller.startDate.value = range.start; controller.endDate.value = range.end; }
            },
          )),
          Obx(() => _buildHeaderFilterChip(
            label: controller.selectedSupplier.value == null ? 'كل الموردين' : controller.selectedSupplier.value!.name,
            icon: Icons.person_search_rounded,
            isSelected: controller.selectedSupplier.value != null,
            onTap: () => _showSupplierPicker(context, controller),
          )),
        ],
      ),
    );
  }

  Widget _buildHeaderFilterChip({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Center(
        child: ActionChip(
          onPressed: onTap,
          avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade600),
          label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12)),
          backgroundColor: isSelected ? Get.theme.primaryColor : Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildPremiumReturnCard(BuildContext context, Map<String, dynamic> item, ThemeData theme) {
    final date = DateTime.parse(item['returnDate']);
    final settings = Get.find<SettingsService>();
    final symbol = settings.primaryCurrency.value.symbol;
    final total = (item['totalValue'] as num).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => Get.to(() => PurchaseDetailsScreen(invoiceId: item['originalInvoiceId'])),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              ListTile(
                title: Text('فاتورة شراء #${item['originalInvoiceId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(intl.DateFormat('yyyy-MM-dd HH:mm').format(date)),
                trailing: Text('${total.toStringAsFixed(2)} $symbol', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(child: _infoRow(Icons.business_rounded, item['supplierName'] ?? 'مورد غير محدد')),
                    Expanded(child: _infoRow(Icons.warehouse_rounded, item['warehouseName'] ?? 'المخزن الرئيسي')),
                  ],
                ),
              ),
              if (item['reason'] != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text('السبب: ${item['reason']}', style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 8), Text(text, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)]);
  }

  Widget _buildEmptyState(ThemeData theme, PurchaseReturnsController controller) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.assignment_return_rounded, size: 80, color: Colors.grey.shade300), const SizedBox(height: 16), const Text('لا يوجد سجل مرتجعات تطابق البحث'), TextButton(onPressed: controller.clearFilters, child: const Text('إعادة تعيين'))]));
  }

  void _showSupplierPicker(BuildContext context, PurchaseReturnsController controller) {
    Get.bottomSheet(Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), child: Column(children: [const Text('اختر المورد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 16), Expanded(child: ListView.builder(itemCount: controller.supplierController.filteredSuppliers.length + 1, itemBuilder: (context, index) { if (index == 0) return ListTile(title: const Text('كل الموردين'), onTap: () { controller.selectedSupplier.value = null; Get.back(); }); final s = controller.supplierController.filteredSuppliers[index - 1]; return ListTile(title: Text(s.name), onTap: () { controller.selectedSupplier.value = s; Get.back(); }); }))])));
  }

  void _showQuickReturnDialog(BuildContext context) {
    final searchController = TextEditingController();
    Get.dialog(AlertDialog(title: const Text('إرجاع مشتريات'), content: TextField(controller: searchController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'رقم الفاتورة الأصلية', prefixIcon: Icon(Icons.search))), actions: [TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')), ElevatedButton(onPressed: () { final id = int.tryParse(searchController.text); if (id != null) { Get.back(); Get.to(() => PurchaseDetailsScreen(invoiceId: id)); } }, child: const Text('عرض الفاتورة'))]));
  }
}
