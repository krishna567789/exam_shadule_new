import 'dart:convert';
import 'package:get/get.dart';
import '../models/verifier_models.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';
import '../../controller/base_controller.dart';
import 'session_controller.dart';

class VerifierDashboardController extends BaseController {
  final summary = Rx<DashboardSummary>(DashboardSummary());
  final pendingSyncCount = 0.obs;

  Future<void> loadDashboard() async {
    try {
      final res = await VerifierApiService.to.get(VerifierApiService.urlDashboard);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body is Map ? body['data'] : null;
        if (data is Map<String, dynamic>) {
          summary.value = DashboardSummary.fromJson(data);
        }
      } else {
        showError('Dashboard load failed (${res.statusCode})');
      }
    } catch (e) {
      showError('Dashboard error: $e');
    } finally {
      pendingSyncCount.value = VerifierSyncService.to.pendingCount;
    }
  }

  Future<void> refreshAll() async {
    await VerifierSessionController.to.loadMe();
    await loadDashboard();
  }

  void refreshSyncCount() {
    pendingSyncCount.value = VerifierSyncService.to.pendingCount;
  }
}
