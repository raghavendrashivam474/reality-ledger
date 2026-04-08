import 'package:flutter/material.dart';

class ExecutionHeatmap extends StatelessWidget {
  final Map<DateTime, double> data;

  const ExecutionHeatmap({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Generate a list of last 30 days
    final now = DateTime.now();
    final List<DateTime> days = List.generate(
      30,
      (index) => now.subtract(Duration(days: 29 - index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "30-DAY EXECUTION STREAK",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white54,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: days.map((day) {
            final score = data[DateTime(day.year, day.month, day.day)] ?? 0.0;
            return _buildHeatmapBox(context, score, day);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHeatmapBox(BuildContext context, double score, DateTime day) {
    Color boxColor;
    if (score == 0) {
      boxColor = const Color(0xFF1A1A1A); // Empty
    } else if (score < 40) {
      boxColor = const Color(0xFF1E3A1E); // Low execution
    } else if (score < 70) {
      boxColor = const Color(0xFF2E7D32); // Medium
    } else {
      boxColor = Theme.of(context).colorScheme.primary; // High hit
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF333333), width: 0.5),
      ),
      child: Tooltip(
        message: "${day.day}/${day.month}\nScore: ${score.toInt()}%",
        child: const SizedBox(),
      ),
    );
  }
}
