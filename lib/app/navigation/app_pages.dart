import 'package:get/get.dart';

import '../../features/policy/presentation/view/policy_dashboard_view.dart';
import 'routes.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.dashboard;

  static final routes = [
    GetPage(
      name: AppRoutes.authorizationDashboard,
      page: () => const PolicyDashboardView(),
    ),
  ];
}
