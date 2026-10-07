import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/candidate.dart';
import '../services/api_service.dart';
import '../../controller/base_controller.dart';

enum CandidateFilter { all, pending, verified, rejected, recheck }

class VerifierCandidatesController extends BaseController {
  final candidates = <Candidate>[].obs;
  final filter = CandidateFilter.all.obs;
  final searchCtl = TextEditingController();

  List<Candidate> get filtered {
    final f = filter.value.name;
    if (f == 'all') return candidates;
    return candidates.where((c) => c.status.toLowerCase() == f).toList();
  }

  int get pendingCount => candidates.where((c) => c.isPending).length;

  Future<void> loadCandidates() async {
    try {
      showLoading(withDialog: false);
      final res = await VerifierApiService.to.get(VerifierApiService.urlCandidates);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = _extractList(body);
        candidates.assignAll(list);
      } else {
        showError('Candidate list failed (${res.statusCode})');
      }
    } catch (e) {
      showError('Candidate load error: $e');
    } finally {
      hideLoading();
    }
  }

  /// Direct roll-number lookup via /candidates/search?rollNo=
  Future<void> searchByRoll(String rollNo) async {
    final q = rollNo.trim();
    if (q.isEmpty) {
      loadCandidates();
      return;
    }
    try {
      showLoading(withDialog: false);
      final res = await VerifierApiService.to
          .get(VerifierApiService.urlCandidateSearch, queryParams: {'rollNo': q});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = _extractList(body);
        if (list.isEmpty) {
          showError('No candidate found for roll no $q');
          candidates.clear();
        } else {
          candidates.assignAll(list);
        }
      } else {
        showError('Search failed (${res.statusCode})');
      }
    } catch (e) {
      showError('Search error: $e');
    } finally {
      hideLoading();
    }
  }

  void clearSearch() {
    searchCtl.clear();
    loadCandidates();
  }

  List<Candidate> _extractList(dynamic body) {
    dynamic data;
    if (body is Map) data = body['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Candidate.fromJson)
          .toList();
    }
    if (data is Map<String, dynamic>) return [Candidate.fromJson(data)];
    if (body is List) {
      return body.whereType<Map<String, dynamic>>().map(Candidate.fromJson).toList();
    }
    return [];
  }

  @override
  void onClose() {
    searchCtl.dispose();
    super.onClose();
  }
}
