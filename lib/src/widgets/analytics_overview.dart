import 'package:flutter/material.dart';

class AnalyticsOverview extends StatelessWidget {
  const AnalyticsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    // Mocked values for demo
    final present = 20;
    final late = 5;
    final absent = 3;
    final total = present + late + absent;

    double ratio(int count) => total == 0 ? 0 : count / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurpleAccent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _progressStat("Present", present, ratio(present), Colors.greenAccent),
          _progressStat("Late", late, ratio(late), Colors.orangeAccent),
          _progressStat("Absent", absent, ratio(absent), Colors.redAccent),
        ],
      ),
    );
  }

  Widget _progressStat(String label, int count, double progress, Color color) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4), // subtle glow
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SizedBox(
            height: 80,
            width: 80,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: value,
                    strokeWidth: 5,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                  Center(
                    child: Text(
                      "$count",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
