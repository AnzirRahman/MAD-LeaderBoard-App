import 'package:flutter/material.dart';
import 'package:leaderboard_app/shared/colors.dart'; // Import AppColors
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leaderboard_app/models/students.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaderboard_app/providers/auth_provider.dart';

class Leaderboard extends ConsumerWidget {
  const Leaderboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Center(
            child: Text(
              'Please log in to access the leaderboard.',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
          );
        }
        return const _LeaderboardContent();
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _LeaderboardContent extends ConsumerStatefulWidget {
  const _LeaderboardContent();

  @override
  ConsumerState<_LeaderboardContent> createState() =>
      _LeaderboardContentState();
}

class _LeaderboardContentState extends ConsumerState<_LeaderboardContent> {
  final StudentService _studentService = StudentService();
  final List<Student> _students = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;

  String? _selectedDepartment;
  int? _selectedBatch;
  String? _selectedSection;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents({bool reset = false}) async {
    if (_isLoading) return;
    if (reset) {
      _resetStudentList();
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final newStudents = await _studentService.fetchStudentsPaginated(
        20, // Load 20 students instead of 10
        lastDoc: _lastDoc,
        department: _selectedDepartment,
        batch: _selectedBatch,
        section: _selectedSection,
      );
      setState(() {
        _students.addAll(newStudents);
        if (newStudents.isNotEmpty) {
          _lastDoc = newStudents.last.doc; // Correctly update _lastDoc
        }
      });

      // Notify the LeaderboardNotifier about the filtered leaderboard
      final userId = ref.read(studentProvider)?.id;
      ref
          .read(leaderboardProvider.notifier)
          .updateLeaderboard(_students, userId);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetStudentList() {
    setState(() {
      _students.clear();
      _lastDoc = null;
    });
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Options',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Department'),
                    value: _selectedDepartment,
                    items:
                        ['CSE', 'EEE', 'NFE']
                            .map(
                              (dept) => DropdownMenuItem(
                                value: dept,
                                child: Text(dept),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      _selectedDepartment = value;
                    },
                  ),
                  SizedBox(height: 8.0),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: 'Batch'),
                    value: _selectedBatch,
                    items:
                        [221, 222, 223] // Batch numbers remain as integers
                            .map(
                              (batch) => DropdownMenuItem(
                                value: batch,
                                child: Text(
                                  batch.toString(),
                                ), // Display batch as string
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      _selectedBatch = value;
                    },
                  ),
                  SizedBox(height: 8.0),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Section'),
                    value: _selectedSection,
                    items:
                        List.generate(
                              16,
                              (index) => String.fromCharCode(
                                65 + index,
                              ), // Generate sections A to P
                            )
                            .map(
                              (section) => DropdownMenuItem(
                                value: section,
                                child: Text(section),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSection =
                            value?.toUpperCase(); // Normalize to uppercase
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDepartment = null;
                            _selectedBatch = null;
                            _selectedSection = null;
                          });
                          Navigator.pop(context);
                          _fetchStudents(
                            reset: true,
                          ); // Refetch the list without filters
                        },
                        child: Text('Clear Filters'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _fetchStudents(
                            reset: true,
                          ); // Refetch the list with filters
                        },
                        child: Text('Apply Filters'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBgColor, // Set background color
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg-pattern.png'),
            fit: BoxFit.cover, // Cover the entire screen
            opacity: 0.1, // Subtle background pattern
          ),
        ),
        child: Center(
          // Center the entire layout
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Center(
                    // Center the table horizontally
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical:
                            8.0, // Reduce margin to 8.0 for top and bottom
                      ), // Add margin to top and bottom
                      width:
                          MediaQuery.of(context).size.width *
                          0.95, // Reduce width to 95% of the screen
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          12.0,
                        ), // Rounded corners
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              0.1,
                            ), // Subtle shadow
                            blurRadius: 8.0,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.secondaryAccentColor.withOpacity(
                            0.5,
                          ), // Border color
                          width: 1.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          12.0,
                        ), // Ensure table respects corners
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                columnSpacing:
                                    constraints.maxWidth /
                                    12, // Adjust column spacing dynamically
                                headingRowColor: MaterialStateProperty.all(
                                  AppColors
                                      .secondaryAccentColor, // Remove opacity for brighter header
                                ),
                                dataRowColor: MaterialStateProperty.resolveWith<
                                  Color?
                                >((Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return AppColors.secondaryAccentColor
                                        .withOpacity(0.2);
                                  }
                                  return Colors
                                      .grey[100]; // Alternating row color
                                }),
                                border: TableBorder(
                                  horizontalInside: BorderSide(
                                    color: AppColors.secondaryAccentColor
                                        .withOpacity(0.5),
                                    width: 0.5,
                                  ),
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Rank',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.0, // Slightly larger font
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Name',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'CGPA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ),
                                ],
                                rows:
                                    _students.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final student = entry.value;
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                color:
                                                    Colors
                                                        .black87, // Subtle text color
                                                fontSize: 13.0,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            InkWell(
                                              onTap: () {
                                                final isAnonymous =
                                                    (student.doc.data()
                                                        as Map<
                                                          String,
                                                          dynamic
                                                        >)['locked'] ==
                                                    true;
                                                showModalBottomSheet(
                                                  context: context,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            16.0,
                                                          ),
                                                        ), // Rounded top corners
                                                  ),
                                                  backgroundColor: AppColors
                                                      .primaryBgColor
                                                      .withOpacity(
                                                        0.95,
                                                      ), // Subtle background
                                                  builder: (context) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16.0,
                                                          ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Text(
                                                                'Details for ${isAnonymous ? 'Anonymous' : student.name}',
                                                                style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      20.0,
                                                                  color:
                                                                      AppColors
                                                                          .secondaryAccentColor, // Accent color for title
                                                                ),
                                                              ),
                                                              IconButton(
                                                                icon: Icon(
                                                                  Icons.close,
                                                                  color:
                                                                      Colors
                                                                          .grey,
                                                                ),
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      context,
                                                                    ), // Close button
                                                              ),
                                                            ],
                                                          ),
                                                          Divider(
                                                            thickness: 1.0,
                                                            color:
                                                                Colors
                                                                    .grey[300],
                                                          ), // Add a divider
                                                          SizedBox(height: 8.0),
                                                          _buildDetailRow(
                                                            'ID',
                                                            isAnonymous
                                                                ? 'Hidden'
                                                                : student.id
                                                                    .toString(),
                                                          ),
                                                          _buildDetailRow(
                                                            'Department',
                                                            isAnonymous
                                                                ? 'Hidden'
                                                                : student
                                                                    .department
                                                                    .toString(),
                                                          ),
                                                          _buildDetailRow(
                                                            'Batch',
                                                            isAnonymous
                                                                ? 'Hidden'
                                                                : student.batch
                                                                    .toString(),
                                                          ),
                                                          _buildDetailRow(
                                                            'Section',
                                                            isAnonymous
                                                                ? 'Hidden'
                                                                : student
                                                                    .section
                                                                    .toString(),
                                                          ),
                                                          _buildDetailRow(
                                                            'Result',
                                                            isAnonymous
                                                                ? 'Hidden'
                                                                : student.result
                                                                    .toString(),
                                                          ),
                                                          SizedBox(height: 8.0),
                                                          _buildDetailSection(
                                                            'Achievements',
                                                            isAnonymous
                                                                ? 'Hidden'
                                                                : student
                                                                    .achievement
                                                                    .toString(),
                                                          ),
                                                          _buildDetailSection(
                                                            'Extracurricular',
                                                            isAnonymous
                                                                ? 'Hidden'
                                                                : student
                                                                    .extracurricular
                                                                    .toString(),
                                                          ),
                                                          _buildDetailSection(
                                                            'Co-curriculum',
                                                            isAnonymous
                                                                ? 'Hidden'
                                                                : student
                                                                    .coCurriculum
                                                                    .toString(),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: Text(
                                                (student.doc.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >)['locked'] ==
                                                        true
                                                    ? 'Anonymous'
                                                    : student.name,
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 13.0,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              student.result.toString(),
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 13.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 64, // Slightly increase space between buttons
            right: 16, // Align to the right
            child: SizedBox(
              width: 100, // Same width as "Load More"
              height: 40, // Same height as "Load More"
              child: FloatingActionButton(
                onPressed: _showFilterOptions, // Open filter options
                backgroundColor: Colors.white.withAlpha(240), // 50% opacity
                elevation: 0, // Remove shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Keep edges rounded
                  side: BorderSide(
                    color: AppColors.secondaryAccentColor, // Add border
                  ),
                ),
                child: Icon(
                  Icons.filter_list, // Filter icon
                  color: AppColors.secondaryAccentColor, // Icon color
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: SizedBox(
              width: 100, // Reduce width
              height: 40, // Reduce height
              child: FloatingActionButton(
                onPressed: _fetchStudents,
                backgroundColor: Colors.white.withAlpha(240), // 50% opacity
                elevation: 0, // Remove shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Keep edges rounded
                  side: BorderSide(
                    color: AppColors.secondaryAccentColor, // Add border
                  ),
                ),
                child: Text(
                  'Load More',
                  style: TextStyle(
                    color: AppColors.secondaryAccentColor, // Set text color
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: Colors.grey[700],
            ),
          ),
          Text(value, style: TextStyle(fontSize: 16.0, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4.0),
          Text(value, style: TextStyle(fontSize: 16.0, color: Colors.black87)),
        ],
      ),
    );
  }
}
