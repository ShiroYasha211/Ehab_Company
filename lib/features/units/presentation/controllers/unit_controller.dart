import 'package:ehab_company_admin/features/units/data/models/unit_model.dart';
import 'package:ehab_company_admin/features/units/data/repositories/unit_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ehab_company_admin/features/activities/data/models/activity_model.dart';
import 'package:ehab_company_admin/features/activities/presentation/controllers/activity_controller.dart';

class UnitController extends GetxController {
  final UnitRepository _repository = UnitRepository();
  final ActivityController _activityController = Get.find<ActivityController>();

  final RxList<UnitModel> units = <UnitModel>[].obs; // السلاسل (الوحدات الجذرية) فقط للعرض
  final RxList<UnitModel> allUnits = <UnitModel>[].obs; // كافة مستويات الوحدات للعمليات الحسابية
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllUnits();
  }

  Future<void> fetchAllUnits() async {
    try {
      isLoading(true);
      final fetched = await _repository.getAllUnits();
      allUnits.clear();
      allUnits.addAll(fetched);

      // تحديد المعرفات التي تعتبر وحدات تابعة (Children)
      final childIds = fetched.map((u) => u.childUnitId).where((id) => id != null).toSet();
      
      // إظهار الوحدات "الجذرية" فقط في قائمة الإدارة
      units.assignAll(fetched.where((u) => !childIds.contains(u.id)).toList());
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب الوحدات: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> addNewUnit({
    required String name,
    int? childUnitId,
    double? conversionFactor,
  }) async {
    if (name.isEmpty) {
      Get.snackbar('خطأ', 'اسم الوحدة لا يمكن أن يكون فارغًا');
      return;
    }
    try {
      await _repository.addUnit(UnitModel(
        name: name,
        childUnitId: childUnitId,
        conversionFactor: conversionFactor ?? 1.0,
      ));

      // تسجيل النشاط
      await _activityController.logAction(
        action: 'إضافة وحدة قياس',
        details: 'تم إضافة وحدة قياس جديدة باسم "$name"',
        type: ActivityType.inventory,
      );

      await fetchAllUnits();
      Get.snackbar('نجاح', 'تمت إضافة الوحدة بنجاح',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إضافة الوحدة: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// حفظ أو تحديث سلسلة وحدات كاملة
  Future<void> saveUnitChain(List<Map<String, dynamic>> levels, {int? originalRootId}) async {
    if (levels.isEmpty) return;

    try {
      isLoading(true);
      
      // 1. تحديد المعرفات الأصلية للسلسلة (إذا كنا في وضع التعديل)
      Set<int> originalIds = {};
      if (originalRootId != null) {
        UnitModel? curr = allUnits.firstWhereOrNull((u) => u.id == originalRootId);
        while (curr != null) {
          originalIds.add(curr.id!);
          if (curr.childUnitId == null) break;
          curr = allUnits.firstWhereOrNull((u) => u.id == curr!.childUnitId);
        }
      }

      int? lastSavedId;
      Set<int> updatedIds = {};
      
      // 2. معالجة المستويات من الأصغر للأكبر
      for (int i = levels.length - 1; i >= 0; i--) {
        final level = levels[i];
        final unit = UnitModel(
          id: level['id'], // قد يكون null في حال الإضافة
          name: level['name'].text,
          childUnitId: lastSavedId,
          conversionFactor: i == levels.length - 1 ? 1.0 : double.tryParse(level['factor'].text) ?? 1.0,
        );
        
        if (unit.id != null) {
          await _repository.updateUnit(unit);
          lastSavedId = unit.id;
          updatedIds.add(unit.id!);
        } else {
          lastSavedId = await _repository.addUnit(unit);
        }
      }
      
      // 3. حذف الوحدات التي تمت إزالتها من السلسلة أثناء التعديل
      if (originalIds.isNotEmpty) {
        final idsToDelete = originalIds.difference(updatedIds);
        for (var id in idsToDelete) {
          await _repository.deleteUnit(id);
        }
      }
      
      await fetchAllUnits();

      // تسجيل النشاط
      final String rootName = levels.isNotEmpty ? levels[0]['name'].text : 'غير معروفة';
      await _activityController.logAction(
        action: 'تعديل سلسلة وحدات',
        details: 'تم تحديث سلسلة الوحدات المرتبطة بـ "$rootName" (إجمالي المستويات: ${levels.length})',
        type: ActivityType.inventory,
      );

      Get.back(); // إغلاق الدايلوج تلقائياً
      Get.snackbar('نجاح', 'تم حفظ التعديلات بنجاح',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حفظ السلسلة: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateUnit(UnitModel unit) async {
    try {
      await _repository.updateUnit(unit);
      await fetchAllUnits();
      Get.snackbar('نجاح', 'تم تحديث البيانات بنجاح',
          backgroundColor: Colors.blue, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في التعديل: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// حذف السلسلة بالكامل تتابعياً
  Future<void> removeUnit(int id) async {
    try {
      isLoading(true);
      final unit = allUnits.firstWhereOrNull((u) => u.id == id);
      await _deleteChainRecursive(id);
      
      // تسجيل النشاط
      await _activityController.logAction(
        action: 'حذف سلسلة وحدات',
        details: 'تم حذف وحدة القياس "${unit?.name ?? "غير معروفة"}" وكافة توابعها.',
        type: ActivityType.inventory,
      );

      await fetchAllUnits();
      // لا نغلق الدايلوج هنا لأنه حذف من القائمة الرئيسية عادة
      Get.snackbar('نجاح', 'تم حذف السلسلة بالكامل بنجاح', backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حذف السلسلة: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading(false);
    }
  }

  Future<void> _deleteChainRecursive(int id) async {
    final unit = allUnits.firstWhereOrNull((u) => u.id == id);
    if (unit == null) return;
    
    // حذف الوحدة التابعة أولاً إذا وجدت
    if (unit.childUnitId != null) {
      await _deleteChainRecursive(unit.childUnitId!);
    }
    
    await _repository.deleteUnit(id);
  }

  /// جلب مستويات السلسلة كقائمة لتعبئة واجهة التعديل
  List<Map<String, dynamic>> getChainList(int rootId) {
    List<Map<String, dynamic>> levels = [];
    UnitModel? current = allUnits.firstWhereOrNull((u) => u.id == rootId);
    
    while (current != null) {
      levels.add({
        'id': current.id,
        'name': TextEditingController(text: current.name),
        'factor': TextEditingController(text: current.conversionFactor.toString()),
      });
      
      if (current.childUnitId == null) break;
      current = allUnits.firstWhereOrNull((u) => u.id == current!.childUnitId);
    }
    return levels;
  }

  // --- محركات الحساب المختصة بالسلاسل ---

  /// جلب كائنات مستويات السلسلة بالترتيب
  List<UnitModel> getUnitLevels(int rootId) {
    List<UnitModel> levels = [];
    UnitModel? current = allUnits.firstWhereOrNull((u) => u.id == rootId);
    while (current != null) {
      levels.add(current);
      if (current.childUnitId == null) break;
      current = allUnits.firstWhereOrNull((u) => u.id == current!.childUnitId);
    }
    return levels;
  }

  /// تفكيك كمية إجمالية إلى أجزاء موزعة على السلسلة (Normalization)
  /// مثال: 7.2 كرتون (كل كرتون 10 باكت) -> [7 كرتون، 2 باكت]
  Map<int, double> decomposeAmount(int rootId, double totalAmount) {
    Map<int, double> result = {};
    List<UnitModel> levels = getUnitLevels(rootId);
    double remaining = totalAmount;

    for (int i = 0; i < levels.length; i++) {
      final current = levels[i];
      if (i == levels.length - 1) {
        // آخر مستوى يأخذ كل الباقي
        // تقريب بسيط للأخطاء العشرية الصغيرة جداً
        result[current.id!] = (remaining * 10000).round() / 10000;
      } else {
        int integerPart = remaining.floor();
        result[current.id!] = integerPart.toDouble();
        remaining = (remaining - integerPart) * current.conversionFactor;
      }
    }
    return result;
  }

  /// تجميع القيم من كافة المستويات وتحويلها لكمية إجمالية واحدة بصيغة "الوحدة الكبرى"
  double recomposeTotal(int rootId, Map<int, double> levelValues) {
    List<UnitModel> levels = getUnitLevels(rootId);
    double total = 0.0;
    double currentDivisor = 1.0;

    for (int i = 0; i < levels.length; i++) {
      final unit = levels[i];
      final val = levelValues[unit.id] ?? 0.0;
      
      total += val / currentDivisor;
      currentDivisor *= unit.conversionFactor;
    }
    return total;
  }

  String getUnitName(int? id) {
    if (id == null) return 'قطعة';
    final unit = allUnits.firstWhereOrNull((u) => u.id == id);
    return unit?.name ?? 'وحدة غير معروفة';
  }

  String formatSmartQuantity(int? unitId, double totalQuantity) {
    if (unitId == null) return '${totalQuantity.toInt()} قطعة';
    final mainUnit = allUnits.firstWhereOrNull((u) => u.id == unitId);
    if (mainUnit == null) return '${totalQuantity.toInt()} قطعة';

    List<String> parts = [];
    _decompose(mainUnit, totalQuantity, parts);

    if (parts.isEmpty) return '0 ${mainUnit.name}';
    return parts.join('، ');
  }

  String getPackagingChain(int? unitId) {
    allUnits.length; // لضمان تفعيل Obx في الواجهة
    if (unitId == null) return 'وحدة أساسية';
    final unit = allUnits.firstWhereOrNull((u) => u.id == unitId);
    if (unit == null) return 'وحدة غير معروفة';
    if (unit.childUnitId == null) return '1 ${unit.name} (أصغر وحدة)';

    List<String> chainParts = ['1 ${unit.name}'];
    double currentMultiplier = 1.0;
    UnitModel? current = unit;

    while (current?.childUnitId != null) {
      final child = allUnits.firstWhereOrNull((u) => u.id == current!.childUnitId);
      if (child == null) break;
      
      currentMultiplier *= current!.conversionFactor;
      chainParts.add('${currentMultiplier.toInt()} ${child.name}');
      current = child;
    }

    return chainParts.join(' = ');
  }

  void _decompose(UnitModel currentUnit, double amount, List<String> parts) {
    if (amount <= 0) return;
    if ((amount - amount.round()).abs() < 0.0001) {
      amount = amount.roundToDouble();
    }

    if (currentUnit.childUnitId == null) {
      if (amount > 0) {
        String balance = amount == amount.toInt() ? amount.toInt().toString() : amount.toStringAsFixed(2);
        parts.add('$balance ${currentUnit.name}');
      }
      return;
    }

    int integerPart = amount.floor();
    if (integerPart > 0) {
      parts.add('$integerPart ${currentUnit.name}');
    }

    double remainder = amount - integerPart;
    if (remainder > 0.0001) {
      final childUnit = allUnits.firstWhereOrNull((u) => u.id == currentUnit.childUnitId);
      if (childUnit != null) {
        double childAmount = remainder * currentUnit.conversionFactor;
        _decompose(childUnit, childAmount, parts);
      }
    }
  }
}
