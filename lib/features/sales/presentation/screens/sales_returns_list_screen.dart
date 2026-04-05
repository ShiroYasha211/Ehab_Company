import 'package:ehab_company_admin/core/services/settings_service.dart';
import 'package:ehab_company_admin/features/sales/data/services/sales_return_report_service.dart';
import 'package:ehab_company_admin/features/sales/presentation/controllers/sales_returns_controller.dart';
import 'package:ehab_company_admin/features/sales/presentation/screens/sales_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:fl_chart/fl_chart.dart';

class SalesReturnsListScreen extends StatelessWidget {
  const SalesReturnsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesReturnsController());
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('مركز إدارة المرتجعات'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              onPressed: () => SalesReturnReportService.generateAndPreviewReport(
                returns: controller.returns,
                startDate: controller.startDate.value,
                endDate: controller.endDate.value,
                customerName: controller.selectedCustomer.value?.name,
              ),
              tooltip: 'تحميل تقرير PDF المفلتر',
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: controller.fetchReturns,
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.list_alt_rounded, size: 20), text: 'قائمة المرتجعات'),
              Tab(icon: Icon(Icons.analytics_outlined, size: 20), text: 'التحليل الإحصائي'),
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
            // 1. لوحة الإحصائيات السريعة (Summary Dashboard) - تظهر دائماً في الأعلى
            _buildSummaryDashboard(controller, theme),
            
            // 2. شريط الفلاتر المتقدمة (Filter Bar)
            _buildFilterBar(context, controller, theme),

            // 3. المحتوى المتغير (Tabs)
            Expanded(
              child: TabBarView(
                children: [
                  // التبويب الأول: القائمة
                  _buildResultsList(controller, theme),
                  
                  // التبويب الثاني: الإحصائيات
                  _buildStatisticsTab(controller, theme),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showSearchReturnDialog(context),
          label: const Text('إرجاع سريع'),
          icon: const Icon(Icons.add_task_rounded),
          backgroundColor: theme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildResultsList(SalesReturnsController controller, ThemeData theme) {
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

  Widget _buildStatisticsTab(SalesReturnsController controller, ThemeData theme) {
    return Obx(() {
      if (controller.isLoading.isTrue) return const Center(child: CircularProgressIndicator());
      if (controller.returns.isEmpty) return _buildEmptyState(theme, controller);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _buildSectionTitle('توزيع أسباب الإرجاع (تفاعلي)', Icons.pie_chart_rounded),
             _buildReasonPieChart(controller, theme),
             
             const SizedBox(height: 32),
             
             _buildSectionTitle('كبار المرتجعين (Top 5)', Icons.groups_rounded),
             _buildTopReturnersList(controller, theme),
             
             const SizedBox(height: 100), // مساحة للزر العائم
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
  Widget _buildReasonPieChart(SalesReturnsController controller, ThemeData theme) {
    final reasons = controller.returnsByReason;
    final colors = [Colors.blue, Colors.red, Colors.orange, Colors.green, Colors.purple, Colors.cyan, Colors.amber];

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
          // الرسم البياني التفاعلي
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
                      shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // الدليل المفسر (Dynamic Legend)
          Obx(() {
             final touchedIdx = controller.touchedIndex.value;
             if (touchedIdx == -1) {
                return Text(
                  'المس أي جزء لمعرفة التفاصيل',
                  style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic, fontSize: 13),
                );
             }
             final entryList = reasons.entries.toList();
             final entry = entryList[touchedIdx];
             final percentage = (entry.value / controller.totalReturnsValue) * 100;
             return Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: colors[touchedIdx % colors.length].withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: colors[touchedIdx % colors.length].withOpacity(0.2)),
               ),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[touchedIdx % colors.length], shape: BoxShape.circle)),
                   const SizedBox(width: 8),
                   Text(
                     '${entry.key}: ',
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                   ),
                   Text(
                     '${percentage.toStringAsFixed(1)}% من الإجمالي',
                     style: TextStyle(color: colors[touchedIdx % colors.length], fontWeight: FontWeight.bold, fontSize: 14),
                   ),
                 ],
               ),
             );
          }),
        ],
      ),
    );
  }

  Widget _buildTopReturnersList(SalesReturnsController controller, ThemeData theme) {
    final top = controller.topReturners;
    final settings = Get.find<SettingsService>();
    final symbol = settings.primaryCurrency.value.symbol;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: top.map((item) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: theme.primaryColor.withOpacity(0.1), child: Text(item['name'].substring(0, 1), style: TextStyle(color: theme.primaryColor, fontSize: 12))),
          title: Text(item['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1),
          trailing: Text('${(item['value'] as double).toStringAsFixed(0)} $symbol', style: const TextStyle(fontSize: 10, color: Colors.red)),
        )).toList(),
      ),
    );
  }

  Widget _buildSummaryDashboard(SalesReturnsController controller, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: theme.primaryColor,
      child: Obx(() {
        final settings = Get.find<SettingsService>();
        final symbol = settings.primaryCurrency.value.symbol;
        
        return Row(
          children: [
            _buildStatCard(
              'إجمالي المرتجعات',
              '${controller.totalReturnsValue.toStringAsFixed(2)} $symbol',
              Icons.account_balance_wallet_rounded,
              Colors.white,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'عدد العمليات',
              '${controller.returnsCount}',
              Icons.onetwothree_rounded,
              Colors.white.withOpacity(0.9),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'متوسط المرتجع',
              '${controller.averageReturnPrice.toStringAsFixed(0)}',
              Icons.analytics_rounded,
              Colors.white.withOpacity(0.8),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              title,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, SalesReturnsController controller, ThemeData theme) {
    return Container(
      height: 60,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Obx(() => _buildHeaderFilterChip(
            label: controller.startDate.value == null 
                ? 'الفترة الزمنية' 
                : '${intl.DateFormat('MM/dd').format(controller.startDate.value!)} - ${controller.endDate.value != null ? intl.DateFormat('MM/dd').format(controller.endDate.value!) : '...'}',
            icon: Icons.date_range_rounded,
            isSelected: controller.startDate.value != null,
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (range != null) {
                controller.startDate.value = range.start;
                controller.endDate.value = range.end;
              }
            },
          )),

          Obx(() => _buildHeaderFilterChip(
            label: controller.selectedCustomer.value == null ? 'كل العملاء' : controller.selectedCustomer.value!.name,
            icon: Icons.person_search_rounded,
            isSelected: controller.selectedCustomer.value != null,
            onTap: () => _showCustomerPicker(context, controller),
          )),
        ],
      ),
    );
  }

  Widget _buildHeaderFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Get.theme.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Get.theme.primaryColor : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: isSelected ? Get.theme.primaryColor : Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Get.theme.primaryColor : Colors.grey.shade700,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumReturnCard(BuildContext context, Map<String, dynamic> item, ThemeData theme) {
    final date = DateTime.parse(item['returnDate']);
    final settings = Get.find<SettingsService>();
    final symbol = settings.primaryCurrency.value.symbol;
    final total = (item['totalReturnedValue'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.to(() => SalesDetailsScreen(invoiceId: item['originalInvoiceId'])),
            child: Stack(
              children: [
                Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 6, color: theme.primaryColor.withOpacity(0.5))),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('فاتورة #${item['originalInvoiceId']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 2),
                              Row(children: [Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade500), const SizedBox(width: 4), Text(intl.DateFormat('yyyy-MM-dd HH:mm').format(date), style: TextStyle(color: Colors.grey.shade500, fontSize: 11))]),
                            ],
                          ),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text('${total.toStringAsFixed(2)} $symbol', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16))),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(height: 1, thickness: 0.5)),
                      Row(children: [_buildInfoItem(Icons.person_outline_rounded, item['customerName'] ?? 'عميل غير محدد'), const Spacer(), _buildInfoItem(Icons.warehouse_outlined, item['warehouseName'] ?? 'المخزن الرئيسي')]),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RichText(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(text: 'السبب: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
                                  TextSpan(text: item['reason'] ?? 'إرجاع عام', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                          _buildMethodBadge(item['returnedToFund'] == 1),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(right: 8, bottom: 8, child: Icon(Icons.arrow_outward_rounded, size: 14, color: theme.primaryColor.withOpacity(0.4))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: Colors.grey.shade400), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))]);
  }

  Widget _buildMethodBadge(bool isCash) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isCash ? Colors.green.shade50 : Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Text(isCash ? 'نقداً' : 'للآجل', style: TextStyle(color: isCash ? Colors.green.shade700 : Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.bold)));
  }

  Widget _buildEmptyState(ThemeData theme, SalesReturnsController controller) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300), const SizedBox(height: 16), Text('لم نجد نتائج تطابق هذه الفلاتر', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)), const SizedBox(height: 8), TextButton(onPressed: controller.clearFilters, child: const Text('إعادة تعيين الفلاتر'))]));
  }

  void _showCustomerPicker(BuildContext context, SalesReturnsController controller) {
    Get.bottomSheet(Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), child: Column(children: [const Text('اختر العميل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 16), Expanded(child: ListView.builder(itemCount: controller.customerController.filteredCustomers.length + 1, itemBuilder: (context, index) { if (index == 0) { return ListTile(title: const Text('كل العملاء'), onTap: () { controller.selectedCustomer.value = null; Get.back(); }); } final customer = controller.customerController.filteredCustomers[index - 1]; return ListTile(title: Text(customer.name), onTap: () { controller.selectedCustomer.value = customer; Get.back(); }); }))])));
  }

  void _showSearchReturnDialog(BuildContext context) {
    final searchController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('إرجاع سريع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل رقم الفاتورة الأصلية لإتمام عملية الإرجاع عنها.'),
            const SizedBox(height: 20),
            TextField(
              controller: searchController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'رقم الفاتورة (مثلاً: 123)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final id = int.tryParse(searchController.text);
              if (id != null) {
                Get.back();
                Get.to(() => SalesDetailsScreen(invoiceId: id));
              }
            },
            child: const Text('عرض الفاتورة'),
          ),
        ],
      ),
    );
  }
}
