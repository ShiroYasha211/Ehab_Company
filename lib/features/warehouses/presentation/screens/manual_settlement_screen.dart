import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';
import 'package:ehab_company_admin/features/fund/presentation/controllers/fund_controller.dart';
import 'package:ehab_company_admin/features/units/data/models/unit_model.dart';
import 'package:ehab_company_admin/features/units/presentation/controllers/unit_controller.dart';
import 'package:ehab_company_admin/features/warehouses/data/models/custody_model.dart';
import 'package:ehab_company_admin/features/warehouses/data/repositories/custody_repository.dart';
import 'package:ehab_company_admin/features/warehouses/presentation/controllers/settlement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ManualSettlementScreen extends StatefulWidget {
  const ManualSettlementScreen({super.key});

  @override
  State<ManualSettlementScreen> createState() => _ManualSettlementScreenState();
}

class _ManualSettlementScreenState extends State<ManualSettlementScreen> {
  final SettlementController _controller = Get.find<SettlementController>();
  final FundController _fundController = Get.find<FundController>();
  final UnitController _unitController = Get.find<UnitController>();
  final CustodyRepository _repo = CustodyRepository();

  final _receivedController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  final _debtAmountController = TextEditingController();
  final _debtNotesController = TextEditingController();
  final _debtTransferNumberController = TextEditingController();
  final _debtSenderNameController = TextEditingController();
  final _debtReceiverNameController = TextEditingController();
  final _debtTransferCompanyController = TextEditingController();
  final _debtBankNameController = TextEditingController();
  final _debtBankReferenceController = TextEditingController();
  final Map<int, TextEditingController> _soldControllers = {};
  final Map<int, TextEditingController> _returnedControllers = {};

  String _debtPaymentMethod = 'cash';
  int? _debtFundId;
  bool _isDebtSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fundController.loadAllData();
  }

  @override
  void dispose() {
    for (final c in _soldControllers.values) {
      c.dispose();
    }
    for (final c in _returnedControllers.values) {
      c.dispose();
    }
    _receivedController.dispose();
    _notesController.dispose();
    _debtAmountController.dispose();
    _debtNotesController.dispose();
    _debtTransferNumberController.dispose();
    _debtSenderNameController.dispose();
    _debtReceiverNameController.dispose();
    _debtTransferCompanyController.dispose();
    _debtBankNameController.dispose();
    _debtBankReferenceController.dispose();
    super.dispose();
  }

  double get _receivedAmount =>
      double.tryParse(_receivedController.text) ?? 0.0;
  double get _debtAmount => double.tryParse(_debtAmountController.text) ?? 0.0;

  TextEditingController _soldCtrl(int productId) =>
      _soldControllers.putIfAbsent(
        productId,
        () => TextEditingController(
          text: _controller.getSoldQty(productId) == 0
              ? ''
              : _controller.getSoldQty(productId).toStringAsFixed(2),
        ),
      );

  TextEditingController _returnedCtrl(int productId) =>
      _returnedControllers.putIfAbsent(
        productId,
        () => TextEditingController(
          text: _controller.getReturnedQty(productId) == 0
              ? ''
              : _controller.getReturnedQty(productId).toStringAsFixed(2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final warehouse = _controller.selectedWarehouse.value;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text('تسوية ${warehouse?.salesRepName ?? ""}'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'تسوية العهدة'),
              Tab(text: 'تسوية المديونية'),
            ],
          ),
        ),
        body: TabBarView(children: [_buildCustodyTab(), _buildDebtTab()]),
      ),
    );
  }

  Widget _buildCustodyTab() {
    return Obx(() {
      final warehouse = _controller.selectedWarehouse.value;
      final products = _controller.currentProducts;
      final newBalance =
          (warehouse?.balance ?? 0.0) +
          (_controller.totalSoldValue - _receivedAmount);

      if (_controller.isLoading.value && products.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: _topSummary(context, [
              ('المديونية السابقة', warehouse?.balance ?? 0.0),
              ('قيمة المباع', _controller.totalSoldValue),
              ('المديونية الجديدة', newBalance),
            ]),
          ),
          if (products.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'لا توجد عهدة حالية على هذا المندوب. استخدم تاب تسوية المديونية إذا كان عليه دين فقط.',
                  ),
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index.isOdd) return const SizedBox(height: 10);
                  return _productCard(products[index ~/ 2]);
                }, childCount: products.length * 2 - 1),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _custodyFooter(),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildDebtTab() {
    return Obx(() {
      final warehouse = _controller.selectedWarehouse.value;
      final balance = warehouse?.balance ?? 0.0;
      final isPayout = balance < -0.0001;
      final absBalance = balance.abs();
      final nextBalance = isPayout
          ? balance + _debtAmount
          : balance - _debtAmount;
      final methods = {
        'cash': FundType.cash,
        'bank': FundType.bank,
        'transfer': FundType.transfer,
      };
      final funds = _fundController.getFundsByType(
        methods[_debtPaymentMethod] ?? FundType.cash,
      );
      final safeFundId = funds.any((f) => f.id == _debtFundId)
          ? _debtFundId
          : null;

      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          _topSummary(context, [
            (
              isPayout ? 'الرصيد الدائن الحالي' : 'المديونية الحالية',
              absBalance,
            ),
            (isPayout ? 'مبلغ السداد للمندوب' : 'مبلغ التحصيل', _debtAmount),
            ('الرصيد بعد العملية', nextBalance.abs()),
          ], alt: true),
          const SizedBox(height: 16),
          if (balance.abs() <= 0.0001)
            const _SimpleCard(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'لا توجد مديونية أو رصيد دائن على هذا المندوب حالياً.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            _SimpleCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _numberField(
                      _debtAmountController,
                      isPayout ? 'مبلغ السداد للمندوب' : 'مبلغ التحصيل',
                      setStateRefresh: true,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _debtPaymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'طريقة التحصيل',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('نقد')),
                        DropdownMenuItem(value: 'bank', child: Text('بنك')),
                        DropdownMenuItem(
                          value: 'transfer',
                          child: Text('حوالة'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _debtPaymentMethod = v;
                          _debtFundId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: safeFundId,
                      decoration: const InputDecoration(
                        labelText: 'الصندوق / الحساب',
                        border: OutlineInputBorder(),
                      ),
                      items: funds
                          .map(
                            (f) => DropdownMenuItem<int>(
                              value: f.id,
                              child: Text(f.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _debtFundId = v),
                    ),
                    const SizedBox(height: 12),
                    if (_debtPaymentMethod == 'bank') ...[
                      TextField(
                        controller: _debtTransferNumberController,
                        decoration: const InputDecoration(
                          labelText: 'رقم العملية / المرجع',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _debtBankNameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم البنك',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _debtBankReferenceController,
                        decoration: const InputDecoration(
                          labelText: 'المرجع البنكي',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    if (_debtPaymentMethod == 'transfer') ...[
                      TextField(
                        controller: _debtTransferNumberController,
                        decoration: const InputDecoration(
                          labelText: 'رقم الحوالة / المرجع',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _debtTransferCompanyController,
                        decoration: const InputDecoration(
                          labelText: 'الشركة / الجهة',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _debtSenderNameController,
                        decoration: InputDecoration(
                          labelText: isPayout ? 'اسم المرسل' : 'اسم المرسل',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _debtReceiverNameController,
                        decoration: InputDecoration(
                          labelText: isPayout ? 'اسم المستلم' : 'اسم المستلم',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _debtNotesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات السداد',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _summaryBox([
                      (
                        isPayout ? 'الرصيد الدائن الحالي' : 'المديونية الحالية',
                        absBalance,
                      ),
                      (
                        isPayout ? 'مبلغ السداد للمندوب' : 'مبلغ التحصيل',
                        _debtAmount,
                      ),
                      ('الرصيد بعد العملية', nextBalance.abs()),
                    ]),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isDebtSubmitting
                            ? null
                            : _submitDebtPayment,
                        icon: _isDebtSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.account_balance_wallet_outlined),
                        label: Text(
                          _isDebtSubmitting
                              ? 'جاري التنفيذ...'
                              : isPayout
                              ? 'اعتماد سداد للمندوب'
                              : 'اعتماد تحصيل من المندوب',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _productCard(CustodyProductSummary product) {
    final theme = Theme.of(context);
    final units = _controller.getAllowedUnits(product.productId);
    return _SimpleCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.productName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              _controller.getProductPricingHint(product.productId),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Text(
              'العهدة الحالية: ${_unitController.formatSmartQuantity(product.unitId, product.quantity)}',
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _qtyRow(
              label: 'المباع',
              controller: _soldCtrl(product.productId),
              unitId: _controller.getSoldUnitId(product.productId),
              units: units,
              color: Colors.green,
              onChanged: (v) {
                _controller.updateEntry(
                  product.productId,
                  sold: double.tryParse(v) ?? 0.0,
                );
                setState(() {});
              },
              onUnitChanged: (v) {
                if (v == null) return;
                _controller.updateEntryUnit(product.productId, soldUnitId: v);
                setState(() {});
              },
            ),
            const SizedBox(height: 10),
            _qtyRow(
              label: 'المرتجع',
              controller: _returnedCtrl(product.productId),
              unitId: _controller.getReturnedUnitId(product.productId),
              units: units,
              color: Colors.orange,
              onChanged: (v) {
                _controller.updateEntry(
                  product.productId,
                  returned: double.tryParse(v) ?? 0.0,
                );
                setState(() {});
              },
              onUnitChanged: (v) {
                if (v == null) return;
                _controller.updateEntryUnit(
                  product.productId,
                  returnedUnitId: v,
                );
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _miniInfo(
                    'المتبقي',
                    _unitController.formatSmartQuantity(
                      product.unitId,
                      _controller.getRemainingQty(product.productId),
                    ),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _miniInfo(
                    'قيمة المباع',
                    _controller
                        .getItemSoldValue(product.productId)
                        .toStringAsFixed(2),
                    Colors.purple,
                  ),
                ),
              ],
            ),
            if (!_controller.isItemValid(product.productId)) ...[
              const SizedBox(height: 10),
              Text(
                'الكمية المدخلة تتجاوز العهدة الحالية بعد التحويل بين الوحدات.',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _qtyRow({
    required String label,
    required TextEditingController controller,
    required int? unitId,
    required List<UnitModel> units,
    required Color color,
    required ValueChanged<String> onChanged,
    required ValueChanged<int?> onUnitChanged,
  }) {
    final unitItems = units
        .map((u) => DropdownMenuItem<int>(value: u.id, child: Text(u.name)))
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final field = TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: color.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: onChanged,
        );
        final unit = DropdownButtonFormField<int>(
          value: unitItems.any((i) => i.value == unitId) ? unitId : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'الوحدة',
            filled: true,
            fillColor: color.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          items: unitItems,
          onChanged: unitItems.isEmpty ? null : onUnitChanged,
        );
        if (constraints.maxWidth < 420) {
          return Column(children: [field, const SizedBox(height: 8), unit]);
        }
        return Row(
          children: [
            Expanded(flex: 3, child: field),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: unit),
          ],
        );
      },
    );
  }

  Widget _custodyFooter() {
    return _SimpleCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _numberField(
              _receivedController,
              'المبلغ المستلم الآن',
              setStateRefresh: true,
            ),
            const SizedBox(height: 12),
            Obx(() {
              final methods = {
                'cash': FundType.cash,
                'bank': FundType.bank,
                'transfer': FundType.transfer,
              };
              final funds = _fundController.getFundsByType(
                methods[_controller.paymentMethod.value] ?? FundType.cash,
              );
              final selectedId = _controller.selectedFundId.value;
              final safeId = funds.any((f) => f.id == selectedId)
                  ? selectedId
                  : null;
              return Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _controller.paymentMethod.value,
                    decoration: const InputDecoration(
                      labelText: 'طريقة التحصيل',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('نقد')),
                      DropdownMenuItem(value: 'bank', child: Text('بنك')),
                      DropdownMenuItem(value: 'transfer', child: Text('حوالة')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      _controller.paymentMethod.value = v;
                      _controller.selectedFundId.value = null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: safeId,
                    decoration: const InputDecoration(
                      labelText: 'الصندوق / الحساب',
                      border: OutlineInputBorder(),
                    ),
                    items: funds
                        .map(
                          (f) => DropdownMenuItem<int>(
                            value: f.id,
                            child: Text(f.name),
                          ),
                        )
                        .toList(),
                    onChanged: _receivedAmount > 0
                        ? (v) => _controller.selectedFundId.value = v
                        : null,
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات التسوية',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final previous =
                  _controller.selectedWarehouse.value?.balance ?? 0.0;
              final difference = _controller.totalSoldValue - _receivedAmount;
              return _summaryBox([
                ('إجمالي قيمة المباع', _controller.totalSoldValue),
                ('المبلغ المستلم', _receivedAmount),
                ('فرق التسوية', difference),
                ('المديونية الجديدة', previous + difference),
              ]);
            }),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton.icon(
                  onPressed:
                      _controller.isLoading.value ||
                          !_controller.areAllItemsValid
                      ? null
                      : () => _controller.submitSettlement(
                          receivedAmount: _receivedAmount,
                          notes: _notesController.text.trim().isEmpty
                              ? null
                              : _notesController.text.trim(),
                        ),
                  icon: _controller.isLoading.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _controller.isLoading.value
                        ? 'جاري الاعتماد...'
                        : 'اعتماد تسوية العهدة',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitDebtPayment() async {
    final warehouse = _controller.selectedWarehouse.value;
    final balance = warehouse?.balance ?? 0.0;
    final isPayout = balance < -0.0001;
    final absBalance = balance.abs();
    if (warehouse == null) return;
    if (_debtAmount <= 0) {
      Get.snackbar(
        'خطأ',
        'أدخل مبلغ سداد صحيح.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (_debtAmount > absBalance + 0.0001) {
      Get.snackbar(
        'خطأ',
        isPayout
            ? 'مبلغ السداد أكبر من الرصيد الدائن الحالي.'
            : 'مبلغ التحصيل أكبر من المديونية الحالية.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (_debtFundId == null) {
      Get.snackbar(
        'خطأ',
        'اختر الصندوق أو الحساب المالي.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    try {
      setState(() => _isDebtSubmitting = true);
      final result = await _repo.collectDebtPayment(
        warehouseId: warehouse.id!,
        amount: _debtAmount,
        fundId: _debtFundId!,
        paymentMethod: _debtPaymentMethod,
        isPayout: isPayout,
        transferNumber: _debtTransferNumberController.text.trim().isEmpty
            ? null
            : _debtTransferNumberController.text.trim(),
        senderName: _debtSenderNameController.text.trim().isEmpty
            ? null
            : _debtSenderNameController.text.trim(),
        receiverName: _debtReceiverNameController.text.trim().isEmpty
            ? null
            : _debtReceiverNameController.text.trim(),
        transferCompany: _debtTransferCompanyController.text.trim().isEmpty
            ? null
            : _debtTransferCompanyController.text.trim(),
        referenceType: _debtPaymentMethod == 'transfer'
            ? 'HAWALA'
            : _debtPaymentMethod == 'bank'
            ? 'BANK'
            : 'CASH',
        bankName: _debtBankNameController.text.trim().isEmpty
            ? null
            : _debtBankNameController.text.trim(),
        bankReference: _debtBankReferenceController.text.trim().isEmpty
            ? null
            : _debtBankReferenceController.text.trim(),
        notes: _debtNotesController.text.trim().isEmpty
            ? null
            : _debtNotesController.text.trim(),
      );
      await _controller.selectWarehouse(
        warehouse.copyWith(balance: result.newBalance),
      );
      _debtAmountController.clear();
      _debtNotesController.clear();
      _debtTransferNumberController.clear();
      _debtSenderNameController.clear();
      _debtReceiverNameController.clear();
      _debtTransferCompanyController.clear();
      _debtBankNameController.clear();
      _debtBankReferenceController.clear();
      setState(() => _debtFundId = null);
      Get.snackbar(
        'نجاح',
        '${isPayout ? 'تم تسجيل سداد للمندوب' : 'تم تسجيل تحصيل من المندوب'}. الرصيد الجديد: ${result.newBalance.toStringAsFixed(2)}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isDebtSubmitting = false);
    }
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool setStateRefresh = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.payments_outlined),
        border: const OutlineInputBorder(),
      ),
      onChanged: setStateRefresh ? (_) => setState(() {}) : null,
    );
  }

  Widget _topSummary(
    BuildContext context,
    List<(String, double)> values, {
    bool alt = false,
  }) {
    final theme = Theme.of(context);
    final colors = alt
        ? [Colors.teal.shade500, Colors.teal.shade700]
        : [theme.primaryColor, theme.primaryColor.withBlue(160)];
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: values
            .map(
              (item) => Expanded(
                child: Column(
                  children: [
                    Text(
                      item.$2.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _summaryBox(List<(String, double)> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row.$1),
                    Text(
                      row.$2.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _miniInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SimpleCard extends StatelessWidget {
  final Widget child;

  const _SimpleCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
