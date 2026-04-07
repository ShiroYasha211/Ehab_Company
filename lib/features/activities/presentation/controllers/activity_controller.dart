import 'package:flutter/material.dart';
import 'package:ehab_company_admin/core/services/auth_service.dart';
import 'package:ehab_company_admin/features/activities/data/models/activity_model.dart';
import 'package:ehab_company_admin/features/activities/data/providers/activity_provider.dart';
import 'package:get/get.dart';

class ActivityController extends GetxController {
  final ActivityProvider _provider = ActivityProvider();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<ActivityModel> activities = <ActivityModel>[].obs;
  final RxBool isLoading = false.obs;

  // فلاتر البحث
  final RxnInt selectedUserId = RxnInt();
  final Rxn<ActivityType> selectedType = Rxn<ActivityType>();
  final Rxn<DateTimeRange> selectedDateRange = Rxn<DateTimeRange>();
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadActivities();
    
    // ربط البحث التلقائي مع تأخير (Debounce) لتحسين الأداء
    debounce(searchQuery, (_) => loadActivities(), time: const Duration(milliseconds: 500));
  }

  Future<void> loadActivities() async {
    isLoading.value = true;
    try {
      final list = await _provider.getFilteredActivities(
        userId: selectedUserId.value,
        type: selectedType.value,
        startDate: selectedDateRange.value?.start,
        endDate: selectedDateRange.value?.end.add(const Duration(hours: 23, minutes: 59)),
        query: searchQuery.value,
      );
      activities.value = list;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل سجل النشاطات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logAction({
    required String action,
    String? details,
    required ActivityType type,
  }) async {
    final user = _authService.currentUser.value;
    final now = DateTime.now();
    
    final activity = ActivityModel(
      userId: user?.id,
      userName: user?.name ?? 'غير معروف',
      userRole: user?.roleName ?? 'غير محدد',
      action: action,
      details: details,
      type: type,
      time: now,
      deviceInfo: 'Admin App',
      createdAt: now,
    );

    await _provider.recordActivity(activity);
    await loadActivities(); // تحديث القائمة فورياً مع مراعاة الفلاتر الحالية
  }

  void resetFilters() {
    selectedUserId.value = null;
    selectedType.value = null;
    selectedDateRange.value = null;
    searchQuery.value = '';
    loadActivities();
  }

  bool get isAnyFilterActive => 
    selectedUserId.value != null || 
    selectedType.value != null || 
    selectedDateRange.value != null || 
    searchQuery.value.isNotEmpty;

  int get activeFiltersCount {
    int count = 0;
    if (selectedUserId.value != null) count++;
    if (selectedType.value != null) count++;
    if (selectedDateRange.value != null) count++;
    if (searchQuery.value.isNotEmpty) count++;
    return count;
  }
}
