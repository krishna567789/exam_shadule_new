import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/candidates_controller.dart';
import '../models/candidate.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text.dart';
import 'candidate_detail_screen.dart';

class VerifierCandidatesScreen extends StatefulWidget {
  const VerifierCandidatesScreen({super.key});

  @override
  State<VerifierCandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<VerifierCandidatesScreen> {
  VerifierCandidatesController get _c => Get.find<VerifierCandidatesController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _c.loadCandidates());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        title: CustomText.heading('CANDIDATES', fontSize: 16, letterSpacing: 1.5),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _c.searchCtl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textLight),
                    onSubmitted: (v) => _c.searchByRoll(v),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search by roll number',
                      hintStyle: const TextStyle(color: AppTheme.textMuted),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward, color: AppTheme.primaryNeon),
                        onPressed: () => _c.searchByRoll(_c.searchCtl.text),
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.primaryNeon, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _filterBar(),
          Expanded(
            child: Obx(() {
              if (_c.isLoading) {
                return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryNeon));
              }
              final list = _c.filtered;
              if (list.isEmpty) {
                return _emptyState();
              }
              return RefreshIndicator(
                color: AppTheme.primaryNeon,
                onRefresh: () => _c.searchCtl.text.trim().isEmpty
                    ? _c.loadCandidates()
                    : _c.searchByRoll(_c.searchCtl.text),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _candidateTile(list[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: CandidateFilter.values.map((f) {
              final selected = _c.filter.value == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: CustomText.regular(f.name.toUpperCase(),
                      fontSize: 11,
                      color: selected ? AppTheme.backgroundDark : AppTheme.textLight),
                  selected: selected,
                  onSelected: (_) => _c.filter.value = f,
                  selectedColor: AppTheme.primaryNeon,
                ),
              );
            }).toList(),
          ),
        ));
  }

  Widget _candidateTile(Candidate c) {
    final color = _statusColor(c.status);
    return Material(
      color: AppTheme.surfaceDark,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(() => CandidateDetailScreen(candidateId: c.id)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              _avatar(c.photo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.regular(c.name.isEmpty ? '—' : c.name,
                        fontSize: 15,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    CustomText.mono('ROLL ${c.rollNo}',
                        fontSize: 12, color: AppTheme.primaryNeon),
                    if (c.applicationId.isNotEmpty)
                      CustomText.regular('App ID ${c.applicationId}',
                          fontSize: 11, color: AppTheme.textMuted),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.6)),
                ),
                child: CustomText.regular(c.status.toUpperCase(),
                    fontSize: 10, color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String url) {
    if (url.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.person, color: AppTheme.textMuted),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
          width: 48, height: 48, child: Icon(Icons.person, color: AppTheme.textMuted),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 56, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          CustomText.regular('No candidates found',
              fontSize: 14, color: AppTheme.textMuted),
          TextButton(
            onPressed: () => _c.clearSearch(),
            child: const Text('Reload',
                style: TextStyle(color: AppTheme.primaryNeon)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return AppTheme.successGreen;
      case 'rejected':
        return AppTheme.errorRed;
      case 'recheck':
        return Colors.orange;
      default:
        return Colors.amber;
    }
  }
}
