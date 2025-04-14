import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leaderboard_app/models/students.dart';
import 'package:leaderboard_app/shared/colors.dart';

class FacultyScreen extends StatefulWidget {
  const FacultyScreen({super.key});

  @override
  State<FacultyScreen> createState() => _FacultyScreenState();
}

class _FacultyScreenState extends State<FacultyScreen> {
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _accessKeyController = TextEditingController();
  final StudentService _studentService = StudentService();
  Student? _student;
  final _formKey = GlobalKey<FormState>();
  bool _isKeyVerified = false;

  Future<void> _verifyKey() async {
    final enteredKey = _accessKeyController.text.trim();
    if (enteredKey.isEmpty) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('access')
              .doc('faculty')
              .get();

      if (doc.exists && doc.data()?['key'] == enteredKey) {
        setState(() {
          _isKeyVerified = true;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid access key.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _loadStudent() async {
    final studentId = _studentIdController.text.trim();
    if (studentId.isEmpty) return;

    try {
      final student = await _studentService.fetchStudentById(studentId);
      setState(() {
        _student = student;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _updateStudent() async {
    if (_formKey.currentState?.validate() != true || _student == null) return;

    try {
      await _student!.doc.reference.update({
        'Name': _student!.name,
        'Department': _student!.department,
        'Batch': _student!.batch,
        'Section': _student!.section,
        'Result': _student!.result, // Ensure this is a double
        'Achievement': _student!.achievement,
        'Extracurricular': _student!.extracurricular,
        'Co-curriculum': _student!.coCurriculum,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student updated successfully!')),
      );
    } catch (e) {
      // Log the error for debugging
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isKeyVerified) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Faculty Access'),
          backgroundColor: AppColors.primaryAccentColor,
        ),
        body: Container(
          color: AppColors.primaryBgColor,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _accessKeyController,
                decoration: InputDecoration(
                  labelText: 'Enter Access Key',
                  labelStyle: const TextStyle(color: AppColors.darkerShade),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryAccentColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _verifyKey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccentColor,
                ),
                child: const Text(
                  'Verify Key',
                  style: TextStyle(color: AppColors.secondaryTextColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty'),
        backgroundColor: AppColors.primaryAccentColor,
      ),
      body: Container(
        color: AppColors.primaryBgColor,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _studentIdController,
              decoration: InputDecoration(
                labelText: 'Enter Student ID',
                labelStyle: const TextStyle(color: AppColors.darkerShade),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryAccentColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStudent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccentColor,
              ),
              child: const Text(
                'Load Student',
                style: TextStyle(color: AppColors.secondaryTextColor),
              ),
            ),
            const SizedBox(height: 16),
            if (_student != null)
              Form(
                key: _formKey,
                child: Expanded(
                  child: ListView(
                    children: [
                      TextFormField(
                        initialValue: _student!.name,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          labelStyle: TextStyle(color: AppColors.darkerShade),
                        ),
                        onChanged:
                            (value) =>
                                _student = _student!.copyWith(name: value),
                      ),
                      TextFormField(
                        initialValue: _student!.department,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          labelStyle: TextStyle(color: AppColors.darkerShade),
                        ),
                        onChanged:
                            (value) =>
                                _student = _student!.copyWith(
                                  department: value,
                                ),
                      ),
                      TextFormField(
                        initialValue: _student!.batch.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Batch',
                          labelStyle: TextStyle(color: AppColors.darkerShade),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged:
                            (value) =>
                                _student = _student!.copyWith(
                                  batch: int.tryParse(value) ?? _student!.batch,
                                ),
                      ),
                      TextFormField(
                        initialValue: _student!.section,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          labelStyle: TextStyle(color: AppColors.darkerShade),
                        ),
                        onChanged:
                            (value) =>
                                _student = _student!.copyWith(section: value),
                      ),
                      TextFormField(
                        initialValue: _student!.result.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Result',
                          labelStyle: TextStyle(color: AppColors.darkerShade),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged:
                            (value) =>
                                _student = _student!.copyWith(
                                  result:
                                      double.tryParse(value) ??
                                      _student!.result,
                                ),
                      ),
                      TextFormField(
                        initialValue: _student!.achievement.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Achievement',
                          labelStyle: TextStyle(color: AppColors.darkerShade),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged:
                            (value) =>
                                _student = _student!.copyWith(
                                  achievement:
                                      int.tryParse(value) ??
                                      _student!.achievement,
                                ),
                      ),
                      TextFormField(
                        initialValue: _student!.extracurricular,
                        decoration: const InputDecoration(
                          labelText: 'Extracurricular',
                          labelStyle: TextStyle(color: AppColors.darkerShade),
                        ),
                        onChanged:
                            (value) =>
                                _student = _student!.copyWith(
                                  extracurricular: value,
                                ),
                      ),
                      TextFormField(
                        initialValue: _student!.coCurriculum,
                        decoration: const InputDecoration(
                          labelText: 'Co-curriculum',
                          labelStyle: TextStyle(color: AppColors.darkerShade),
                        ),
                        onChanged:
                            (value) =>
                                _student = _student!.copyWith(
                                  coCurriculum: value,
                                ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _updateStudent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryAccentColor,
                        ),
                        child: const Text(
                          'Update Student',
                          style: TextStyle(color: AppColors.secondaryTextColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
