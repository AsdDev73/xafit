import 'package:flutter/foundation.dart';
import 'dashboard_service.dart';

// home_widget desactivado temporalmente hasta que el plugin soporte
// UIScene lifecycle en iOS 26. La lógica está lista para reactivarse.

class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  Future<void> init() async {}

  Future<void> updateSummaryWidget(DashboardOverview overview) async {}

  Future<void> markWorkoutActive({
    required DateTime startedAt,
    required String title,
  }) async {}

  Future<void> markWorkoutInactive() async {}
}
