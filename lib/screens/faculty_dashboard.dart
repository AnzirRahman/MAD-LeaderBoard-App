import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaderboard_app/models/students.dart';
import 'package:leaderboard_app/models/app_user.dart';
import 'package:leaderboard_app/providers/auth_provider.dart';
import 'package:leaderboard_app/services/auth_service.dart';
import 'package:leaderboard_app/shared/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leaderboard_app/screens/navbar.dart'; // Import NavBarItem

class FacultyDashboard extends ConsumerStatefulWidget {
  const FacultyDashboard({super.key});

  @override
  ConsumerState<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends ConsumerState<FacultyDashboard> {
  final TextEditingController _searchController = TextEditingController();
  Student? _selectedStudent;
  String? _errorMessage;
  bool _isLoading = false;

  final TextEditingController _achievementController = TextEditingController();
  final TextEditingController _coCurriculumController = TextEditingController();
  final TextEditingController _extracurricularController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _achievementController.dispose();
    _coCurriculumController.dispose();
    _extracurricularController.dispose();
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
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(_selectedStudent!.id)
          .update({
        'Achievement': int.tryParse(_achievementController.text) ?? 0,
        'Co-curriculum': _coCurriculumController.text,
        'Extracurricular': _extracurricularController.text,
      });

      setState(() {
        _selectedStudent = _selectedStudent!.copyWith(
          achievement: int.tryParse(_achievementController.text) ?? 0,
          coCurriculum: _coCurriculumController.text,
          extracurricular: _extracurricularController.text,
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
        _isLoading = false;
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
        if (user.role != 'faculty') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/signin');
          });
          return const Center(child: Text('Unauthorized access'));
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
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
            final designation = profileData['designation'] as String? ?? 'Faculty';
            final profilePictureUrl = profileData['profilePictureUrl'] as String? ??
                'https://via.placeholder.com/150';

            return Scaffold(
              appBar: AppBar(
                backgroundColor: AppColors.secondaryAccentColor,
                title: const Text('Faculty Dashboard'),
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    try {
                      print('FacultyDashboard: Back button pressed, navigating to home page (/wrapper)');
                      Navigator.pushReplacementNamed(
                        context,
                        '/wrapper',
                        arguments: {'allowMainMenu': true, 'item': NavBarItem.home},
                      );
                    } catch (e) {
                      print('FacultyDashboard: Navigation error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Navigation error: $e')),
                      );
                    }
                  },
                  tooltip: 'Back to Home Page',
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      print('FacultyDashboard: Logout button pressed');
                      await AuthService.signOut();
                      Navigator.pushReplacementNamed(context, '/signin');
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
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              onPressed: _updateStudent,
                              child: const Text('Save Changes'),
                            ),
                          ],
                        ),
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