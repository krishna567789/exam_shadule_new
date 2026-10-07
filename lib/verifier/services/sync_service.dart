import 'dart:convert';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/pending_verification.dart';
import 'api_service.dart';

/// Offline-first verification queue.
///
/// - Failed / offline submits are stored in the `vse_pending_sync_box` Hive box
///   keyed by a unique clientSyncId.
/// - When connectivity returns, queued records are pushed to
///   `/api/verifiers/mobile/sync` in batches (max 500 per request).
class VerifierSyncService extends GetxService {
  static VerifierSyncService get to => Get.find<VerifierSyncService>();

  static const int maxBatch = 500;
  static const int maxRetries = 3;

  late Box _box;

  final RxList<PendingVerification> pending = <PendingVerification>[].obs;
  final RxBool isSyncing = false.obs;

  Future<VerifierSyncService> init(Box box) async {
    _box = box;
    _reload();
    return this;
  }

  void _reload() {
    final items = _box.values.map((e) {
      try {
        return PendingVerification.fromJson(json.decode(e.toString()));
      } catch (_) {
        return null;
      }
    }).whereType<PendingVerification>().toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    pending.assignAll(items);
  }

  int get pendingCount => pending.length;

  Future<bool> isOnline() async {
    try {
      final res = await Connectivity().checkConnectivity();
      return res.contains(ConnectivityResult.mobile) ||
          res.contains(ConnectivityResult.wifi) ||
          res.contains(ConnectivityResult.ethernet) ||
          res.contains(ConnectivityResult.vpn);
    } catch (_) {
      return true; // optimistic
    }
  }

  Future<void> enqueue(PendingVerification record) async {
    await _box.put(record.clientSyncId, json.encode(record.toJson()));
    _reload();
    print("VerifierSyncService: queued ${record.clientSyncId} for ${record.rollNo}");
  }

  Future<void> remove(String clientSyncId) async {
    await _box.delete(clientSyncId);
    _reload();
  }

  Future<void> clearAll() async {
    await _box.clear();
    _reload();
  }

  /// Push all queued records. Returns a summary map.
  Future<SyncResult> syncAll({int maxRetries = VerifierSyncService.maxRetries}) async {
    if (pending.isEmpty) {
      return SyncResult(success: 0, failed: 0, remaining: 0);
    }
    if (!await isOnline()) {
      return SyncResult(success: 0, failed: 0, remaining: pending.length, offline: true);
    }

    isSyncing.value = true;
    int success = 0;
    int failed = 0;

    final batches = <List<PendingVerification>>[];
    for (var i = 0; i < pending.length; i += maxBatch) {
      final end = (i + maxBatch).clamp(0, pending.length);
      batches.add(pending.sublist(i, end));
    }

    for (final batch in batches) {
      final items = batch.map((e) => e.payload).toList();
      bool done = false;
      for (var attempt = 0; attempt < maxRetries && !done; attempt++) {
        try {
          final res = await VerifierApiService.to
              .post(VerifierApiService.urlSync, {'items': items});
          if (res.statusCode == 200) {
            final body = _tryDecode(res.body);
            final syncedIds = _collectSyncedIds(body, batch);
            for (final id in syncedIds) {
              await remove(id);
              success++;
            }
            // Anything left in the batch that wasn't reported synced -> failed
            final remainingInBatch =
                batch.where((e) => !syncedIds.contains(e.clientSyncId)).toList();
            failed += remainingInBatch.length;
            done = true;
          } else {
            print("Sync batch HTTP ${res.statusCode}: ${res.body}");
            if (attempt == maxRetries - 1) failed += batch.length;
          }
        } catch (e) {
          print("Sync batch error: $e");
          if (attempt == maxRetries - 1) failed += batch.length;
        }
      }
    }

    isSyncing.value = false;
    _reload();
    return SyncResult(
      success: success,
      failed: failed,
      remaining: pending.length,
    );
  }

  dynamic _tryDecode(String body) {
    try {
      return json.decode(body);
    } catch (_) {
      return null;
    }
  }

  /// Best-effort extraction of which clientSyncIds succeeded.
  /// Falls back to "all in batch" when the response marks overall success,
  /// since the endpoint reports synced/duplicate/failed individually.
  Set<String> _collectSyncedIds(dynamic body, List<PendingVerification> batch) {
    final all = batch.map((e) => e.clientSyncId).toSet();
    if (body is! Map) return all;

    final data = body['data'] is Map ? body['data'] : body;
    final ids = <String>{};

    void addFrom(dynamic listOrIds) {
      if (listOrIds is List) {
        for (final it in listOrIds) {
          if (it is Map && it['clientSyncId'] != null) {
            ids.add(it['clientSyncId'].toString());
          } else if (it is String) {
            ids.add(it);
          }
        }
      }
    }

    // synced + duplicate/already-synced count as resolved (no need to retry)
    addFrom(data['synced']);
    addFrom(data['duplicates']);
    addFrom(data['duplicate']);
    addFrom(data['alreadySynced']);
    addFrom(data['already_synced']);

    if (ids.isEmpty && (body['status'] == true || data['status'] == true)) {
      return all;
    }
    return ids.where(all.contains).toSet();
  }
}

class SyncResult {
  final int success;
  final int failed;
  final int remaining;
  final bool offline;
  SyncResult({
    required this.success,
    required this.failed,
    required this.remaining,
    this.offline = false,
  });

  bool get hadWork => success > 0 || failed > 0;
}
