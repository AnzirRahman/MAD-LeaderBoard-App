import 'package:flutter/material.dart';
import 'package:leaderboard_app/shared/colors.dart'; // Import color palette
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileUpdate extends StatefulWidget {
  final String studentId; // Accept studentId as a parameter

  const ProfileUpdate({super.key, required this.studentId});

  @override
  ProfileUpdateState createState() => ProfileUpdateState();
}

class ProfileUpdateState extends State<ProfileUpdate> {
  final _formKey = GlobalKey<FormState>();
  String profilePictureUrl = '';
  String bio = ''; // Add bio field
  bool _isSaving = false; // Add a flag for loading state
  bool _isLoading = true; // Add a flag for loading existing data
  bool _isLocked = false; // Add a flag for locked state

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Load existing profile data
    _loadLockState(); // Load lock state
  }

  Future<void> _loadProfileData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('profiles')
              .doc(widget.studentId)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          profilePictureUrl = data['profilePictureUrl'] ?? '';
          bio = data['bio'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state
      });
    }
  }

  Future<void> _loadLockState() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('students')
              .doc(widget.studentId)
              .get();
      if (doc.exists) {
        setState(() {
          _isLocked = doc.data()?['locked'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error loading lock state: $e');
    }
  }

  Future<void> _saveProfileData(
    String studentId,
    String? profilePictureUrl,
    String? bio,
  ) async {
    try {
      setState(() {
        _isSaving = true; // Set loading state to true
      });
      final Map<String, dynamic> updateData = {};
      if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
        updateData['profilePictureUrl'] = profilePictureUrl;
      }
      if (bio != null && bio.isNotEmpty) {
        updateData['bio'] = bio;
      }
      if (updateData.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(studentId)
            .set(updateData, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving profile data: $e');
    } finally {
      setState(() {
        _isSaving = false; // Reset loading state
      });
    }
  }

  Future<void> _updateLockState(bool isLocked) async {
    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .update({'locked': isLocked});
      setState(() {
        _isLocked = isLocked;
      });
    } catch (e) {
      debugPrint('Error updating lock state: $e');
    }
  }

  Future<void> _deleteProfileField(String studentId, String field) async {
    try {
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(studentId)
          .update({field: FieldValue.delete()});
    } catch (e) {
      debugPrint('Error deleting $field: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
        backgroundColor: AppColors.primaryAccentColor,
      ),
      backgroundColor: AppColors.primaryBgColor,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Profile Picture',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'Profile Picture URL',
                                        labelStyle: TextStyle(
                                          color: AppColors.primaryTextColor,
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.primaryAccentColor,
                                          ),
                                        ),
                                      ),
                                      initialValue: profilePictureUrl,
                                      onSaved:
                                          (value) =>
                                              profilePictureUrl = value ?? '',
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: AppColors.primaryAccentColor,
                                    ),
                                    onPressed: () async {
                                      await _deleteProfileField(
                                        widget.studentId,
                                        'profilePictureUrl',
                                      );
                                      setState(() {
                                        profilePictureUrl = '';
                                      });
                                      if (mounted) {
                                        Navigator.pop(context, true);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bio',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'Bio',
                                        labelStyle: TextStyle(
                                          color: AppColors.primaryTextColor,
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.primaryAccentColor,
                                          ),
                                        ),
                                      ),
                                      initialValue: bio,
                                      onSaved: (value) => bio = value ?? '',
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: AppColors.primaryAccentColor,
                                    ),
                                    onPressed: () async {
                                      await _deleteProfileField(
                                        widget.studentId,
                                        'bio',
                                      );
                                      setState(() {
                                        bio = '';
                                      });
                                      if (mounted) {
                                        Navigator.pop(context, true);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Privacy Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                title: Text(
                                  'Lock Profile',
                                  style: TextStyle(
                                    color: AppColors.primaryTextColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  _isLocked
                                      ? 'Your profile is locked. Others will see your name as "Anonymous".'
                                      : 'Your profile is unlocked. Others can see your name.',
                                  style: TextStyle(
                                    color: AppColors.primaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                                value: _isLocked,
                                onChanged: (value) async {
                                  await _updateLockState(value);
                                },
                                activeColor: AppColors.secondaryAccentColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _isSaving
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryAccentColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              _formKey.currentState?.save();
                              await _saveProfileData(
                                widget.studentId,
                                profilePictureUrl.isNotEmpty
                                    ? profilePictureUrl
                                    : null,
                                bio.isNotEmpty ? bio : null,
                              );
                              if (mounted) {
                                Navigator.pop(context, true);
                              }
                            },
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
    );
  }
}
