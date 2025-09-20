import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ Widgets
import 'package:students_reminder/src/widgets/summary_row.dart' as summary;
import 'package:students_reminder/src/widgets/date_search_map_bar.dart';
import 'package:students_reminder/src/widgets/student_pillrow.dart' as student;
import 'package:students_reminder/src/widgets/full_map_screen.dart';
import 'package:students_reminder/src/features/admin/search_results_screen.dart';
import 'package:students_reminder/src/features/admin/user_detail_page.dart';

// ✅ Models
import 'package:students_reminder/src/models/app_user.dart';

// ✅ Services
import 'package:students_reminder/src/services/user_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  DateTimeRange? _range; // 🔑 Selected date range
  bool _isAdmin = false;
  bool _loadedRole = false;
  AppUser? _currentUser; // 🔑 logged-in admin

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  /// ✅ Load role from Firestore
  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _isAdmin = true; // allow testing
        _loadedRole = true;
      });
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!snap.exists) {
      setState(() => _loadedRole = true);
      return;
    }

    final appUser = AppUser.fromMap(uid, snap.data() ?? {});
    setState(() {
      _currentUser = appUser;
      _isAdmin = appUser.isAdmin;
      _loadedRole = true;
    });
  }

  /// ✅ Pick a date range and refresh stream
  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initial =
        _range ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
    );

    if (picked != null) {
      setState(() => _range = picked); // 🔄 triggers StreamBuilder refresh
    }
  }

  /// ✅ Search students by name
  Future<void> _searchStudents(String query) async {
    if (query.isEmpty) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final results = snap.docs.where((doc) {
        final first = (doc['firstName'] ?? '').toString().toLowerCase();
        final last = (doc['lastName'] ?? '').toString().toLowerCase();
        return first.contains(query.toLowerCase()) ||
            last.contains(query.toLowerCase());
      }).toList();

      if (!mounted) return;

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No student found for '$query'")),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchResultsScreen(results: results),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error searching: $e")));
    }
  }

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FullMapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedRole) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    if (!_isAdmin || _currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'You do not have permission to view this page.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Admin — Attendance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.black],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // ✅ Updated: apply date range filter
        stream: UserService.instance.adminDoc(
          startDate: _range?.start,
          endDate: _range?.end,
        ),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No attendance records found',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final displayName = _currentUser?.displayName ?? "Admin";

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 👋 Greeting card
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back, $displayName 👋",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _range == null
                          ? "Here’s the attendance summary for today"
                          : "Showing records from ${_range!.start.toLocal().toString().split(' ')[0]} → ${_range!.end.toLocal().toString().split(' ')[0]}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // 📊 Summary Row
              summary.SummaryRow(docs: docs),

              const SizedBox(height: 20),

              // 🔍 Date / Search / Map
              DateSearchMapBar(
                onPickDate: _pickRange,
                onSearch: _searchStudents,
                onMap: _openMap,
              ),

              const SizedBox(height: 24),

              // 👨‍🎓 Student list
              ...buildStudentList(docs),
            ],
          );
        },
      ),
    );
  }

  /// ✅ Student list builder
  List<Widget> buildStudentList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.map((doc) {
      final data = doc.data();
      final status = data['status'] ?? 'unknown';
      final userId = data['userId'];

      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              ),
            );
          }

          final userData = userSnap.data!.data();
          if (userData == null) return const SizedBox();

          // 🔹 Build AppUser model
          final appUser = AppUser.fromMap(userId, userData);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserDetailPage.admin(
                      student: appUser,
                      currentUser: _currentUser!, // logged-in admin
                    ),
                  ),
                );
              },
              child: student.StudentRow(
                name: appUser.displayName,
                status: status,
                photoUrl: appUser.photoUrl,
                reason: data['lateReason'],
                onPresent: () async =>
                    await _markStatus(doc.reference, "present"),
                onAbsent: () async =>
                    await _markStatus(doc.reference, "absent"),
                onEditReason: () async =>
                    await _editLateReason(doc.reference, data['lateReason']),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  /// ✅ Update student status
  Future<void> _markStatus(DocumentReference docRef, String status) async {
    await docRef.update({
      'status': status,
      if (status != 'late') 'lateReason': null,
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Marked $status')));
  }

  /// ✅ Edit late reason
  Future<void> _editLateReason(
    DocumentReference docRef,
    String? current,
  ) async {
    final controller = TextEditingController(text: current ?? '');
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'Edit Late Reason',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.deepPurple),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (res == null) return;

    await docRef.update({
      'status': 'late',
      'lateReason': res.isEmpty ? null : res,
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Late reason updated')));
  }
}
