import 'package:ehab_company_admin/core/services/auth_service.dart';
import 'package:ehab_company_admin/features/activities/data/models/activity_model.dart';
import 'package:ehab_company_admin/features/activities/data/providers/activity_provider.dart';
import 'package:get/get.dart';

class ActivityController extends GetxController {
  final ActivityProvider _provider = ActivityProvider();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<ActivityModel> activities = <ActivityModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadActivities();
  }

  Future<void> loadActivities() async {
    isLoading.value = true;
    try {
      final list = await _provider.getAllActivities();
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
      deviceInfo: 'Admin App', // يمكن توسيعه لاحقاً
      createdAt: now,
    );

    await _provider.recordActivity(activity);
    await loadActivities(); // تحديث القائمة فورياً
  }

  // دوال مساعدة للفلترة (سيتم تفعيلها في المرحلة الثالثة)
  void filterByUser(int? userId) {
    if (userId == null) {
      loadActivities();
    } else {
      // منطق الفلترة
    }
  }
}
