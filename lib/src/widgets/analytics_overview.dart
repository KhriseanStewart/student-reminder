import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:students_reminder/src/models/assignment_summary.dart';
import 'package:students_reminder/src/models/attendance_day.dart';
import 'package:students_reminder/src/services/home_repository.dart';
import 'package:students_reminder/src/services/attendance_repository.dart';
import 'package:students_reminder/src/services/provider.dart';
import 'package:students_reminder/src/widgets/map_card.dart';

class AnalyticsOverview extends ConsumerStatefulWidget {
  const AnalyticsOverview({super.key});

  @override
  ConsumerState<AnalyticsOverview> createState() => _AnalyticsOverviewState();
}

class _AnalyticsOverviewState extends ConsumerState<AnalyticsOverview> {
  final PageController _controller = PageController();
  static const _pageCount = 3;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_controller.hasClients) {
        final nextPage = (_currentPage + 1) % _pageCount;
        _controller.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage = nextPage);
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final homeRepo = ref.watch(homeRepoProvider);
    final attendanceRepo = ref.watch(attendanceRepoProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Card(
        color: colors.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No user logged in',
            style: textTheme.bodyMedium?.copyWith(color: colors.onSurface),
          ),
        ),
      );
    }

    return Card(
      color: colors.surfaceContainerHighest,
      elevation: 12,
      shadowColor: colors.shadow.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics Overview',
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your activity this week · ${_currentWeekRange()}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 360,
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    children: [
                      _StatsAndTrendPage(
                        attendanceRepo: attendanceRepo,
                        uid: uid,
                      ),
                      const _MapOverviewPage(),
                      _AssignmentsPreviewPage(homeRepo: homeRepo, uid: uid),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pageCount,
                    (index) => _buildDot(index, colors),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, ColorScheme colors) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 18 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive
            ? colors.primary
            : colors.outline.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  static String _currentWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final formatter = DateFormat('MMM d');
    return '${formatter.format(startOfWeek)} – ${formatter.format(endOfWeek)}';
  }
}

class _StatsAndTrendPage extends ConsumerWidget {
  const _StatsAndTrendPage({required this.attendanceRepo, required this.uid});

  final AttendanceRepository attendanceRepo;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<List<AttendanceDay>>(
      stream: attendanceRepo.watchUserAttendance(uid, limit: 14),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: \${snapshot.error}',
              style: textTheme.bodyMedium?.copyWith(color: colors.error),
            ),
          );
        }

        final allDays = snapshot.data ?? [];
        final currentWeek = allDays.take(7).toList();
        final previousWeek = allDays.skip(7).take(7).toList();

        if (currentWeek.isEmpty && previousWeek.isEmpty) {
          return Center(
            child: Text(
              'No attendance activity yet. Clock in to see your progress!',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        final currentCounts = _countByStatus(currentWeek);
        final previousCounts = _countByStatus(previousWeek);

        final metrics = [
          _MetricData(
            label: 'Present',
            value: currentCounts['present'] ?? 0,
            trendValue:
                (currentCounts['present'] ?? 0) -
                (previousCounts['present'] ?? 0),
            accent: colors.primary,
          ),
          _MetricData(
            label: 'Late',
            value: currentCounts['late'] ?? 0,
            trendValue:
                (currentCounts['late'] ?? 0) - (previousCounts['late'] ?? 0),
            accent: colors.tertiary,
          ),
          _MetricData(
            label: 'Absent',
            value: currentCounts['absent'] ?? 0,
            trendValue:
                (currentCounts['absent'] ?? 0) -
                (previousCounts['absent'] ?? 0),
            accent: colors.error,
          ),
          _MetricData(
            label: 'Total',
            value: currentCounts.values.fold<int>(0, (sum, v) => sum + v),
            trendValue:
                currentCounts.values.fold<int>(0, (sum, v) => sum + v) -
                previousCounts.values.fold<int>(0, (sum, v) => sum + v),
            accent: colors.secondary,
          ),
        ];

        final atRisk = (currentCounts['absent'] ?? 0) >= 2;
        final frequentlyLate = (currentCounts['late'] ?? 0) >= 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (atRisk || frequentlyLate) ...[
                const SizedBox(height: 12),
                _StudentAlertBanner(
                  atRisk: atRisk,
                  frequentlyLate: frequentlyLate,
                ),
              ],
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: metrics.length,
                itemBuilder: (context, index) {
                  final metric = metrics[index];
                  return _MetricTile(metric: metric);
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Attendance trend (last 7 days)',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _TrendChart(days: currentWeek, colors: colors),
            ],
          ),
        );
      },
    );
  }

  static Map<String, int> _countByStatus(List<AttendanceDay> days) {
    final counts = {'present': 0, 'late': 0, 'absent': 0};

    for (final day in days) {
      final status = day.status.toLowerCase();
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }
    return counts;
  }
}

class _StudentAlertBanner extends StatelessWidget {
  final bool atRisk;
  final bool frequentlyLate;

  const _StudentAlertBanner({
    required this.atRisk,
    required this.frequentlyLate,
  });

  @override
  Widget build(BuildContext context) {
    final alerts = <String>[];
    if (atRisk) alerts.add('⚠️ 2+ absences — At Risk');
    if (frequentlyLate) alerts.add('⏰ 2+ lates — Frequently Late');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: alerts
            .map(
              (text) => Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MapOverviewPage extends StatelessWidget {
  const _MapOverviewPage();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: const MapCard(),
        ),
      ),
    );
  }
}

class _AssignmentsPreviewPage extends ConsumerWidget {
  const _AssignmentsPreviewPage({required this.homeRepo, required this.uid});

  final HomeRepository homeRepo;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<List<AssignmentSummary>>(
      stream: homeRepo.watchUpcomingAssignments(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: textTheme.bodyMedium?.copyWith(color: colors.error),
            ),
          );
        }

        final assignments = snapshot.data ?? [];
        final upcoming = [...assignments]
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upcoming assignments',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (upcoming.isEmpty)
                _EmptyAssignments(colors: colors, textTheme: textTheme)
              else
                _AssignmentsScroller(assignments: upcoming),
              const SizedBox(height: 20),
              _InsightBanner(assignments: upcoming),
            ],
          ),
        );
      },
    );
  }
}

class _AssignmentsScroller extends StatelessWidget {
  const _AssignmentsScroller({required this.assignments});

  final List<AssignmentSummary> assignments;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: assignments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final assignment = assignments[index];
          return Container(
            width: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Due ${DateFormat('MMM d').format(assignment.dueDate)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _StatusBadge(status: assignment.status),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AssignmentStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = switch (status) {
      AssignmentStatus.completed => 'Completed',
      AssignmentStatus.inProgress => 'In progress',
      AssignmentStatus.overdue => 'Overdue',
      AssignmentStatus.notStarted => 'Not started',
    };

    final color = switch (status) {
      AssignmentStatus.completed => colors.primary,
      AssignmentStatus.inProgress => colors.tertiary,
      AssignmentStatus.overdue => colors.error,
      AssignmentStatus.notStarted => colors.secondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  const _InsightBanner({required this.assignments});

  final List<AssignmentSummary> assignments;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final now = DateTime.now();
    final dueSoon = assignments
        .where(
          (assignment) =>
              assignment.dueDate.isAfter(
                now.subtract(const Duration(days: 1)),
              ) &&
              assignment.dueDate.isBefore(now.add(const Duration(days: 3))),
        )
        .length;

    String message;
    String emoji;

    if (assignments.isEmpty) {
      emoji = '🎉';
      message = 'All caught up! No assignments due this week.';
    } else if (dueSoon > 0) {
      emoji = '⚠️';
      message =
          '$dueSoon assignment${dueSoon == 1 ? '' : 's'} due soon. Plan your study time.';
    } else {
      emoji = '✅';
      final next = assignments.first;
      message =
          'Next up: ${next.title} on ${DateFormat('MMM d').format(next.dueDate)}.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAssignments extends StatelessWidget {
  const _EmptyAssignments({required this.colors, required this.textTheme});

  final ColorScheme colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Text(
        'No upcoming assignments. Enjoy the head start! 🎯',
        style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final trendLabel = _buildTrendLabel(metric.trendValue);
    final trendColor = metric.trendValue > 0
        ? colors.primary
        : metric.trendValue < 0
        ? colors.error
        : colors.outline;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: metric.accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: metric.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              metric.label,
              style: textTheme.labelSmall?.copyWith(
                color: metric.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            metric.value.toString(),
            style: textTheme.headlineSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            trendLabel,
            style: textTheme.labelSmall?.copyWith(
              color: trendColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _buildTrendLabel(int trend) {
    if (trend > 0) return '↑ $trend vs last week';
    if (trend < 0) return '↓ ${trend.abs()} vs last week';
    return 'No change week over week';
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.trendValue,
    required this.accent,
  });

  final String label;
  final int value;
  final int trendValue;
  final Color accent;
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.days, required this.colors});

  final List<AttendanceDay> days;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final chartSpots = _buildSpots(days);
    final labels = _buildDayLabels();

    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.5,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: colors.outlineVariant, strokeWidth: 0.6),
          ),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 0.5,
                getTitlesWidget: (value, meta) {
                  if (value == 1.0) {
                    return Text(
                      'On time',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    );
                  }
                  if (value == 0.5) {
                    return Text(
                      'Late',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    );
                  }
                  if (value == 0) {
                    return Text(
                      'Missed',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    labels[index],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 1,
          lineBarsData: [
            LineChartBarData(
              spots: chartSpots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: colors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.25),
                    colors.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots(List<AttendanceDay> days) {
    final now = DateTime.now();
    final earliest = now.subtract(const Duration(days: 6));
    final dayMap = {for (final day in days) day.date: day};
    final spots = <FlSpot>[];

    for (var i = 0; i < 7; i++) {
      final date = earliest.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      final status = dayMap[key]?.status.toLowerCase() ?? 'absent';
      final value = switch (status) {
        'present' => 1.0,
        'late' => 0.5,
        _ => 0.0,
      };
      spots.add(FlSpot(i.toDouble(), value));
    }

    return spots;
  }

  List<String> _buildDayLabels() {
    final now = DateTime.now();
    final earliest = now.subtract(const Duration(days: 6));
    final formatter = DateFormat('E');
    return List.generate(
      7,
      (index) => formatter
          .format(earliest.add(Duration(days: index)))
          .substring(0, 1)
          .toUpperCase(),
    );
  }
}
