import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:students_reminder/src/core/utils/distance_utils.dart'
    as distance_utils;
import 'package:students_reminder/src/features/admin/user_detail_page.dart';
import 'package:students_reminder/src/models/app_user.dart';
import 'package:students_reminder/src/models/attendance_record.dart';
import 'package:students_reminder/src/models/geofence_incident.dart';
import 'package:students_reminder/src/providers/admin_providers.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/widgets/full_map_screen.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage>
    with SingleTickerProviderStateMixin {
  bool _loadedRole = false;
  bool _isAdmin = false;
  AppUser? _currentUser;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _isAdmin = true;
        _loadedRole = true;
      });
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    if (!_loadedRole) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                'Loading dashboard…',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isAdmin || _currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text(
                'Access denied',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This dashboard is available to administrators only.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    final summaryAsync = ref.watch(adminTodaySummaryProvider);
    final studentCountAsync = ref.watch(studentCountProvider);
    final incidentsAsync = ref.watch(adminRecentIncidentsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: _buildTakeAttendanceButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.black],
          ),
        ),
        child: summaryAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (err, _) => _buildErrorState(err.toString()),
          data: (summary) {
            final studentCount = studentCountAsync.maybeWhen(
              data: (value) => value,
              orElse: () => summary.uniqueStudents,
            );
            final incidents = incidentsAsync.maybeWhen(
              data: (value) => value,
              orElse: () => const <GeofenceIncident>[],
            );

            return SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(_currentUser!.displayName),
                      const SizedBox(height: 24),
                      _buildAttendanceOverview(summary, studentCount),
                      const SizedBox(height: 24),
                      _buildInsights(summary),
                      const SizedBox(height: 24),
                      _buildQuickActions(summary),
                      const SizedBox(height: 24),
                      _buildIncidentSection(incidents),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String displayName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Administrator',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Online',
                    style: GoogleFonts.poppins(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => showLogoutModal(
            context,
            onLogout: () => AuthService.instance.logout(),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceOverview(
    AdminAttendanceSummary summary,
    int studentCount,
  ) {
    final absent = (studentCount - summary.uniqueStudents).clamp(0, 9999);

    Widget metric(String label, int value, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value.toString().padLeft(2, '0'),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Overview',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Live today · ${DateTime.now().toString().split(' ').first}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live',
                      style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              metric('Total', summary.total, Colors.blue.shade600),
              const SizedBox(width: 12),
              metric('Present', summary.present, Colors.green.shade600),
              const SizedBox(width: 12),
              metric('Late', summary.late, Colors.orange.shade600),
              const SizedBox(width: 12),
              metric('Outside', summary.outside, Colors.red.shade600),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              metric(
                'Students',
                summary.uniqueStudents,
                Colors.purple.shade600,
              ),
              const SizedBox(width: 12),
              metric('Absent (est.)', absent, Colors.grey.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(AdminAttendanceSummary summary) {
    List<MapEntry<String, int>> takeTop(Map<String, int> source) {
      final sorted = source.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted.take(5).toList();
    }

    final lateLeaders = takeTop(
      summary.lateCounts,
    ).where((entry) => entry.value >= 2).toList();
    final outsideAlerts = takeTop(
      summary.outsideCounts,
    ).where((entry) => entry.value >= 1).toList();

    if (lateLeaders.isEmpty && outsideAlerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Text(
          'No alerts yet. Attendance looks good today.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
      );
    }

    Widget buildEntry(MapEntry<String, int> entry, String label, Color color) {
      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(entry.key)
            .get(),
        builder: (context, snapshot) {
          final name = snapshot.hasData
              ? AppUser.fromMap(
                  entry.key,
                  snapshot.data!.data() ?? {},
                ).displayName
              : entry.key;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(Icons.person, color: color),
            ),
            title: Text(
              name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '$label • ${entry.value}×',
              style: GoogleFonts.poppins(color: color.withValues(alpha: 0.8)),
            ),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insights & Alerts',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (lateLeaders.isNotEmpty) ...[
            Text(
              'Frequently late',
              style: GoogleFonts.poppins(
                color: Colors.orange.shade300,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...lateLeaders.map(
              (entry) => buildEntry(entry, 'Late', Colors.orange.shade300),
            ),
            const SizedBox(height: 18),
          ],
          if (outsideAlerts.isNotEmpty) ...[
            Text(
              'Outside geofence',
              style: GoogleFonts.poppins(
                color: Colors.red.shade300,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...outsideAlerts.map(
              (entry) =>
                  buildEntry(entry, 'Outside attempt', Colors.red.shade300),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(AdminAttendanceSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick actions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0,
          children: [
            _buildQuickActionBtn(
              label: 'Students',
              icon: Icons.people_outline,
              color: Colors.blue,
              onTap: () => _showStudentsList(summary),
            ),
            _buildQuickActionBtn(
              label: 'View map',
              icon: Icons.map_outlined,
              color: Colors.green,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FullMapScreen()),
                );
              },
            ),
            _buildQuickActionBtn(
              label: 'Reports',
              icon: Icons.analytics_outlined,
              color: Colors.orange,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reports coming soon')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentSection(List<GeofenceIncident> incidents) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent incidents',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (incidents.isNotEmpty)
                Text(
                  '${incidents.length} open',
                  style: GoogleFonts.poppins(
                    color: Colors.red.shade200,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (incidents.isEmpty)
            Text(
              'No geofence incidents reported today.',
              style: GoogleFonts.poppins(color: Colors.white70),
            )
          else
            Column(children: incidents.map(_buildIncidentTile).toList()),
        ],
      ),
    );
  }

  Widget _buildIncidentTile(GeofenceIncident incident) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(incident.studentUid)
          .get(),
      builder: (context, snapshot) {
        final name = snapshot.hasData
            ? AppUser.fromMap(
                incident.studentUid,
                snapshot.data!.data() ?? {},
              ).displayName
            : incident.studentUid;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${incident.direction == AttendanceDirection.checkIn ? 'In' : 'Out'} · ${incident.distanceLabel}',
                    style: GoogleFonts.poppins(
                      color: Colors.red.shade200,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Occurred at ${incident.occurredAt.hour.toString().padLeft(2, '0')}:${incident.occurredAt.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
              if (incident.outsideMessageText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    incident.outsideMessageText!,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showStudentsList(AdminAttendanceSummary summary) {
    final entries = summary.latestByStudent.values.toList()
      ..sort((a, b) => b.checkedAt.compareTo(a.checkedAt));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s students',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        return _buildStudentListItem(entries[index]);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentListItem(AttendanceRecord record) {
    final status = record.status;
    final color = _statusColor(status);
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(record.studentUid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            title: Text('Loading…', style: TextStyle(color: Colors.white70)),
          );
        }

        final appUser = AppUser.fromMap(
          record.studentUid,
          snapshot.data!.data() ?? {},
        );

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: (Colors.grey[850] ?? Colors.grey.shade800),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(Icons.person, color: color),
            ),
            title: Text(
              appUser.displayName,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _statusLabel(status),
              style: GoogleFonts.poppins(color: color, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserDetailPage.admin(
                    student: appUser,
                    currentUser: _currentUser!,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTakeAttendanceButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 40,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Take attendance coming soon')),
          );
        },
        icon: const Icon(Icons.event_available),
        label: const Text('Take attendance'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 48),
            const SizedBox(height: 12),
            Text(
              'Unable to load admin data',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(distance_utils.AttStatus status) {
    switch (status) {
      case distance_utils.AttStatus.present:
        return Colors.green;
      case distance_utils.AttStatus.late:
        return Colors.orange;
      case distance_utils.AttStatus.outsideAttempt:
        return Colors.red;
    }
  }

  String _statusLabel(distance_utils.AttStatus status) {
    switch (status) {
      case distance_utils.AttStatus.present:
        return 'Present';
      case distance_utils.AttStatus.late:
        return 'Late';
      case distance_utils.AttStatus.outsideAttempt:
        return 'Outside area';
    }
  }
}

void showLogoutModal(BuildContext context, {required VoidCallback onLogout}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.logout, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Log out of admin?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Any unsaved changes will be lost.',
              style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onLogout();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Log out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
