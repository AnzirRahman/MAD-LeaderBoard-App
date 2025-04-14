import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaderboard_app/models/students.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to fetch all students
  Stream<List<Student>> fetchStudents() {
    return _firestore.collection('students').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
    });
  }

  // Fetch a single student by ID
  Future<Student?> fetchStudentById(String id) async {
    try {
      final doc = await _firestore.collection('students').doc(id).get();
      if (doc.exists) {
        return Student.fromFirestore(doc);
      }
      throw Exception("Student with ID $id not found");
    } catch (e) {
      throw Exception("Failed to fetch student data: $e");
    }
  }

  // Fetch students with pagination and optional filters
  Future<List<Student>> fetchStudentsPaginated(
    int limit, {
    DocumentSnapshot? lastDoc,
    String? department,
    int? batch,
    String? section,
  }) async {
    try {
      Query query = _firestore
          .collection('students')
          .orderBy('Result', descending: true)
          .limit(limit);

      if (lastDoc != null) query = query.startAfterDocument(lastDoc);
      if (department != null) {
        query = query.where('Department', isEqualTo: department);
      }
      if (batch != null) query = query.where('Batch', isEqualTo: batch);
      if (section != null && section.isNotEmpty) {
        query = query.where('Section', isEqualTo: section.toUpperCase());
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception("Failed to fetch students: $e");
    }
  }

  // Check if a student ID already exists
  Future<bool> doesStudentExist(String id) async {
    try {
      final doc = await _firestore.collection('students').doc(id).get();
      return doc.exists;
    } catch (e) {
      throw Exception("Failed to check student existence: $e");
    }
  }

  // Add a new student to the students collection
  Future<void> addStudent({
    required String id,
    required String name,
    required String department,
    required int batch,
    required String section,
    required double result,
    required int achievement,
    required String extracurricular,
    required String coCurriculum,
  }) async {
    try {
      // Check for duplicate ID
      if (await doesStudentExist(id)) {
        throw Exception("Student ID $id already exists");
      }

      await _firestore.collection('students').doc(id).set({
        'Name': name,
        'Department': department,
        'Batch': batch,
        'Section': section,
        'Result': result,
        'Achievement': achievement,
        'Extracurricular': extracurricular,
        'Co-curriculum': coCurriculum,
      });
    } catch (e) {
      // Log the error for debugging
      print('Error adding student: $e');
      throw Exception("Failed to add student: $e");
    }
  }
}

// StateNotifier to manage a single student's state
class StudentNotifier extends StateNotifier<Student?> {
  StudentNotifier() : super(null);

  void setStudent(Student student) => state = student;
  void clearStudent() => state = null;
}

final studentProvider = StateNotifierProvider<StudentNotifier, Student?>(
  (ref) => StudentNotifier(),
);

// StateNotifier to manage leaderboard state
class LeaderboardNotifier extends StateNotifier<Map<String, dynamic>> {
  LeaderboardNotifier() : super({'filteredStudents': [], 'currentRank': null});

  void updateLeaderboard(List<Student> filteredStudents, String? studentId) {
    state = {
      'filteredStudents': filteredStudents,
      'currentRank': _calculateRank(filteredStudents, studentId),
    };
  }

  int? _calculateRank(List<Student> students, String? studentId) {
    if (studentId == null) return null;
    final rank = students.indexWhere((student) => student.id == studentId);
    return rank != -1 ? rank + 1 : null; // Convert 0-based index to 1-based rank
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, Map<String, dynamic>>(
  (ref) => LeaderboardNotifier(),
);