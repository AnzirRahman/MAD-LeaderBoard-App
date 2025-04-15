import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaderboard_app/screens/profile/profileupdate.dart';
import 'package:leaderboard_app/screens/signin/sign_in.dart';
import 'package:leaderboard_app/shared/colors.dart';
import 'package:leaderboard_app/providers/auth_provider.dart';
import 'package:leaderboard_app/models/students.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:leaderboard_app/models/app_user.dart';

class Profile extends ConsumerStatefulWidget {
  const Profile({super.key});

  @override
  ConsumerState<Profile> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<Profile> {
  final TextEditingController _studentIdController = TextEditingController();
  bool _isFetchingStudent = false;
  bool _isBinding = false;
  bool _isUnloading = false;
  bool _isFetchingRank = false;
  String? _error;
  int? _profileRank;
  int? _peopleAhead;
  int? _peopleBehind;
  bool _isProfileUnbound = false;
  bool _isRankFetched = false;

  Future<void> _fetchStudentDetails(String studentId) async {
    final authState = ref.read(authProvider).value;
    final profileId = authState?['profileId'] as String?;

    if (profileId == null || profileId == studentId) {
      setState(() {
        _isFetchingStudent = true;
        _error = null;
      });

      try {
        final studentService = StudentService();
        final student = await studentService.fetchStudentById(studentId);
        if (student != null) {
          ref.read(studentProvider.notifier).setStudent(student);
        } else {
          setState(() {
            _error = 'No student found. Please check the ID.';
          });
        }
      } catch (e) {
        setState(() {
          _error = 'Failed to fetch details: $e';
        });
      } finally {
        setState(() {
          _isFetchingStudent = false;
        });
      }
    } else {
      setState(() {
        _error = 'Cannot load profile. It is not bound to this account.';
      });
    }
  }

  Future<void> _fetchRank(String studentId) async {
    setState(() {
      _isFetchingRank = true;
      _error = null;
      _isRankFetched = false;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('students')
          .orderBy('Result', descending: true)
          .get();

      final students = querySnapshot.docs;
      final rank = students.indexWhere((doc) => doc.id == studentId) + 1;

      if (rank > 0) {
        setState(() {
          _profileRank = rank;
          _peopleAhead = rank - 1;
          _peopleBehind = students.length - rank;
          _isRankFetched = true;
        });
      } else {
        setState(() {
          _error = 'Rank not found. Please check the ID.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch rank: $e';
      });
    } finally {
      setState(() {
        _isFetchingRank = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchProfileData(String studentId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(studentId)
          .get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
    }
    return null;
  }

  Future<void> _bindProfileToAccount(String studentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isBinding = true;
      _error = null;
    });

    try {
      // Ensure student is set before binding
      final currentStudent = ref.read(studentProvider);
      if (currentStudent == null || currentStudent.id != studentId) {
        final studentService = StudentService();
        final student = await studentService.fetchStudentById(studentId);
        if (student != null) {
          ref.read(studentProvider.notifier).setStudent(student);
        } else {
          throw Exception('Student not found');
        }
      }

      // Bind profile to account
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'profileId': studentId}, SetOptions(merge: true));

      // Explicitly set unbound flag to false
      setState(() {
        _isProfileUnbound = false;
      });

      ref.invalidate(authProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile bound to account successfully!'),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to bind profile: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error binding profile: $e'),
        ),
      );
    } finally {
      setState(() {
        _isBinding = false;
      });
    }
  }

  Future<void> _unbindProfileFromAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isBinding = true;
      _error = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'profileId': null}, SetOptions(merge: true));

      setState(() {
        _profileRank = null;
        _peopleAhead = null;
        _peopleBehind = null;
        _isProfileUnbound = true;
        _isRankFetched = false;
      });

      ref.invalidate(authProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile unbound from account successfully!'),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to unbind profile: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unbinding profile: $e'),
        ),
      );
    } finally {
      setState(() {
        _isBinding = false;
      });
    }
  }

  void _unloadProfile() {
    setState(() {
      _isUnloading = true;
      _error = null;
    });

    ref.read(studentProvider.notifier).clearStudent();
    setState(() {
      _profileRank = null;
      _peopleAhead = null;
      _peopleBehind = null;
      _error = null;
      _isProfileUnbound = false;
      _isRankFetched = false;
      _isUnloading = false;
    });
    _studentIdController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile unloaded successfully!'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentProvider.notifier).clearStudent();
    });
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final student = ref.watch(studentProvider);

    if (student == null && !_isProfileUnbound) {
      _profileRank = null;
      _peopleAhead = null;
      _peopleBehind = null;
      _isRankFetched = false;
    }

    ref.listen<AsyncValue<Map<String, dynamic>?>>(authProvider, (previous, next) {
      next.whenData((authData) {
        final profileId = authData?['profileId'] as String?;
        final currentUserUid = authData?['user']?.uid as String?;
        if (profileId != null && student == null && currentUserUid != null) {
          _fetchStudentDetails(profileId);
        }
      });
    });

    return authState.when(
      data: (authData) {
        final user = authData?['user'] as AppUser?;
        final profileId = authData?['profileId'] as String?;

        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(studentProvider.notifier).clearStudent();
          });
          return const SignIn();
        }

        if (profileId != null && student == null && !_isProfileUnbound) {
          _fetchStudentDetails(profileId);
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: student != null ? _fetchProfileData(student.id) : Future.value(null),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading profile data: ${snapshot.error}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }

            final profileData = snapshot.data ?? {};
            final profilePictureUrl = profileData['profilePictureUrl'] ?? '';
            final bio = profileData['bio'] ?? 'No bio available';

            return Scaffold(
              backgroundColor: AppColors.primaryBgColor,
              body: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/bg-pattern.png'),
                        fit: BoxFit.none,
                        repeat: ImageRepeat.repeat,
                        opacity: 0.2,
                        scale: 3.0,
                      ),
                    ),
                    child: Center(
                      child: student == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: 'Load ',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryTextColor,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Profile',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondaryAccentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Stack(
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      child: TextField(
                                        controller: _studentIdController,
                                        decoration: InputDecoration(
                                          hintText: 'Enter Student ID',
                                          hintStyle: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.secondaryAccentColor,
                                          foregroundColor: AppColors.primaryBgColor,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: _isFetchingStudent ? null : () {
                                          final studentId = _studentIdController.text.trim();
                                          if (studentId.isNotEmpty) {
                                            _fetchStudentDetails(studentId);
                                          }
                                        },
                                        child: _isFetchingStudent
                                            ? const CircularProgressIndicator(
                                                color: Colors.white,
                                              )
                                            : const Icon(
                                                Icons.search,
                                                size: 20,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            )
                          : SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundImage: profilePictureUrl.isNotEmpty
                                          ? NetworkImage(profilePictureUrl)
                                          : const AssetImage('assets/profile.png')
                                              as ImageProvider,
                                      onBackgroundImageError: (_, __) {
                                        debugPrint('Error loading profile picture.');
                                      },
                                      backgroundColor: AppColors.primaryAccentColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      student.name,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      bio,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.primaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 6,
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Student Details',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const Divider(thickness: 1.5),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('Student ID', student.id),
                                            _buildDetailRow('Department', student.department),
                                            _buildDetailRow('Batch', student.batch.toString()),
                                            _buildDetailRow('Section', student.section),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Academic Details',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const Divider(thickness: 1.5),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('CGPA', student.result.toString()),
                                            if (_profileRank != null) ...[
                                              _buildDetailRow('Rank', _profileRank.toString()),
                                              _buildDetailRow('People Ahead', _peopleAhead.toString()),
                                              _buildDetailRow('People Behind', _peopleBehind.toString()),
                                            ],
                                            if (_profileRank != null && _isRankFetched) ...[
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Badges',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const Divider(thickness: 1.5),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  if (_profileRank == 1) ...[
                                                    Column(
                                                      children: [
                                                        Icon(
                                                          Icons.star,
                                                          color: Colors.yellow,
                                                          size: 40,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        const Text(
                                                          'Rank 1',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 16),
                                                  ],
                                                  if (_profileRank! <=
                                                      (_peopleAhead! + _peopleBehind! + 1) * 0.1) ...[
                                                    Column(
                                                      children: [
                                                        Icon(
                                                          Icons.emoji_events,
                                                          color: Colors.orange,
                                                          size: 40,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        const Text(
                                                          'Top 10%',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                            if (!_isRankFetched)
                                              Center(
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.transparent,
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      side: BorderSide(
                                                        color: AppColors.secondaryAccentColor,
                                                      ),
                                                    ),
                                                  ),
                                                  onPressed: _isFetchingRank ? null : () {
                                                    if (student != null) {
                                                      _fetchRank(student.id);
                                                    }
                                                  },
                                                  child: _isFetchingRank
                                                      ? const CircularProgressIndicator(
                                                          color: AppColors.secondaryAccentColor,
                                                        )
                                                      : Text(
                                                          'Get Rank',
                                                          style: TextStyle(
                                                            color: AppColors.secondaryAccentColor,
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Achievements',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const Divider(thickness: 1.5),
                                            const SizedBox(height: 8),
                                            _buildDetailRow(
                                                'Achievement Points', student.achievement.toString()),
                                            _buildDetailRow(
                                                'Extracurricular', student.extracurricular),
                                            _buildDetailRow('Co-Curriculum', student.coCurriculum),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          if (authData?['profileId'] != null) ...[
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.redAccent,
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: () async {
                                                await _unbindProfileFromAccount();
                                              },
                                              child: const Text(
                                                'Unbind Account',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ] else if (student != null) ...[
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primaryAccentColor,
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: _isBinding ? null : () async {
                                                if (student != null) {
                                                  await _bindProfileToAccount(student.id);
                                                }
                                              },
                                              child: _isBinding
                                                  ? const CircularProgressIndicator(
                                                      color: Colors.white,
                                                    )
                                                  : const Text(
                                                      'Bind Profile to Account',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.secondaryAccentColor,
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: _isUnloading ? null : () {
                                                _unloadProfile();
                                              },
                                              child: _isUnloading
                                                  ? const CircularProgressIndicator(
                                                      color: Colors.white,
                                                    )
                                                  : const Text(
                                                      'Unload Profile',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (student != null)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryAccentColor.withAlpha(25),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: AppColors.secondaryAccentColor,
                            ),
                          ),
                        ),
                        onPressed: () async {
                          final shouldReload = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileUpdate(studentId: student.id),
                            ),
                          );
                          if (shouldReload == true && mounted) {
                            setState(() {});
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit_outlined,
                              color: AppColors.secondaryAccentColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Update',
                              style: TextStyle(
                                color: AppColors.secondaryAccentColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'An error occurred: $error',
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}