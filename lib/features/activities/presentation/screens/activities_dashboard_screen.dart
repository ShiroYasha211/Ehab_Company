// File: lib/features/activities/presentation/screens/activities_dashboard_screen.dart

import 'package:ehab_company_admin/features/activities/presentation/widgets/advanced_filter_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../controllers/operations_controller.dart';
import '../../data/models/operation_model.dart';

class ActivitiesDashboardScreen extends StatelessWidget {
  const ActivitiesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final OperationsController controller = Get.put(OperationsController());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('إدارة العمليات والرقابة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.loadOperations(),
            tooltip: 'تحديث',
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {
              Get.bottomSheet(
                const AdvancedFilterBottomSheet(),
                isScrollControlled: true,
              );
            },
            tooltip: 'فلترة متقدمة',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildActiveFilters(controller),
          _buildHeaderStats(controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.operations.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: controller.operations.length,
                itemBuilder: (context, index) {
                  final operation = controller.operations[index];
                  return _buildOperationItem(context, operation, controller);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(OperationsController controller) {
    return Obx(() {
      if (!controller.isAnyFilterApplied()) return const SizedBox.shrink();
      return Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (controller.selectedTypes.isNotEmpty)
              ...controller.selectedTypes.map((t) => _buildFilterChip(
                label: 'النوع: ${_getTypeLabel(t)}',
                onDeleted: () {
                  controller.selectedTypes.remove(t);
                  controller.loadOperations();
                },
              )),
            if (controller.selectedEmployee.value.isNotEmpty)
              _buildFilterChip(
                label: 'الموظف: ${controller.selectedEmployee.value}',
                onDeleted: () {
                  controller.selectedEmployee.value = "";
                  controller.loadOperations();
                },
              ),
            if (controller.minAmount.value != null)
              _buildFilterChip(
                label: 'من: ${controller.minAmount.value}',
                onDeleted: () {
                  controller.minAmount.value = null;
                  controller.loadOperations();
                },
              ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip({required String label, required VoidCallback onDeleted}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onDeleted: onDeleted,
        deleteIcon: const Icon(Icons.close, size: 14),
        backgroundColor: Colors.blue.shade50,
      ),
    );
  }

  String _getTypeLabel(OperationType type) {
    switch (type) {
      case OperationType.sale: return 'بيع';
      case OperationType.purchase: return 'شراء';
      case OperationType.expense: return 'مصروف';
      case OperationType.transfer: return 'تحويل';
      case OperationType.settlement: return 'تسوية';
      case OperationType.returnSale: return 'مرتجع بيع';
      case OperationType.returnPurchase: return 'مرتجع شراء';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('لا توجد عمليات تطابق هذه الفلاتر', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(OperationsController controller) {
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
        final totalSales = controller.operations
            .where((o) => o.type == OperationType.sale)
            .fold(0.0, (sum, o) => sum + o.amount);
        
        final totalExpenses = controller.operations
            .where((o) => o.type == OperationType.expense)
            .fold(0.0, (sum, o) => sum + o.amount);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('إجمالي المبيعات', totalSales.toStringAsFixed(0), Colors.green),
            _buildStatItem('إجمالي المصاريف', totalExpenses.toStringAsFixed(0), Colors.red),
            _buildStatItem('عدد العمليات', controller.operations.length.toString(), Colors.blue),
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

  Widget _buildOperationItem(BuildContext context, OperationModel operation, OperationsController controller) {
    final String timeStr = intl.DateFormat('hh:mm a').format(operation.date);
    final String dateStr = intl.DateFormat('MM/dd').format(operation.date);

    IconData icon;
    Color color;
    switch (operation.type) {
      case OperationType.sale:
        icon = Icons.shopping_cart_checkout_rounded;
        color = Colors.green;
        break;
      case OperationType.purchase:
        icon = Icons.shopping_bag_outlined;
        color = Colors.blue;
        break;
      case OperationType.expense:
        icon = Icons.money_off_csred_rounded;
        color = Colors.red;
        break;
      case OperationType.transfer:
        icon = Icons.swap_horiz_rounded;
        color = Colors.orange;
        break;
      default:
        icon = Icons.receipt_long_rounded;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => controller.showOperationDetails(operation),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            operation.typeLabel, 
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          operation.amount.toStringAsFixed(2),
                          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      operation.details ?? 'لا توجد تفاصيل', 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  operation.userName ?? 'النظام', 
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text('$dateStr | $timeStr', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
