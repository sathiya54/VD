import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/analytics_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().load();
    });
  }

  static const _palette = [
    Colors.deepPurple,
    Colors.teal,
    Colors.orange,
    Colors.pinkAccent,
    Colors.blueAccent,
    Colors.green,
    Colors.brown,
    Colors.indigo,
    Colors.redAccent,
    Colors.amber,
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();

    if (provider.isLoading && provider.summary.totalEntries == 0) {
      return const Scaffold(body: LoadingIndicator());
    }
    if (provider.errorMessage != null && provider.summary.totalEntries == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: ErrorView(
          message: provider.errorMessage!,
          onRetry: () => context.read<AnalyticsProvider>().load(),
        ),
      );
    }

    final summary = provider.summary;
    final moodEntries = summary.moodDistribution.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: RefreshIndicator(
        onRefresh: () => context.read<AnalyticsProvider>().load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Total Entries', value: '${summary.totalEntries}')),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Current Streak', value: '${summary.currentStreak}d')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Longest Streak', value: '${summary.longestStreak}d')),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Goals Done', value: '${summary.goalsCompleted}')),
              ],
            ),
            const SizedBox(height: 24),
            Text('Mood Distribution', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (moodEntries.isEmpty)
              const Text('Not enough data yet.')
            else
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sections: [
                      for (var i = 0; i < moodEntries.length; i++)
                        PieChartSectionData(
                          value: moodEntries[i].value.toDouble(),
                          title: moodEntries[i].key,
                          color: _palette[i % _palette.length],
                          radius: 80,
                          titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
                        ),
                    ],
                    sectionsSpace: 2,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text('Category Distribution', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (summary.categoryDistribution.isEmpty)
              const Text('Not enough data yet.')
            else
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    barGroups: [
                      for (final entry
                          in summary.categoryDistribution.entries.toList().asMap().entries)
                        BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.value.toDouble(),
                              color: _palette[entry.key % _palette.length],
                              width: 18,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final keys = summary.categoryDistribution.keys.toList();
                            final index = value.toInt();
                            if (index < 0 || index >= keys.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(keys[index], style: const TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text('Tasks Completed: ${summary.tasksCompleted}',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            if (provider.onThisDay.isNotEmpty) ...[
              Text('On This Day', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...provider.onThisDay.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item.entry.title),
                    subtitle: Text('${item.year}'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
