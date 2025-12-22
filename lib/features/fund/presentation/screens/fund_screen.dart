// File: lib/features/fund/presentation/screens/fund_screen.dart

import 'package:ehab_company_admin/core/theme/app_theme.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_transaction_model.dart';
import 'package:ehab_company_admin/features/fund/presentation/controllers/fund_controller.dart';
import 'package:ehab_company_admin/features/fund/presentation/widgets/add_transaction_dialog.dart';
import 'package:ehab_company_admin/features/fund/presentation/widgets/balance_card.dart';
import 'package:ehab_company_admin/features/fund/presentation/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart' hide DateRangePickerDialog;
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // <-- 1. إضافة import جديد
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:ehab_company_admin/core/services/fund_pdf_service.dart';
import 'package:ehab_company_admin/features/fund/presentation/widgets/date_range_picker_dialog.dart';


class FundScreen extends StatelessWidget {
  const FundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FundController controller = Get.find<FundController>();

    return Scaffold(
      // --- 2. بداية التعديل: AppBar جديد مع فلاتر ---
      appBar: AppBar(
        title: const Text('حركة الصندوق'),
        actions: [
      IconButton(
      icon: const Icon(Icons.print_outlined),
        tooltip: 'طباعة تقرير حركة الصندوق',
        onPressed: () {
          Get.dialog(
              DateRangePickerDialog(
                  onConfirm: (from, to) async {
                    // بعد أن يؤكد المستخدم، قم بإنشاء التقرير
                    try {
                      Get.dialog(
                          const Center(child: CircularProgressIndicator()),
                        barrierDismissible: false,
                      );

                      final reportData = await controller.repository.generateFundFlowReportData(
                        fundId: 1, // افترض أن الصندوق الرئيسي دائماً 1
                        from: from,
                        to: to,
                      );
                      if(Get.isDialogOpen!) Get.back(); // إغلاق مؤشر التحميل

                      await FundPdfService.printFundReport(
                        reportData: reportData,
                        from: from,
                        to: to,
                      );
                    } catch (e){
                      if(Get.isDialogOpen!) Get.back(); // إغلاق مؤشر التحميل في حال حدوث خطأ
                      Get.snackbar('خطأ', 'فشل في إنشاء التقرير: $e');
                    }
                  },
              ),
          );
        },
    ),
          IconButton(
            icon: const Icon(Icons.filter_alt_off_outlined),
            tooltip: 'مسح الفلاتر',
            onPressed: controller.clearFilters,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadFundData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(125.0),
          child: _buildFilters(context, controller),
        ),
      ),
      // --- نهاية التعديل ---

      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.isTrue && controller.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
        
          return RefreshIndicator(
            onRefresh: controller.loadFundData,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildSummaryCards(
                    controller)), // <-- 3. إضافة بطاقات الملخص
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8)
                    , child: Row(
                      mainAxisAlignment
                          : MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الحركات',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text('${controller.transactions.length} حركة'),
                      ],
                    ),
                  ),
                ),
                controller.transactions.isEmpty
                    ? SliverFillRemaining(
                  child: Center(
                    child:
                    Text
                      ('لا توجد حركات تطابق بحثك.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                )
                    : SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final transaction = controller.transactions[index];
                      return TransactionListItem(transaction: transaction);
                    },
                    childCount: controller.transactions.length,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
      // --- 4. بداية التعديل: استخدام SpeedDial FAB ---
      floatingActionButton: SpeedDial(
        // --- 1. الأيقونات والأنميشن الأساسي ---
          icon: Icons.add, // أيقونة الزر عندما يكون مغلقًا
          activeIcon: Icons.close, // أيقونة الزر عندما يكون مفتوحًا
          useRotationAnimation: true, // تدوير الأيقونة عند الفتح
          animationCurve: Curves.elasticInOut, // حركة مرنة وممتعة
          visible: true,

          // --- 2. الحل الجذري لمشكلة الاتجاه ---
          // هذه الخاصية تجبر النصوص على الظهور في الاتجاه المعاكس للأيقونة
          // في بيئة RTL، هذا يعني أن النص سيظهر على يمين الزر
          switchLabelPosition: true,

        // --- 3. تحسينات جمالية إضافية ---
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 8.0,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,

        // التحكم في المسافات
        spacing: 12,
        spaceBetweenChildren: 8,

        // هذا يجعل شكل الزر الرئيسي دائريًا تمامًا
        shape: const CircleBorder(),

        children: [
          SpeedDialChild(
            child: const Icon(Icons.add_circle_outline),
            label: 'توريد نقدي (إيداع)',
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            onTap: () => Get.dialog(const AddTransactionDialog(isDeposit: true)),
          ),
          SpeedDialChild(
            child: const Icon(Icons.remove_circle_outline),
            label: 'صرف نقدي (سحب)',
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            onTap: () => Get.dialog(const AddTransactionDialog(isDeposit: false)),
          ),
        ],
      ),

    );
  }

  // ودجت بناء بطاقات الملخص
  Widget _buildSummaryCards(FundController controller) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          BalanceCard(balance: controller.currentFund.value?.balance ?? 0.0),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _buildMiniCard(
                    'الوارد اليوم',
                    controller.todaysDeposits.value,
                    Icons.arrow_downward,
                    Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: _buildMiniCard(
                'الصادر اليوم',
                controller.todaysWithdrawals.value,
                Icons.arrow_upward,
                Colors.red)),
          ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String title, double value, IconData icon,
      Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                intl.NumberFormat.currency(locale: 'ar_SA', symbol: '')
                    .format(value),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
            ),
            ),
          ],
        ),
      ),
    );
  }

  // ودجت بناء الفلاتر
  Widget _buildFilters(BuildContext context, FundController controller) {
    // --- بداية التعديل ---
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDateField(context, controller, isFromDate: true),
              ),
              const SizedBox(width: 8,),
              Expanded(
                child: _buildDateField(context, controller, isFromDate: false),
              )

            ],
          ),
          const SizedBox(height: 8),
          Obx(() =>
              SegmentedButton<TransactionType?>(
                style: SegmentedButton.styleFrom(
                  // تصغير حجم الخط داخل الأزرار
                  textStyle: const TextStyle(fontSize: 14),
                ), segments: const [
                ButtonSegment(value: null, label: Text('الكل')),
                ButtonSegment(
                    value: TransactionType.DEPOSIT, label: Text('الوارد فقط')),
                ButtonSegment(value: TransactionType.WITHDRAWAL,
                    label: Text('الصادر فقط'))
              ],
                selected: {controller.transactionTypeFilter.value},
                onSelectionChanged: (newSelection) {
                  controller.transactionTypeFilter.value = newSelection.first;
                },
              )),
        ],
      ),
    );
    // --- نهاية التعديل ---
  }

  // ودجت بناء حقل التاريخ
  Widget _buildDateField(BuildContext context, FundController controller,
      {required bool isFromDate}) {
    return Obx(() {
      final date = isFromDate ? controller.fromDate
          .value : controller.toDate.value;
      return TextFormField(
        readOnly: true,
        controller: TextEditingController(
          text: date == null ? '' : intl
              .DateFormat('yyyy-MM-dd', 'ar')
              .format(date),
        ),
        onTap: () => controller.selectDate(context, isFromDate: isFromDate),
        decoration: InputDecoration(
          hintText: isFromDate ? 'من تاريخ' : 'إلى تاريخ',
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
    });
  }
}