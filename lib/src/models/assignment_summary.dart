import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentStatus { notStarted, inProgress, completed, overdue }

class AssignmentSummary {
  final String id;
  final String title;
  final DateTime dueDate;
  final AssignmentStatus status;

  const AssignmentSummary({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.status,
  });

  factory AssignmentSummary.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return AssignmentSummary(
      id: doc.id,
      title: (data['title'] as String? ?? 'Untitled Assignment').trim(),
      dueDate: _readDate(data['dueDate']) ?? DateTime.now(),
      status: _parseStatus(data['status'] as String?),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static AssignmentStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'in_progress':
      case 'inProgress':
        return AssignmentStatus.inProgress;
      case 'completed':
        return AssignmentStatus.completed;
      case 'overdue':
        return AssignmentStatus.overdue;
      default:
        return AssignmentStatus.notStarted;
    }
  }
}
