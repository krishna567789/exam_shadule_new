import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/candidate.dart';
import 'enrollment_screen.dart';

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({super.key});

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  final List<Candidate> _allCandidates = [
    Candidate(id: '1', name: 'Aarav Sharma', rollNo: '2025-EX-8821', status: CandidateStatus.absent),
    Candidate(id: '2', name: 'Mock Candidate 1', rollNo: '2025-EX-9000', status: CandidateStatus.absent),
    Candidate(id: '3', name: 'Mock Candidate 10', rollNo: '2025-EX-9009', status: CandidateStatus.absent),
    Candidate(id: '4', name: 'Mock Candidate 100', rollNo: '2025-EX-9099', status: CandidateStatus.absent),
  ];

  List<Candidate> _filteredCandidates = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCandidates = _allCandidates;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCandidates = _allCandidates.where((c) {
        return c.name.toLowerCase().contains(query) || c.rollNo.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _navigateToEnrollment(Candidate candidate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BiometricEnrollmentScreen(candidate: candidate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'CNTR-104',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () {
                        // Logout action handled in Session Setup or App Main, for now pop to root
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                  ],
                ),
                const Text(
                  'Govt. Polytechnic College, Zone 4',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Morning (Shift 1)',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        '2 / 150 Present',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              autofocus: true,
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Scan Barcode or Search roll no...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textLight),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          
          // Candidates List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Candidates',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.sort, size: 16, color: AppTheme.textLight),
                  label: const Text(
                    'Name (A-Z)',
                    style: TextStyle(color: AppTheme.textLight),
                  ),
                ),
              ],
            ),
          ),
          
          // Candidates List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              itemCount: _filteredCandidates.length,
              itemBuilder: (context, index) {
                final candidate = _filteredCandidates[index];
                return GestureDetector(
                  onTap: () => _navigateToEnrollment(candidate),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: candidate.status == CandidateStatus.absent
                            ? AppTheme.errorRed.withOpacity(0.3)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.backgroundLight,
                          radius: 24,
                          child: Text(
                            candidate.name.substring(0, 2).toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                candidate.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                candidate.rollNo,
                                style: const TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: candidate.status == CandidateStatus.absent
                                ? AppTheme.errorRed.withOpacity(0.1)
                                : AppTheme.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            candidate.status == CandidateStatus.absent ? 'ABSENT' : 'PRESENT',
                            style: TextStyle(
                              color: candidate.status == CandidateStatus.absent
                                  ? AppTheme.errorRed
                                  : AppTheme.successGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
