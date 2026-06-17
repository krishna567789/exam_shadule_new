import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    const Color cyberBlue = Color(0xFF2196F3);
    const Color cyberCyan = Color(0xFF64B5F6);
    const Color textMuted = Color(0xFF90A4AE);

    return Scaffold(
      backgroundColor: const Color(0xFF03081A),
      body: SafeArea(
            child: Column(
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFF1A3D75).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    color: const Color(0xFF0A1329).withOpacity(0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: cyberCyan, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'CNTR-104',
                                style: GoogleFonts.outfit(
                                  color: textMuted,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: cyberCyan, size: 20),
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Govt. Polytechnic College, Zone 4',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D254F).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF154385).withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time, color: cyberCyan, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Morning (Shift 1)',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '2 / 150 Present',
                              style: GoogleFonts.outfit(
                                color: cyberCyan,
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
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF154385).withOpacity(0.4),
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.search,
                            color: Color(0xFF1976D2),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1C2D42),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Scan Barcode or Search roll no...',
                              hintStyle: TextStyle(
                                color: Color(0xFF78909C),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Candidates List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CANDIDATES',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.sort, size: 14, color: textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Name (A-Z)',
                            style: GoogleFonts.outfit(
                              color: textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Candidates List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                    itemCount: _filteredCandidates.length,
                    itemBuilder: (context, index) {
                      final candidate = _filteredCandidates[index];
                      final bool isAbsent = candidate.status == CandidateStatus.absent;

                      return GestureDetector(
                        onTap: () => _navigateToEnrollment(candidate),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: _buildHudCard(
                            showTopLeft: true,
                            showBottomRight: true,
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cyberBlue,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: cyberBlue.withOpacity(0.2),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    backgroundColor: const Color(0xFF0D254F),
                                    radius: 20,
                                    child: Text(
                                      candidate.name.substring(0, 2).toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
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
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        candidate.rollNo,
                                        style: GoogleFonts.outfit(
                                          color: textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isAbsent
                                        ? const Color(0xFFEF4444).withOpacity(0.1)
                                        : const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isAbsent
                                          ? const Color(0xFFEF4444).withOpacity(0.4)
                                          : const Color(0xFF10B981).withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    isAbsent ? 'ABSENT' : 'PRESENT',
                                    style: GoogleFonts.outfit(
                                      color: isAbsent
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF10B981),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildHudCard({
    required Widget child,
    bool showTopLeft = true,
    bool showTopRight = true,
    bool showBottomLeft = true,
    bool showBottomRight = true,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1329).withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1A3D75).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}

