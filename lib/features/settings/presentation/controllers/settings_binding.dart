// File: lib/features/settings/presentation/controllers/settings_binding.dart

import 'package:ehab_company_admin/features/settings/presentation/controllers/settings_controller.dart';
import 'package:get/get.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
    