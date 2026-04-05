import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ehab_company_admin/features/fund/presentation/controllers/fund_controller.dart';
import 'package:ehab_company_admin/features/warehouses/presentation/controllers/settlement_controller.dart';
import 'package:ehab_company_admin/features/units/presentation/controllers/unit_controller.dart';
import 'package:ehab_company_admin/features/units/data/models/unit_model.dart';
import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';

class ManualSettlementScreen extends StatefulWidget {
  const ManualSettlementScreen({super.key});

  @override
  State<ManualSettlementScreen> createState() => _ManualSettlementScreenState();
}

class _ManualSettlementScreenState extends State<ManualSettlementScreen> {
  final SettlementController _controller = Get.find<SettlementController>();
  final FundController _fundController = Get.find<FundController>();
  final UnitController _unitController = Get.find<UnitController>();
  final CustomerController _customerController = Get.find<CustomerController>();

  final TextEditingController _notesController = TextEditingController();

  bool _isStockCleared = false;
  
  // تتبع المربعات المفتوحة للحسابات المالية لكل منتج
  final Map<int, bool> _isExpanded = {};
  
  // تتبع الوحدات المختارة للإدخال لكل منتج
  final Map<int, int> _selectedSoldUnitId = {};
  final Map<int, int> _selectedReturnedUnitId = {};
  
  // تتبع طريقة الدفع المختارة حالياً لكل منتج (للعرض فقط)
  final Map<int, String> _itemPaymentMode = {}; // 'cash', 'bank', 'transfer', 'credit'
  
  // تتبع القيم النصية المدخلة لتجنب المسح عند تغيير الوحدة
  final Map<int, String> _inputSoldValues = {};
  final Map<int, String> _inputReturnedValues = {};

  @override
  void initState() {
    super.initState();
    _customerController.fetchAllCustomers();
    // التأكد من تحميل الصناديق
    _fundController.loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedRep = _controller.selectedWarehouse.value;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor, theme.primaryColor.withBlue(100)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      selectedRep?.salesRepName ?? "المندوب",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    Text(
                      'تسوية مديونية وعهدة ميدانية',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            title: const Text('مركـز التسويـة', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            centerTitle: true,
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: Obx(() {
              if (_controller.isLoading.value) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              final itemsToShow = _controller.currentStock.where((item) {
                final pid = item['productId'];
                final initial = (item['quantity'] as num).toDouble();
                final entry = _controller.entryData[pid] ?? {};
                final sold = (entry['sold'] ?? 0.0) as double;
                final returned = (entry['returned'] ?? 0.0) as double;
                double remaining = initial - sold - returned;
                if (remaining <= 0.0001 && sold <= 0) return false;
                return true;
              }).toList();

              if (itemsToShow.isEmpty) {
                return SliverFillRemaining(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade200),
                      const SizedBox(height: 16),
                      Text('تمت تسوية كافة العهـدة بنجاح', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = itemsToShow[index];
                    final productId = item['productId'];
                    return _buildPremiumProductCard(theme, item, productId);
                  },
                  childCount: itemsToShow.length,
                ),
              );
            }),
          ),

          SliverToBoxAdapter(child: _buildFinalOptions(theme)),
          const SliverPadding(padding: EdgeInsets.only(bottom: 200)),
        ],
      ),
      bottomSheet: Obx(() => _buildNavigationFooter(theme)),
    );
  }

  Widget _buildPremiumProductCard(ThemeData theme, dynamic item, int productId) {
    final entry = _controller.entryData[productId]!;
    final isValid = _controller.isItemValid(productId);
    final isPayComplete = _controller.isItemPaymentComplete(productId);
    final initial = (item['quantity'] as num).toDouble();
    final unitString = _unitController.formatSmartQuantity(item['unitId'], initial);
    final sold = (entry['sold'] as double);
    final salePrice = (item['salePrice'] as num).toDouble();
    final expectedAmount = sold * salePrice;
    
    final expanded = _isExpanded[productId] ?? false;
    final mode = _itemPaymentMode[productId] ?? 'none';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
        ],
        border: Border.all(
          color: !isValid ? Colors.red.shade200 : (!isPayComplete && sold > 0 ? Colors.orange.shade200 : Colors.white),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // Head
            _buildCardHead(item, unitString, theme),
            
            if (!isValid) _buildErrorStrip('تحذير: الكمية المدخلة تجاوزت عهدة المندوب!'),

            // Units & Quantities
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: _buildQtySection(productId, item, theme),
            ),

            if (sold > 0) ...[
              _buildModernSummaryBar(expectedAmount, isPayComplete, productId, theme),
              
              const SizedBox(height: 12),
              // Payment Selection
              _buildPaymentModeSelector(productId, mode, theme),
              
              if (mode != 'none')
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: _buildSelectedPaymentForm(productId, mode, theme),
                ),
              
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardHead(dynamic item, String unitString, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey.shade50.withOpacity(0.5),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: Icon(Icons.inventory_2, color: theme.primaryColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['productName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('العهدة الحالية: $unitString', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${item['salePrice']?.toStringAsFixed(2)}', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
              const Text('ريال / وحدة', style: TextStyle(color: Colors.grey, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtySection(int productId, dynamic item, ThemeData theme) {
    final levels = _unitController.getUnitLevels(item['unitId']);
    if (!_selectedSoldUnitId.containsKey(productId)) {
      _selectedSoldUnitId[productId] = levels.first.id!;
      _selectedReturnedUnitId[productId] = levels.first.id!;
    }

    return Column(
      children: [
        _buildAdvancedQtyRow('الكمية المباعة', productId, levels, true, theme.primaryColor),
        const SizedBox(height: 20),
        _buildAdvancedQtyRow('الكمية المرتجعة', productId, levels, false, Colors.orange),
      ],
    );
  }

  Widget _buildAdvancedQtyRow(String label, int productId, List<UnitModel> levels, bool isSold, Color color) {
    final activeUnitId = isSold ? _selectedSoldUnitId[productId] : _selectedReturnedUnitId[productId];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: levels.map((u) {
                final isSelected = activeUnitId == u.id;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSold) _selectedSoldUnitId[productId] = u.id!;
                      else _selectedReturnedUnitId[productId] = u.id!;
                    });
                    _recalculateQty(productId, isSold, isSold ? (_inputSoldValues[productId] ?? '0') : (_inputReturnedValues[productId] ?? '0'), levels);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(u.name, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'أدخل الرقم هنا',
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: color, width: 2)),
          ),
          onChanged: (v) {
            if (isSold) _inputSoldValues[productId] = v;
            else _inputReturnedValues[productId] = v;
            _recalculateQty(productId, isSold, v, levels);
          },
        ),
      ],
    );
  }

  void _recalculateQty(int productId, bool isSold, String val, List<UnitModel> levels) {
    final qty = double.tryParse(val) ?? 0;
    final unitId = isSold ? _selectedSoldUnitId[productId] : _selectedReturnedUnitId[productId];
    double multiplier = 1.0;
    for (int i = 0; i < levels.length; i++) {
      if (levels[i].id == unitId) break;
      multiplier /= levels[i].conversionFactor;
    }
    final totalInBase = qty * multiplier;
    if (isSold) _controller.updateEntry(productId, sold: totalInBase);
    else _controller.updateEntry(productId, returned: totalInBase);
  }

  Widget _buildModernSummaryBar(double expected, bool complete, int productId, ThemeData theme) {
    final remaining = _controller.getItemRemainingToPay(productId);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: complete ? Colors.green.shade50 : Colors.orange.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade100), bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إجمالي قيمة المبيعات', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('${expected.toStringAsFixed(2)} ريال', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          if (remaining > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('المتبقي للتحصيل', style: TextStyle(fontSize: 10, color: Colors.orange)),
                Text('${remaining.toStringAsFixed(2)} ريال', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
              ],
            )
          else
            const Icon(Icons.verified, color: Colors.green, size: 28),
        ],
      ),
    );
  }

  Widget _buildPaymentModeSelector(int productId, String currentMode, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('اختر طريقة التحصيل:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildModeIcon(productId, 'cash', Icons.payments, 'نقد', Colors.green, currentMode),
              _buildModeIcon(productId, 'bank', Icons.account_balance, 'بنك', Colors.blue, currentMode),
              _buildModeIcon(productId, 'transfer', Icons.swap_horiz, 'حوالة', Colors.pink, currentMode),
              _buildModeIcon(productId, 'credit', Icons.timer, 'أجل', Colors.purple, currentMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeIcon(int productId, String mode, IconData icon, String label, Color color, String current) {
    final isSelected = current == mode;
    return GestureDetector(
      onTap: () => setState(() => _itemPaymentMode[productId] = mode),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
              boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)] : null,
            ),
            child: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSelectedPaymentForm(int productId, String mode, ThemeData theme) {
    final entry = _controller.entryData[productId]!;
    
    switch (mode) {
      case 'cash':
        return _buildPaymentInputRow(
          icon: Icons.payments,
          color: Colors.green,
          amountValue: entry['cashAmount'],
          onAmountChanged: (v) => _controller.updateEntry(productId, cashAmount: v),
          picker: _buildFundPickerUI('cash', entry['cashFundId'], (id) => _controller.updateEntry(productId, cashFundId: id)),
        );
      case 'bank':
        return Column(
          children: [
            _buildPaymentInputRow(
              icon: Icons.account_balance,
              color: Colors.blue,
              amountValue: entry['bankAmount'],
              onAmountChanged: (v) => _controller.updateEntry(productId, bankAmount: v),
              picker: _buildFundPickerUI('bank', entry['bankFundId'], (id) => _controller.updateEntry(productId, bankFundId: id)),
            ),
            const SizedBox(height: 10),
            _buildModernDetailsInput('رقم العملية / تفاصيل...', entry['bankDetails'], (v) => _controller.updateEntry(productId, bankDetails: v)),
          ],
        );
      case 'transfer':
        return Column(
          children: [
            _buildPaymentInputRow(
              icon: Icons.swap_horiz,
              color: Colors.pink,
              amountValue: entry['transferAmount'],
              onAmountChanged: (v) => _controller.updateEntry(productId, transferAmount: v),
              picker: _buildFundPickerUI('transfer', entry['transferFundId'], (id) => _controller.updateEntry(productId, transferFundId: id)),
            ),
            const SizedBox(height: 10),
            _buildModernDetailsInput('اسم المحول / شركة التحويل...', entry['transferDetails'], (v) => _controller.updateEntry(productId, transferDetails: v)),
          ],
        );
      case 'credit':
        return Column(
          children: [
            _buildPaymentInputRow(
              icon: Icons.timer,
              color: Colors.purple,
              amountValue: entry['creditAmount'],
              onAmountChanged: (v) => _controller.updateEntry(productId, creditAmount: v),
              picker: Row(
                children: [
                  _buildSubChoice('على المندوب', entry['creditTarget'] == 'rep', () => _controller.updateEntry(productId, creditTarget: 'rep'), Colors.purple),
                  const SizedBox(width: 10),
                  _buildSubChoice('على عميل', entry['creditTarget'] == 'customer', () => _controller.updateEntry(productId, creditTarget: 'customer'), Colors.purple),
                ],
              ),
            ),
            if (entry['creditTarget'] == 'customer')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildCustomerPickerUI(entry['customerId'], (id) => _controller.updateEntry(productId, customerId: id)),
              ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildPaymentInputRow({required IconData icon, required Color color, required double amountValue, required Function(double) onAmountChanged, required Widget picker}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: color, size: 20),
                  hintText: 'أدخل المبلغ المخصص...',
                  filled: true,
                  fillColor: color.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                onChanged: (v) => onAmountChanged(double.tryParse(v) ?? 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        picker,
      ],
    );
  }

  Widget _buildFundPickerUI(String type, int? selectedId, Function(int) onChanged) {
    return Obx(() {
      final funds = _fundController.subFunds.where((f) => f.fundType.toString().split('.').last.toLowerCase() == type).toList();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedId,
            isExpanded: true,
            hint: Text('اختر التحصيل لـ ($type)', style: const TextStyle(fontSize: 12)),
            items: funds.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
            onChanged: (v) => v != null ? onChanged(v) : null,
          ),
        ),
      );
    });
  }

  Widget _buildCustomerPickerUI(int? selectedId, Function(int) onChanged) {
    return Obx(() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedId,
            isExpanded: true,
            hint: const Text('اختر العميل المستلم للآجل...', style: TextStyle(fontSize: 12)),
            items: _customerController.filteredCustomers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => v != null ? onChanged(v) : null,
          ),
        ),
      );
    });
  }

  Widget _buildSubChoice(String label, bool selected, VoidCallback onTap, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: selected ? Colors.white : Colors.black87, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildModernDetailsInput(String hint, String? initial, Function(String) onChanged) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildErrorStrip(String msg) {
    return Container(
      width: double.infinity,
      color: Colors.red.shade400,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFinalOptions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                const Icon(Icons.cleaning_services, color: Colors.blue),
                const SizedBox(width: 15),
                const Expanded(child: Text('صفير العهدة (إرجاع المتبقي للمخزن)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Switch.adaptive(value: _isStockCleared, onChanged: (v) => setState(() => _isStockCleared = v)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'ملاحظات إضافية...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationFooter(ThemeData theme) {
    final canSubmit = _controller.areAllItemsValid;
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLargeStat('نـقداً', _controller.totalCashAmount, Colors.green),
              _buildLargeStat('بـنك', _controller.totalBankAmount + _controller.totalTransferAmount, Colors.blue),
              _buildLargeStat('آجـل', _controller.totalCreditAmount, Colors.purple),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: canSubmit ? () => _controller.submitSettlement(totalCredit: 0, amountPaid: 0, notes: _notesController.text, isStockCleared: _isStockCleared) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit ? theme.primaryColor : Colors.grey.shade400,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: Text(canSubmit ? 'إعتمـاد وتأكيـد التسوية' : 'يرجى إكمال تحصيل الأرصدة', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeStat(String label, double val, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        Text(val.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 20)),
      ],
    );
  }
}
