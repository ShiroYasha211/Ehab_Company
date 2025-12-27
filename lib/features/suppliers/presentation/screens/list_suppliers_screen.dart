// File: lib/features/suppliers/presentation/screens/list_suppliers_screen.dart

import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/screens/add_edit_supplier_screen.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/screens/supplier_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/supplier_pdf_service.dart';

class ListSuppliersScreen extends StatelessWidget {
  const ListSuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SupplierController controller = Get.find<SupplierController>();
    final searchController = TextEditingController(text: controller.searchQuery.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الموردين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'طباعة تقرير أرصدة الموردين',
            onPressed: () async {
              try {
                Get.dialog(
                  const Center(child: CircularProgressIndicator()),
                  barrierDismissible: false,
                );

                // جلب قائمة الموردين المرتبة من الـ Repository
                // هذا السطر سيعمل بشكل صحيح بعد إضافة الـ getter في الخطوة التالية
                final suppliers = await controller.repository.getSuppliersForReport();

                if (Get.isDialogOpen!) Get.back(); // إغلاق مؤشر التحميل

                // طباعة التقرير
                await SupplierPdfService.printSuppliersReport(suppliers);
              } catch (e) {
                if (Get.isDialogOpen!) Get.back();
                Get.snackbar('خطأ', 'فشل في إنشاء التقرير: $e');
              }

            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120.0),
          child: Column(
            children: [
              // شريط البحث
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) => controller.searchQuery.value = value,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو رقم الهاتف...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        controller.searchQuery.value = '';
                      },
                    )
                        : const SizedBox.shrink()),
                  ),
                ),
              ),
              // أزرار الفلترة
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Obx(() => SegmentedButton<SupplierFilter>(
                  segments: const [
                    ButtonSegment(value: SupplierFilter.all, label: Text('الكل')),
                    ButtonSegment(value: SupplierFilter.hasBalance, label: Text('لهم رصيد')),
                    ButtonSegment(value: SupplierFilter.noBalance, label: Text('رصيد صفري')),
                  ],
                  selected: {controller.currentFilter.value},
                  onSelectionChanged: (newSelection) {
                    controller.currentFilter.value = newSelection.first;
                  },
                )),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.isTrue) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.filteredSuppliers.isEmpty) {
            return const Center(child: Text('لا يوجد موردين يطابقون بحثك.', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: controller.filteredSuppliers.length,
            itemBuilder: (context, index) {
              final supplier = controller.filteredSuppliers[index];
              return SupplierCard(supplier: supplier); // استخدام ودجت البطاقة
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddEditSupplierScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ودجت منفصل لبطاقة المورد لجعل الكود أنظف
class SupplierCard extends StatelessWidget {
  final SupplierModel supplier;
  const SupplierCard({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    final hasBalance = supplier.balance > 0;
    final balanceColor = hasBalance ? Colors.orange.shade800 : Colors.green.shade700;
    final formatCurrency = NumberFormat.currency(locale: 'ar_SA', symbol: 'ريال');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: hasBalance ? balanceColor : Colors.transparent,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Get.to(() => SupplierDetailsScreen(supplier: supplier,));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                supplier.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الرصيد المتبقي:',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  Text(
                    formatCurrency.format(supplier.balance),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: balanceColor,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                    // --- بداية التعديل: أيقونات جديدة ---
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.phone, color: Colors.green.shade700, size: 20),
                      onPressed: () async {
                        final Uri url = Uri(scheme: 'tel', path: supplier.phone);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      tooltip: 'اتصال',
                    ),
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green.shade800, size: 22),
                      onPressed: () async {
                        final Uri url = Uri.parse('https://wa.me/${supplier.phone}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      tooltip: 'واتساب',
                    ),
                  ],
                  const Spacer(),
                  // --- نهاية التعديل ---
                  IconButton(
                    // --- بداية التعديل: أيقونة وتصحيح منطق الحذف ---
                    icon: FaIcon(FontAwesomeIcons.trashCan, color: Theme.of(context).colorScheme.error, size: 20),
                    onPressed: () {
                      // استدعاء الدالة مباشرة، وهي ستقوم بعرض الديالوج المناسب
                      Get.find<SupplierController>().deleteSupplier(supplier);
                    },
                    tooltip: 'حذف',
                    // --- نهاية التعديل ---
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
