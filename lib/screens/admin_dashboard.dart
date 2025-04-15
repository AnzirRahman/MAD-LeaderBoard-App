import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaderboard_app/models/students.dart' hide StudentService;
import 'package:leaderboard_app/models/app_user.dart';
import 'package:leaderboard_app/providers/auth_provider.dart';
import 'package:leaderboard_app/services/auth_service.dart';
import 'package:leaderboard_app/services/student_service.dart';
import 'package:leaderboard_app/shared/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leaderboard_app/screens/navbar.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  final TextEditingController _searchController = TextEditingController();
  Student? _selectedStudent;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _isAdding = false;

  final TextEditingController _achievementController = TextEditingController();
  final TextEditingController _coCurriculumController = TextEditingController();
  final TextEditingController _extracurricularController = TextEditingController();

  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();
  final TextEditingController _newAchievementController = TextEditingController();
  final TextEditingController _newExtracurricularController = TextEditingController();
  final TextEditingController _newCoCurriculumController = TextEditingController();

  // New state for toggling UI
  String _activeSection = 'search'; // 'search' or 'add'

  late final Future<DocumentSnapshot> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(ref.read(authProvider).value?['user']?.uid)
        .get();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _achievementController.dispose();
    _coCurriculumController.dispose();
    _extracurricularController.dispose();
    _studentIdController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    _batchController.dispose();
    _sectionController.dispose();
    _resultController.dispose();
    _newAchievementController.dispose();
    _newExtracurricularController.dispose();
    _newCoCurriculumController.dispose();
    super.dispose();
  }

  Future<void> _searchStudent(String id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedStudent = null;
    });

    try {
      final student = await StudentService().fetchStudentById(id);
      if (student != null) {
        setState(() {
          _selectedStudent = student;
          _achievementController.text = student.achievement.toString();
          _coCurriculumController.text = student.coCurriculum;
          _extracurricularController.text = student.extracurricular;
        });
      } else {
        setState(() {
          _errorMessage = 'Student not found';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStudent() async {
    if (_selectedStudent == null) return;

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final updatedAchievement = int.tryParse(_achievementController.text) ?? 0;
      final updatedCoCurriculum = _coCurriculumController.text;
      final updatedExtracurricular = _extracurricularController.text;

      await FirebaseFirestore.instance
          .collection('students')
          .doc(_selectedStudent!.id)
          .update({
        'Achievement': updatedAchievement,
        'Co-curriculum': updatedCoCurriculum,
        'Extracurricular': updatedExtracurricular,
      });

      setState(() {
        _selectedStudent = _selectedStudent!.copyWith(
          achievement: updatedAchievement,
          coCurriculum: updatedCoCurriculum,
          extracurricular: updatedExtracurricular,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student data updated successfully')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update student data: $e';
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _addStudent() async {
    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    try {
      final id = _studentIdController.text.trim();
      final name = _nameController.text.trim();
      final department = _departmentController.text.trim();
      final batch = int.tryParse(_batchController.text.trim());
      final section = _sectionController.text.trim().toUpperCase();
      final result = double.tryParse(_resultController.text.trim());
      final achievement = int.tryParse(_newAchievementController.text.trim()) ?? 0;
      final extracurricular = _newExtracurricularController.text.trim();
      final coCurriculum = _newCoCurriculumController.text.trim();

      if (id.isEmpty) {
        throw Exception('Student ID is required');
      }
      if (name.isEmpty) {
        throw Exception('Name is required');
      }
      if (department.isEmpty) {
        throw Exception('Department is required');
      }
      if (batch == null || batch <= 0) {
        throw Exception('Please enter a valid batch (e.g., 2023)');
      }
      if (section.isEmpty) {
        throw Exception('Section is required');
      }
      if (result == null || result < 0) {
        throw Exception('Please enter a valid result (e.g., 3.5)');
      }

      print('Adding student with ID: $id');
      await StudentService().addStudent(
        id: id,
        name: name,
        department: department,
        batch: batch,
        section: section,
        result: result,
        achievement: achievement,
        extracurricular: extracurricular.isEmpty ? 'No' : extracurricular,
        coCurriculum: coCurriculum.isEmpty ? 'No' : coCurriculum,
      );

      setState(() {
        _studentIdController.clear();
        _nameController.clear();
        _departmentController.clear();
        _batchController.clear();
        _sectionController.clear();
        _resultController.clear();
        _newAchievementController.clear();
        _newExtracurricularController.clear();
        _newCoCurriculumController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student added successfully')),
      );
    } catch (e) {
      print('Add student error: $e');
      String errorMessage;
      if (e.toString().contains('already exists')) {
        errorMessage = 'Student ID already exists. Please use a unique ID.';
      } else if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Please check Firestore security rules.';
      } else if (e.toString().contains('required')) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = 'Failed to add student: $e';
      }
      setState(() {
        _errorMessage = errorMessage;
      });
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (authData) {
        if (authData == null || authData['user'] == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/signin');
          });
          return const Center(child: CircularProgressIndicator());
        }

        final user = authData['user'] as AppUser;
        if (user.role != 'admin') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/signin');
          });
          return const Center(child: Text('Unauthorized access'));
        }

        return FutureBuilder<DocumentSnapshot>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Profile not found'));
            }

            final profileData = snapshot.data!.data() as Map<String, dynamic>;
            final name = profileData['name'] as String? ?? 'Unknown';
            final email = profileData['email'] as String? ?? user.email;
            final designation = profileData['designation'] as String? ?? 'Admin';
            final profilePictureUrl = profileData['profilePictureUrl'] as String? ??
                'https://via.placeholder.com/150';

            return Scaffold(
              appBar: AppBar(
                backgroundColor: AppColors.secondaryAccentColor,
                title: const Text('Admin Dashboard'),
                automaticallyImplyLeading: false,
                /* leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    try {
                      print('AdminDashboard: Back button pressed, navigating to home page (/wrapper)');
                      Navigator.pushReplacementNamed(
                        context,
                        '/wrapper',
                        arguments: {'allowMainMenu': true, 'item': NavBarItem.home},
                      );
                    } catch (e) {
                      print('AdminDashboard: Navigation error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Navigation error: $e')),
                      );
                    }
                  },
                  tooltip: 'Back to Home Page',
                ),
                */
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      print('AdminDashboard: Logout button pressed');
                      await AuthService.signOut();
                      Navigator.pushReplacementNamed(context, '/NavBarItem.home');
                    },
                    tooltip: 'Sign Out',
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CachedNetworkImage(
                            imageUrl: profilePictureUrl,
                            imageBuilder: (context, imageProvider) =>
                                CircleAvatar(
                              radius: 40,
                              backgroundImage: imageProvider,
                            ),
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.person, size: 80),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  designation,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _activeSection == 'search'
                                ? AppColors.secondaryAccentColor
                                : Colors.grey[300],
                            foregroundColor: _activeSection == 'search'
                                ? AppColors.primaryBgColor
                                : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _activeSection = 'search';
                              _errorMessage = null; // Clear errors when switching
                            });
                          },
                          child: const Text(
                            'Search Student',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _activeSection == 'add'
                                ? AppColors.secondaryAccentColor
                                : Colors.grey[300],
                            foregroundColor: _activeSection == 'add'
                                ? AppColors.primaryBgColor
                                : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _activeSection = 'add';
                              _errorMessage = null; // Clear errors when switching
                            });
                          },
                          child: const Text(
                            'Add New Student',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_activeSection == 'search') ...[
                    const Text(
                      'Search Student',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Enter Student ID',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            if (_searchController.text.isNotEmpty) {
                              _searchStudent(_searchController.text.trim());
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator()),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (_selectedStudent != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Editing: ${_selectedStudent!.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _achievementController,
                        decoration: const InputDecoration(
                          labelText: 'Achievements (Number)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _coCurriculumController,
                        decoration: const InputDecoration(
                          labelText: 'Co-Curricular Activities',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _extracurricularController,
                        decoration: const InputDecoration(
                          labelText: 'Extracurricular Activities',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryAccentColor,
                          foregroundColor: AppColors.primaryBgColor,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: _isUpdating ? null : _updateStudent,
                        child: _isUpdating
                            ? const CircularProgressIndicator(
                                color: AppColors.primaryBgColor,
                              )
                            : const Text('Save Changes'),
                      ),
                    ],
                  ],
                  if (_activeSection == 'add') ...[
                    const Text(
                      'Add New Student',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _studentIdController,
                      decoration: const InputDecoration(
                        labelText: 'Student ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _batchController,
                      decoration: const InputDecoration(
                        labelText: 'Batch (e.g., 2023)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sectionController,
                      decoration: const InputDecoration(
                        labelText: 'Section (e.g., A)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _resultController,
                      decoration: const InputDecoration(
                        labelText: 'Result (e.g., 3.5)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newAchievementController,
                      decoration: const InputDecoration(
                        labelText: 'Achievements (Number)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newExtracurricularController,
                      decoration: const InputDecoration(
                        labelText: 'Extracurricular Activities (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newCoCurriculumController,
                      decoration: const InputDecoration(
                        labelText: 'Co-Curricular Activities (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryAccentColor,
                        foregroundColor: AppColors.primaryBgColor,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: _isAdding ? null : _addStudent,
                      child: _isAdding
                          ? const CircularProgressIndicator(
                              color: AppColors.primaryBgColor,
                            )
                          : const Text('Add Student'),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}