import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:students_reminder/src/core/utils/distance_utils.dart'
    as distance_utils;
import 'package:students_reminder/src/features/attendance/attendance_history.dart';
import 'package:students_reminder/src/features/checkin/check_in_controller.dart';
import 'package:students_reminder/src/features/checkin/check_result_feedback.dart';
import 'package:students_reminder/src/features/checkin/session_context.dart';
import 'package:students_reminder/src/models/attendance_record.dart';
import 'package:students_reminder/src/models/geofence_incident.dart';
import 'package:students_reminder/src/providers/incident_providers.dart';
import 'package:students_reminder/src/widgets/clock_fab.dart';
import 'package:students_reminder/src/widgets/map_card.dart';
import 'package:students_reminder/src/widgets/status_strip.dart';
import 'package:students_reminder/src/widgets/late_reason_dialog.dart';

const _cardRadius = 20.0;

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage>
    with WidgetsBindingObserver {
  Timer? _clockTicker;
  DateTime _now = DateTime.now();
  MapStatus _mapStatus = const MapStatus.loading();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startClock();
  }

  void _startClock() {
    _clockTicker?.cancel();
    _clockTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTicker?.cancel();
    super.dispose();
  }

  Future<void> _performCheck({required bool isCheckIn}) async {
    final now = DateTime.now();
    final isRestrictedDay =
        now.weekday == DateTime.wednesday || now.weekday == DateTime.thursday;

    const stonyHillLat = 18.0937;
    const stonyHillLng = -76.7880;
    const allowedRadiusMeters = 200;

    if (isCheckIn && isRestrictedDay) {
      final pos = _mapStatus.position;
      bool isAtStonyHill = false;
      String locationLabel = 'Unknown location';

      if (pos != null) {
        final distance = distance_utils.haversineDistanceMeters(
          lat1: pos.latitude,
          lon1: pos.longitude,
          lat2: stonyHillLat,
          lon2: stonyHillLng,
        );

        locationLabel = '${distance_utils.prettyDistance(distance)} away';
        isAtStonyHill = distance <= allowedRadiusMeters;
      } else {
        isAtStonyHill = false;
        locationLabel = 'Location unavailable';
      }

      if (!isAtStonyHill) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Outside designated area'),
            content: Text(
              'Today is restricted to Stony Hill campus. Your device is $locationLabel from Stony Hill.\n\nDo you still want to clock in?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Clock in anyway'),
              ),
            ],
          ),
        );

        if (proceed != true) {
          _showSnack('Clock-in cancelled (outside Stony Hill).');
          return;
        }
      }
    }

    final session = ref.read(sessionContextProvider);
    final controller = ref.read(checkInControllerProvider.notifier);

    try {
      final cutoff = session.scheduledStart.add(
        Duration(minutes: session.graceMinutes),
      );

      if (isCheckIn && now.isAfter(cutoff)) {
        final reason = await showLateReasonDialog(context);
        if (reason == null || reason.trim().isEmpty) {
          _showSnack('Clock-in cancelled (no reason provided).');
          return;
        }

        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('attendance_records')
              .add({
                'timestamp': now,
                'status': 'late',
                'reason': reason,
                'classId': session.classId,
                'sessionId': session.sessionId,
              });
        }

        _showSnack('Late reason saved: $reason');
      }

      final outcome = isCheckIn
          ? await controller.checkIn(
              sessionId: session.sessionId,
              classId: session.classId,
              scheduledStart: session.scheduledStart,
              graceMinutes: session.graceMinutes,
            )
          : await controller.checkOut(
              sessionId: session.sessionId,
              classId: session.classId,
              scheduledStart: session.scheduledStart,
              graceMinutes: session.graceMinutes,
            );

      if (!mounted) return;
      showCheckResultFeedback(context, outcome);
    } on CheckInException catch (err) {
      _showSnack(err.message);
    } catch (_) {
      _showSnack(
        'Unable to ${isCheckIn ? 'clock in' : 'clock out'}. Please try again.',
      );
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _handleMapStatusChanged(MapStatus status) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _mapStatus = status);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user signed in.')));
    }

    final checkState = ref.watch(checkInControllerProvider);
    final attendanceAsync = ref.watch(attendanceHistoryProvider(user.uid));
    final incidentsAsync = ref.watch(studentIncidentsProvider(user.uid));

    return attendanceAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load attendance.\n$err'),
          ),
        ),
      ),
      data: (records) {
        final todaySnapshot = _snapshotForDay(records, DateTime.now());
        final groupedDays = _groupByDay(records);
        final incidentsWidget = incidentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load incidents.\n$err'),
          ),
          data: (incidents) => _buildIncidentSection(incidents),
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Attendance'),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AttendanceHistory(),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
              ),
            ],
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: StatusStrip(status: todaySnapshot.currentStatus?.name),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _buildOverviewSection(todaySnapshot),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildTodaySummary(todaySnapshot),
                      const SizedBox(height: 16),
                      _buildHistorySection(groupedDays),
                      const SizedBox(height: 16),
                      _buildWeeklyStreaks(records),
                      const SizedBox(height: 16),
                      incidentsWidget,
                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: ClockFab(
            isClockedIn: todaySnapshot.isClockedIn,
            isProcessing: checkState.isLoading,
            onClockIn: () => _performCheck(isCheckIn: true),
            onClockOut: () => _performCheck(isCheckIn: false),
          ),
        );
      },
    );
  }

  DailySnapshot _snapshotForDay(List<AttendanceRecord> records, DateTime day) {
    final sameDay = records.where((r) => _isSameDay(r.checkedAt, day)).toList();
    sameDay.sort((a, b) => a.checkedAt.compareTo(b.checkedAt));

    AttendanceRecord? lastCheckIn;
    AttendanceRecord? lastCheckOut;

    for (final record in sameDay) {
      if (record.direction == AttendanceDirection.checkIn) {
        lastCheckIn = record;
      } else {
        lastCheckOut = record;
      }
    }

    AttendanceRecord? latest;
    if (lastCheckIn != null) {
      latest = lastCheckIn;
    }
    if (lastCheckOut != null &&
        (latest == null || lastCheckOut.checkedAt.isAfter(latest.checkedAt))) {
      latest = lastCheckOut;
    }

    final isClockedIn =
        lastCheckIn != null &&
        (lastCheckOut == null ||
            lastCheckIn.checkedAt.isAfter(lastCheckOut.checkedAt));

    return DailySnapshot(
      lastCheckIn: lastCheckIn,
      lastCheckOut: lastCheckOut,
      currentStatus: latest?.status,
      isClockedIn: isClockedIn,
      records: sameDay,
    );
  }

  Map<DateTime, List<AttendanceRecord>> _groupByDay(
    List<AttendanceRecord> records,
  ) {
    final map = <DateTime, List<AttendanceRecord>>{};
    for (final record in records) {
      final key = DateTime(
        record.checkedAt.year,
        record.checkedAt.month,
        record.checkedAt.day,
      );
      map.putIfAbsent(key, () => []).add(record);
    }
    return map;
  }

  Widget _buildOverviewSection(DailySnapshot snapshot) {
    final lastLocation =
        snapshot.lastCheckIn?.actualLocation ??
        snapshot.lastCheckOut?.actualLocation;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 640;

        final pills = SizedBox(
          width: isWide ? 200 : double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationPill(lastLocation),
              const SizedBox(height: 12),
              _buildStatusSummaryPill(snapshot),
            ],
          ),
        );

        final mapCard = Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
          ),
          elevation: 6,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 300,
            child: MapCard(onStatusChanged: _handleMapStatusChanged),
          ),
        );

        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  pills,
                  const SizedBox(width: 20),
                  Expanded(child: mapCard),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [pills, const SizedBox(height: 16), mapCard],
              );
      },
    );
  }

  Widget _buildLocationPill(GeoSample? location) {
    String text;
    Color pillColor;
    Color textColor;
    String emoji;

    switch (_mapStatus.state) {
      case MapLoadState.ready:
        if (location != null) {
          text =
              'Lat ${location.latitude.toStringAsFixed(4)}, Lng ${location.longitude.toStringAsFixed(4)}';
        } else if (_mapStatus.position != null) {
          text =
              'Lat ${_mapStatus.position!.latitude.toStringAsFixed(4)}, Lng ${_mapStatus.position!.longitude.toStringAsFixed(4)}';
        } else {
          text = 'Location ready';
        }
        pillColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        emoji = '📍';
        break;
      case MapLoadState.error:
        text = 'Location error: ${_mapStatus.error ?? 'Unknown'}';
        pillColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        emoji = '❌';
        break;
      case MapLoadState.loading:
        text = 'Detecting location…';
        pillColor = Colors.grey.shade200;
        textColor = Colors.grey.shade600;
        emoji = '⏳';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummaryPill(DailySnapshot snapshot) {
    final status = snapshot.currentStatus ?? distance_utils.AttStatus.present;
    final statusLabel = _statusLabel(status);
    final color = _statusColor(status);
    final now = TimeOfDay.fromDateTime(_now).format(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last checked ${now.toLowerCase()}',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary(DailySnapshot snapshot) {
    final clockIn = snapshot.lastCheckIn?.checkedAt;
    final clockOut = snapshot.lastCheckOut?.checkedAt;
    final duration = _computeDuration(clockIn, clockOut);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      elevation: 4,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                      DateFormat('EEEE, MMM d').format(_now),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snapshot.isClockedIn
                          ? 'Currently clocked in'
                          : 'Not clocked in',
                      style: TextStyle(
                        color: snapshot.isClockedIn
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSummaryRow(
              icon: Icons.login,
              label: 'Clocked in',
              value: clockIn != null ? _formatTime(clockIn) : 'Not yet',
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              icon: Icons.logout,
              label: 'Clocked out',
              value: clockOut != null ? _formatTime(clockOut) : 'Not yet',
            ),
            if (duration != null) ...[
              const Divider(height: 24),
              _buildElapsedRow(duration),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.indigo.shade400),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildElapsedRow(Duration duration) {
    return Row(
      children: [
        Icon(Icons.timer, size: 22, color: Colors.indigo.shade400),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Elapsed time',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDuration(duration),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistorySection(
    Map<DateTime, List<AttendanceRecord>> groupedDays,
  ) {
    if (groupedDays.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        elevation: 4,
        margin: EdgeInsets.zero,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Your attendance history will appear here once you start clocking in.',
          ),
        ),
      );
    }

    final entries = groupedDays.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((entry) {
        final snapshot = _snapshotForDay(entry.value, entry.key);
        final status = snapshot.currentStatus;
        final color = status != null
            ? _statusColor(status)
            : Colors.grey.shade500;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.brightness_1, color: color, size: 12),
          title: Text(DateFormat('EEE, MMM d').format(entry.key)),
          subtitle: Text(status != null ? _statusLabel(status) : 'No record'),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyStreaks(List<AttendanceRecord> records) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final days = List.generate(5, (index) {
      final date = startOfWeek.add(Duration(days: index));
      final snapshot = _snapshotForDay(records, date);
      final status = snapshot.currentStatus;

      return {
        'label': DateFormat('EEE').format(date),
        'emoji': status != null ? _statusEmoji(status) : '•',
        'color': status != null ? _statusColor(status) : Colors.grey.shade500,
      };
    });

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      elevation: 4,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((day) {
            return Column(
              children: [
                Text(
                  day['label'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  day['emoji'] as String,
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildIncidentSection(List<GeofenceIncident> incidents) {
    if (incidents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      elevation: 4,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent incidents',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final incident in incidents) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.report, color: Colors.red.shade400),
                title: Text(
                  '${incident.direction == AttendanceDirection.checkIn ? 'Check in' : 'Check out'} · ${DateFormat('MMM d, h:mm a').format(incident.occurredAt)}',
                ),
                subtitle: Text(
                  '${incident.distanceLabel} away · ${incident.outsideMessageText ?? 'Outside designated zone'}',
                ),
              ),
              if (incident != incidents.last) const Divider(),
            ],
          ],
        ),
      ),
    );
  }

  Duration? _computeDuration(DateTime? checkIn, DateTime? checkOut) {
    final start = checkIn;
    if (start == null) return null;
    final end = checkOut ?? _now;
    return end.difference(start);
  }

  String _formatTime(DateTime value) => DateFormat('h:mm a').format(value);

  String _formatDuration(Duration duration) {
    final abs = duration.isNegative ? duration.abs() : duration;
    final hours = abs.inHours;
    final minutes = abs.inMinutes.remainder(60);
    return hours > 0
        ? '${hours}h ${minutes.toString().padLeft(2, '0')}m'
        : '${minutes}m';
  }

  String _statusLabel(distance_utils.AttStatus status) {
    switch (status) {
      case distance_utils.AttStatus.present:
        return 'Present';
      case distance_utils.AttStatus.late:
        return 'Late arrival';
      case distance_utils.AttStatus.outsideAttempt:
        return 'Outside area';
    }
  }

  String _statusEmoji(distance_utils.AttStatus status) {
    switch (status) {
      case distance_utils.AttStatus.present:
        return '✅';
      case distance_utils.AttStatus.late:
        return '⏰';
      case distance_utils.AttStatus.outsideAttempt:
        return '📍';
    }
  }

  Color _statusColor(distance_utils.AttStatus status) {
    switch (status) {
      case distance_utils.AttStatus.present:
        return Colors.green.shade400;
      case distance_utils.AttStatus.late:
        return Colors.orange.shade400;
      case distance_utils.AttStatus.outsideAttempt:
        return Colors.red.shade400;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class DailySnapshot {
  DailySnapshot({
    required this.lastCheckIn,
    required this.lastCheckOut,
    required this.currentStatus,
    required this.isClockedIn,
    required this.records,
  });

  final AttendanceRecord? lastCheckIn;
  final AttendanceRecord? lastCheckOut;
  final distance_utils.AttStatus? currentStatus;
  final bool isClockedIn;
  final List<AttendanceRecord> records;
}
