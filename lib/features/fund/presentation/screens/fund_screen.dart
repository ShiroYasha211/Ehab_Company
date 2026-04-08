// File: lib/features/fund/presentation/screens/fund_screen.dart

import 'package:ehab_company_admin/core/theme/app_theme.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_transaction_model.dart';
import 'package:ehab_company_admin/features/fund/presentation/controllers/fund_controller.dart';
import 'package:ehab_company_admin/features/fund/presentation/widgets/fund_form_bottom_sheet.dart';
import 'package:ehab_company_admin/features/fund/presentation/widgets/transaction_form_bottom_sheet.dart';
import 'package:ehab_company_admin/features/fund/presentation/widgets/transaction_list_item.dart';
import 'package:ehab_company_admin/features/fund/presentation/widgets/transfer_form_bottom_sheet.dart';
import 'package:flutter/material.dart' hide DateRangePickerDialog;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:ehab_company_admin/core/services/printing/fund_pdf_service.dart';
import 'package:ehab_company_admin/features/fund/presentation/widgets/date_range_picker_dialog.dart';
import 'package:ehab_company_admin/core/services/settings_service.dart';

class FundScreen extends StatefulWidget {
  const FundScreen({super.key});

  @override
  State<FundScreen> createState() => _FundScreenState();
}

class _FundScreenState extends State<FundScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FundController controller = Get.find<FundController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        controller.selectedFundIndex.value = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withBlue(100)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    _buildPremiumBalanceCard(controller),
                  ],
                ),
              ),
              centerTitle: true,
              title: innerBoxIsScrolled 
                ? const Text('إدارة الصناديق والمحفظة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                : null,
            ),
            actions: [
              IconButton(icon: const Icon(Icons.print_outlined, color: Colors.white), onPressed: () => _showPrintDialog(controller)),
              IconButton(icon: const Icon(Icons.filter_alt_off_outlined, color: Colors.white), onPressed: controller.clearFilters),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: controller.loadAllData),
            ],
          ),
          SliverToBoxAdapter(
            child: _buildPillTabs(),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCategoryView(FundType.cash),
            _buildCategoryView(FundType.bank),
            _buildCategoryView(FundType.transfer),
          ],
        ),
      ),
      floatingActionButton: _buildSpeedDial(controller),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  // ==================== بطاقة الرصيد العصرية ====================
  Widget _buildPremiumBalanceCard(FundController controller) {
    final settings = Get.find<SettingsService>();
    final formatCurrency = intl.NumberFormat.currency(locale: 'ar_SA', symbol: settings.primaryCurrency.value.symbol);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          const Text('إجمالي السيولة النقدية والبنكية', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Obx(() => FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatCurrency.format(controller.totalBalance.value),
              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          )),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(50)),
            child: const Text('آمن ومؤمن 🛡️', style: TextStyle(color: Colors.white, fontSize: 9)),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade500,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)]),
        ),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'نقدية'),
          Tab(text: 'بنوك'),
          Tab(text: 'حوالات'),
        ],
      ),
    );
  }

  // ==================== عرض الفئة (كاش/بنك/حوالة) ====================
  Widget _buildCategoryView(FundType type) {
    return Obx(() {
      if (controller.isLoading.value && controller.subFunds.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final funds = controller.getFundsByType(type);
      
      return RefreshIndicator(
        onRefresh: controller.loadAllData,
        child: CustomScrollView(
          slivers: [
            if (funds.isNotEmpty) ...[
              // قائمة الحسابات الفرعية (كبطاقات صغيرة أفقية)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 140, 
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    itemCount: funds.length,
                    itemBuilder: (context, index) => _buildSubFundCard(funds[index]),
                  ),
                ),
              ),

              // بطاقة تفاصيل الصندوق المختار حالياً في هذا النوع
              SliverToBoxAdapter(child: _buildDetailsCardForSelected(type)),

              // الفلاتر
              SliverToBoxAdapter(child: _buildFilters(context, controller)),

              // قائمة الحركات
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('آخر الحركات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${controller.transactions.length} حركة', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => TransactionListItem(transaction: controller.transactions[index]),
                  childCount: controller.transactions.length,
                ),
              ),
            ] else ...[
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade200),
                      const SizedBox(height: 16),
                      const Text('لا توجد حسابات مسجلة في هذا القسم', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Get.bottomSheet(
                            FundFormBottomSheet(fundType: type),
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                          );
                        },
                        child: const Text('أضف أول حساب الآن'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      );
    });
  }

  // ==================== بطاقة الحساب الفرعي (داخل التاب) ====================
  Widget _buildSubFundCard(FundModel fund) {
    return Obx(() {
      bool isSelected = false;
      if (fund.fundType == FundType.cash) isSelected = controller.selectedCashId.value == fund.id;
      if (fund.fundType == FundType.bank) isSelected = controller.selectedBankId.value == fund.id;
      if (fund.fundType == FundType.transfer) isSelected = controller.selectedTransferId.value == fund.id;

      final settings = Get.find<SettingsService>();
      final formatCurrency = intl.NumberFormat.currency(locale: 'ar_SA', symbol: settings.primaryCurrency.value.symbol);

      return GestureDetector(
        onTap: () {
          if (fund.fundType == FundType.cash) controller.selectedCashId.value = fund.id;
          if (fund.fundType == FundType.bank) controller.selectedBankId.value = fund.id;
          if (fund.fundType == FundType.transfer) controller.selectedTransferId.value = fund.id;
        },
        onLongPress: () => _showFundManagementSheet(context, fund),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 150,
          margin: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
            border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text(fund.displayIcon, style: const TextStyle(fontSize: 16)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fund.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatCurrency.format(fund.balance),
                    style: TextStyle(
                      color: isSelected ? Colors.white.withOpacity(0.9) : AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ==================== بطاقة تفاصيل الصندوق المختار ====================
  Widget _buildDetailsCardForSelected(FundType type) {
    return Obx(() {
      final fund = controller.getSelectedFund();
      if (fund == null || fund.fundType != type) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            if (fund.bankName != null || fund.accountNumber != null) ...[
              if (fund.bankName != null) _buildInfoRow(Icons.account_balance, 'البنك', fund.bankName!),
              if (fund.accountNumber != null) _buildInfoRow(Icons.credit_card, 'رقم الحساب', fund.accountNumber!),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF5F5F5))),
            ],
            Row(
              children: [
                Expanded(child: _buildSummaryItem('الوارد اليوم', controller.todaysDeposits.value, Colors.green, Icons.keyboard_double_arrow_down_rounded)),
                const SizedBox(width: 15),
                Expanded(child: _buildSummaryItem('الصادر اليوم', controller.todaysWithdrawals.value, Colors.red, Icons.keyboard_double_arrow_up_rounded)),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, double value, Color color, IconData icon) {
    final settings = Get.find<SettingsService>();
    final formatCurrency = intl.NumberFormat.currency(locale: 'ar_SA', symbol: settings.primaryCurrency.value.symbol);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                FittedBox(
                  child: Text(
                    formatCurrency.format(value),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== الفلاتر ====================
  Widget _buildFilters(BuildContext context, FundController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDateField(context, controller, isFromDate: true)),
              const SizedBox(width: 8),
              Expanded(child: _buildDateField(context, controller, isFromDate: false)),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => SegmentedButton<TransactionType?>(
            style: SegmentedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 12),
              padding: EdgeInsets.zero,
            ),
            segments: const [
              ButtonSegment(value: null, label: Text('الكل')),
              ButtonSegment(value: TransactionType.DEPOSIT, label: Text('الوارد')),
              ButtonSegment(value: TransactionType.WITHDRAWAL, label: Text('الصادر')),
            ],
            selected: {controller.transactionTypeFilter.value},
            onSelectionChanged: (s) => controller.transactionTypeFilter.value = s.first,
          )),
        ],
      ),
    );
  }

  Widget _buildDateField(BuildContext context, FundController controller, {required bool isFromDate}) {
    return Obx(() {
      final date = isFromDate ? controller.fromDate.value : controller.toDate.value;
      return TextFormField(
        readOnly: true,
        controller: TextEditingController(text: date == null ? '' : intl.DateFormat('yyyy-MM-dd', 'ar').format(date)),
        onTap: () => controller.selectDate(context, isFromDate: isFromDate),
        decoration: InputDecoration(
          hintText: isFromDate ? 'من تاريخ' : 'إلى تاريخ',
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        style: const TextStyle(fontSize: 13),
      );
    });
  }

  // ==================== SpeedDial FAB ====================
  Widget _buildSpeedDial(FundController controller) {
    return Obx(() {
      final fund = controller.getSelectedFund();
      
      return SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        useRotationAnimation: true,
        animationCurve: Curves.fastOutSlowIn,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 8.0,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        spacing: 12,
        spaceBetweenChildren: 8,
        children: [
          if (fund != null) ...[
            SpeedDialChild(
              child: const Icon(Icons.download_rounded),
              label: 'إيداع في ${fund.name}',
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              onTap: () => Get.bottomSheet(
                TransactionFormBottomSheet(fundId: fund.id, fundType: fund.fundType, fundName: fund.name, initialIsDeposit: true),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              ),
            ),
            SpeedDialChild(
              child: const Icon(Icons.upload_rounded),
              label: 'سحب من ${fund.name}',
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              onTap: () => Get.bottomSheet(
                TransactionFormBottomSheet(fundId: fund.id, fundType: fund.fundType, fundName: fund.name, initialIsDeposit: false),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              ),
            ),
          ],
          SpeedDialChild(
            child: const Icon(Icons.swap_horiz_rounded),
            label: 'تحويل بين الصناديق',
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            onTap: () => Get.bottomSheet(
              TransferFormBottomSheet(initialSourceFundId: fund?.id),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
            ),
          ),
          SpeedDialChild(
            child: const Icon(Icons.add_home_work_outlined),
            label: _getAddLabel(),
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
            onTap: () {
              final type = _getCurrentType();
              Get.bottomSheet(
                FundFormBottomSheet(fundType: type),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
          ),
        ],
      );
    });
  }

  FundType _getCurrentType() {
    switch (_tabController.index) {
      case 0: return FundType.cash;
      case 1: return FundType.bank;
      case 2: return FundType.transfer;
      default: return FundType.cash;
    }
  }

  String _getAddLabel() {
    switch (_tabController.index) {
      case 0: return 'إضافة صندوق نقدي';
      case 1: return 'إضافة حساب بنكي';
      case 2: return 'إضافة شركة حوالات';
      default: return 'إضافة صندوق فرعي';
    }
  }

  // ==================== إدارة الصناديق (تعديل/حذف) ====================
  void _showFundManagementSheet(BuildContext context, FundModel fund) {
    // منع تعديل/حذف الصندوق الرئيسي (النقدي) الافتراضي إذا لزم الأمر
    // هنا سنسمح للكل ولكن نضع تحذير
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Text('إدارة ${fund.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.blue),
              title: const Text('تعديل البيانات'),
              subtitle: const Text('تغيير الاسم أو رقم الحساب'),
              onTap: () {
                Get.back();
                Get.bottomSheet(
                  FundFormBottomSheet(fundType: fund.fundType, fundToEdit: fund),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                );
              },
            ),
            if (fund.id != 1) // لا نسمح بحذف صندوق الكاش الرئيسي
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('حذف / إخفاء الصندوق'),
                subtitle: const Text('سيتم التعطيل إذا وجدت حركات مسجلة'),
                onTap: () {
                  Get.back();
                  _showDeleteConfirmation(fund);
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(FundModel fund) {
    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف/تعطيل ${fund.name}؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Get.back();
              controller.handleFundDeletion(fund.id);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // ==================== طباعة ====================
  void _showPrintDialog(FundController controller) {
    Get.dialog(
      DateRangePickerDialog(
        onConfirm: (from, to) async {
          try {
            Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
            final fund = controller.getSelectedFund();
            final fundId = fund?.id ?? 1;
            final reportData = await controller.repository.generateFundFlowReportData(fundId: fundId, from: from, to: to);
            if (Get.isDialogOpen!) Get.back();
            
            final List<Map<String, dynamic>> txList = (reportData['transactions'] as List<FundTransactionModel>)
                .map((t) => {
                  ...t.toMap(),
                  'transactionDate': intl.DateFormat('yyyy-MM-dd HH:mm').format(t.transactionDate),
                }).toList();

            await FundPdfService.printFundTransactions(
              txList,
              fundName: fund?.name,
              openingBalance: (reportData['openingBalance'] as num?)?.toDouble() ?? 0.0,
              dateRange: '${intl.DateFormat('yyyy-MM-dd').format(from)} - ${intl.DateFormat('yyyy-MM-dd').format(to)}'
            );
          } catch (e) {
            if (Get.isDialogOpen!) Get.back();
            Get.snackbar('خطأ', 'فشل في إنشاء التقرير: $e');
          }
        },
      ),
    );
  }
}