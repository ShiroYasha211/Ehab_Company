import 'package:ehab_company_admin/features/activities/data/models/activity_model.dart';
import 'package:ehab_company_admin/features/activities/presentation/controllers/activity_controller.dart';
import 'package:ehab_company_admin/features/activities/presentation/widgets/activity_filter_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class ActivitiesDashboardScreen extends StatelessWidget {
  const ActivitiesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // التأكد من تهيئة المتحكم
    final ActivityController controller = Get.isRegistered<ActivityController>() 
        ? Get.find<ActivityController>() 
        : Get.put(ActivityController());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('إدارة العمليات والرقابة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.loadActivities(),
            tooltip: 'تحديث السجلات',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                onPressed: () {
                  Get.bottomSheet(
                    const ActivityFilterDialog(),
                    isScrollControlled: true,
                  );
                },
              ),
              Obx(() => controller.isAnyFilterActive 
                ? Positioned(
                    right: 8, top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${controller.activeFiltersCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ) 
                : const SizedBox.shrink()),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderStats(controller),
          _buildSearchBar(controller),
          _buildActiveFilters(controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.activities.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        controller.isAnyFilterActive 
                          ? 'لا توجد نتائج تطابق الفلاتر المختارة'
                          : 'لا توجد سجلات عمليات حتى الآن',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 16),
                      if (!controller.isAnyFilterActive)
                        ElevatedButton.icon(
                          onPressed: () => _seedMockData(controller),
                          icon: const Icon(Icons.bolt_rounded),
                          label: const Text('توليد سجلات تجريبية حقيقية'),
                        )
                      else
                        TextButton.icon(
                          onPressed: () => controller.resetFilters(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة تعيين الفلاتر'),
                        ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: controller.activities.length,
                itemBuilder: (context, index) {
                  final activity = controller.activities[index];
                  final bool isLast = index == controller.activities.length - 1;
                  return _buildTimelineItem(context, activity, isLast);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ActivityController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        onChanged: (val) => controller.searchQuery.value = val,
        decoration: InputDecoration(
          hintText: 'بحث في الإجراءات أو التفاصيل...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear_rounded), 
                onPressed: () => controller.searchQuery.value = ''
              ) 
            : const SizedBox.shrink()),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilters(ActivityController controller) {
    return Obx(() {
      if (!controller.isAnyFilterActive) return const SizedBox.shrink();
      
      return Container(
        height: 40,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (controller.selectedUserId.value != null)
              _buildFilterChip('الموظف', () => controller.selectedUserId.value = null),
            if (controller.selectedType.value != null)
              _buildFilterChip(controller.selectedType.value!.label, () => controller.selectedType.value = null),
            if (controller.selectedDateRange.value != null)
              _buildFilterChip('الفترة الزمنية', () => controller.selectedDateRange.value = null),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: InputChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        onDeleted: () {
          onDeleted();
          Get.find<ActivityController>().loadActivities();
        },
        deleteIcon: const Icon(Icons.close_rounded, size: 14),
        backgroundColor: Colors.blue.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: Colors.blue.shade100),
      ),
    );
  }

  // دالة مساعدة لتوليد بيانات حقيقية في قاعدة البيانات للاختبار
  void _seedMockData(ActivityController controller) async {
    await controller.logAction(
      action: 'تسجيل دخول (تجريبي)',
      details: 'تم الدخول للنظام من لوحة التحكم',
      type: ActivityType.auth,
    );
    await controller.logAction(
      action: 'فحص المخزون',
      details: 'قام الأدمن بمراجعة حالة المخازن الرئيسية',
      type: ActivityType.inventory,
    );
    Get.snackbar('تم', 'تم توليد سجلات حقيقية في قاعدة البيانات بنجاح');
  }

  Widget _buildHeaderStats(ActivityController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        final todayCount = controller.activities.where((a) {
          final now = DateTime.now();
          return a.time.year == now.year && a.time.month == now.month && a.time.day == now.day;
        }).length;

        final sensitiveCount = controller.activities.where((a) => 
          a.type == ActivityType.admin || a.type == ActivityType.inventory).length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('سجلات اليوم', todayCount.toString(), Colors.blue),
            _buildStatItem('عمليات حساسة', sensitiveCount.toString(), Colors.orange),
            _buildStatItem('إجمالي السجلات', controller.activities.length.toString(), Colors.purple),
          ],
        );
      }),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, ActivityModel activity, bool isLast) {
    final String timeStr = intl.DateFormat('hh:mm a').format(activity.time);
    final String dateStr = intl.DateFormat('MMM dd').format(activity.time);

    // استخدام الـ extension الجديد للحصول على اللون والأيقونة
    final color = activity.type.color;
    IconData icon;
    switch (activity.type) {
      case ActivityType.auth: icon = Icons.lock_person_outlined; break;
      case ActivityType.sale: icon = Icons.point_of_sale_rounded; break;
      case ActivityType.inventory: icon = Icons.inventory_2_outlined; break;
      case ActivityType.admin: icon = Icons.admin_panel_settings_outlined; break;
      case ActivityType.purchase: icon = Icons.shopping_bag_outlined; break;
      case ActivityType.expense: icon = Icons.receipt_long_outlined; break;
      case ActivityType.fund: icon = Icons.account_balance_wallet_outlined; break;
      default: icon = Icons.history_rounded;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 2),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${activity.userName} (${activity.userRole})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('$dateStr | $timeStr', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  elevation: 0, color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                activity.type.label,
                                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                activity.action,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        if (activity.details != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            activity.details!,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
