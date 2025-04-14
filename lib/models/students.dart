import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Student {
  final String id;
  final String name;
  final String department;
  final int batch;
  final String section;
  final double result;
  final int achievement;
  final String extracurricular;
  final String coCurriculum;
  final DocumentSnapshot doc; // Reference to the original DocumentSnapshot

  Student({
    required this.id,
    required this.name,
    required this.department,
    required this.batch,
    required this.section,
    required this.result,
    required this.achievement,
    required this.extracurricular,
    required this.coCurriculum,
    required this.doc,
  });

  // Factory method to create a Student object from Firestore
  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      name: data['Name'] ?? '',
      department: data['Department'] ?? '',
      batch: data['Batch'] ?? 0,
      section: data['Section'] ?? '',
      result: _parseDouble(data['Result']), // Use helper method for conversion
      achievement: data['Achievement'] ?? 0,
      extracurricular: data['Extracurricular'] ?? 'No',
      coCurriculum: data['Co-curriculum'] ?? 'No',
      doc: doc,
    );
  }

  // Helper method to safely parse a value to double
  static double _parseDouble(dynamic value) {
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is String) {
      final parsedValue = double.tryParse(value);
      if (parsedValue != null) {
        return parsedValue;
      } else {
        return 0.0; // Default to 0.0 if parsing fails
      }
    }
    return 0.0; // Default to 0.0 for unsupported types
  }

  Student copyWith({
    String? id,
    String? name,
    String? department,
    int? batch,
    String? section,
    double? result,
    int? achievement,
    String? extracurricular,
    String? coCurriculum,
    DocumentSnapshot? doc,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
      batch: batch ?? this.batch,
      section: section ?? this.section,
      result: result ?? this.result,
      achievement: achievement ?? this.achievement,
      extracurricular: extracurricular ?? this.extracurricular,
      coCurriculum: coCurriculum ?? this.coCurriculum,
      doc: doc ?? this.doc,
    );
  }
}

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
      // Log the student ID
      final doc = await _firestore.collection('students').doc(id).get();
      if (doc.exists) {
        // Log the fetched data
        return Student.fromFirestore(doc);
      }
      // Log if student is not found
      throw Exception("Student with ID $id not found");
    } catch (e) {
      // Log error and stack trace
      throw Exception("Failed to fetch student data. Please try again later.");
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
      // Log the number of students fetched
      return snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
    } catch (e) {
      // Log error and stack trace
      throw Exception("Failed to fetch students. Please try again later.");
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
    return rank != -1
        ? rank + 1
        : null; // Convert 0-based index to 1-based rank
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, Map<String, dynamic>>(
      (ref) => LeaderboardNotifier(),
    );
