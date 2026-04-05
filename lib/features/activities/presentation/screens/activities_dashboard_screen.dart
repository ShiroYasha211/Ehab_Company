import 'package:ehab_company_admin/features/activities/data/models/activity_model.dart';
import 'package:ehab_company_admin/features/activities/presentation/controllers/activity_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class ActivitiesDashboardScreen extends StatelessWidget {
  const ActivitiesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ActivityController controller = Get.put(ActivityController());

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
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
              Get.snackbar('قريباً', 'سيتم تفعيل الفلترة المتقدمة في الخطوة القادمة');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderStats(controller),
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
                        'لا توجد سجلات عمليات حتى الآن',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _seedMockData(controller),
                        icon: const Icon(Icons.bolt_rounded),
                        label: const Text('توليد سجلات تجريبية حقيقية'),
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

    // تحديد اللون والأيقونة بناءً على النوع
    IconData icon;
    Color color;
    switch (activity.type) {
      case ActivityType.auth:
        icon = Icons.lock_person_outlined;
        color = Colors.blue;
        break;
      case ActivityType.sale:
        icon = Icons.point_of_sale_rounded;
        color = Colors.green;
        break;
      case ActivityType.inventory:
        icon = Icons.inventory_2_outlined;
        color = Colors.orange;
        break;
      case ActivityType.admin:
        icon = Icons.admin_panel_settings_outlined;
        color = Colors.purple;
        break;
      default:
        icon = Icons.history_rounded;
        color = Colors.grey;
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
                    Text(
                      '${activity.userName} (${activity.userRole})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                        Text(activity.action, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
                        if (activity.details != null) ...[
                          const SizedBox(height: 4),
                          Text(activity.details!, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
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
