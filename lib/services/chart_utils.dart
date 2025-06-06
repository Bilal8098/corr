import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:corr/services/DataProcessing.dart';

class ChartUtils {
  // 🔹 Build Category Chart
  static Widget buildCategoryChart(Map<String, int> categoryCounts) {
    // Predefined list of colors to use for each category
    const List<Color> predefinedColors = [
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.cyan,
    ];

    // Create a mapping from each category to a color
    Map<String, Color> categoryColors = {};
    int index = 0;
    for (var category in categoryCounts.keys) {
      categoryColors[category] =
      predefinedColors[index % predefinedColors.length];
      index++;
    }

    // Generate pie chart sections using the generated color mapping
    List<PieChartSectionData> sections = categoryCounts.entries.map((entry) {
      Color color = categoryColors[entry.key]!;
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        // Pie Chart
        SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 60,
              sectionsSpace: 2,
              startDegreeOffset:
              -90, // Rotate chart for better visual appearance
              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(
                touchCallback: (
                    FlTouchEvent event,
                    PieTouchResponse? touchResponse,
                    ) {
                  // Add interactivity (e.g., highlight section on touch)
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Legend
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: categoryCounts.entries.map((entry) {
            Color color = categoryColors[entry.key]!;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // 🔹 Build Certifications Overview Chart
  static Widget buildCertificationsOverviewChart(Map<String, int> certificationCounts) {
    List<PieChartSectionData> sections = certificationCounts.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.key}\n(${entry.value})',
        color: Colors.primaries[entry.key.hashCode % Colors.primaries.length],
        radius: 60,
        titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 80,
          sectionsSpace: 4,
        ),
      ),
    );
  }

  // 🔹 Build Projects Contribution Chart
  static Widget buildProjectsContributionChart(List<BarChartGroupData> filteredBarGroups, bool animateChart) {
    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          barGroups: filteredBarGroups,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, interval: 1),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  String projectName = filteredBarGroups[value.toInt()]
                      .barRods
                      .first
                      .toY
                      .toString();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(projectName, style: TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.black87.withOpacity(0.8),
              tooltipPadding: const EdgeInsets.all(8),
              tooltipRoundedRadius: 8,
            ),
          ),
        ),
        swapAnimationDuration: Duration(milliseconds: animateChart ? 800 : 0),
        swapAnimationCurve: Curves.easeInOut,
      ),
    );
  }

  // 🔹 Build Languages Proficiency Chart

// 🔹 Build Languages Proficiency Chart
  static Widget buildLanguagesProficiencyChart(Map<String, double> languageAverages) {
    if (languageAverages.isEmpty) {
      return Center(child: Text("No Language Data Available"));
    }

    print("📊 Languages Data for Chart: $languageAverages");

    Map<String, Color> categoryColors = {
      "Native": Colors.red,
      "Fluent": Colors.orange,
      "Intermediate": Colors.amber,
      "Beginner": Colors.pink,
    };

    List<BarChartGroupData> barGroups = [];
    List<String> languageLabels = languageAverages.keys.toList();

    for (int i = 0; i < languageLabels.length; i++) {
      String language = languageLabels[i];
      double avgScore = languageAverages[language] ?? 0;
      String category = DataProcessing.getCategory(avgScore);
      Color barColor = categoryColors[category] ?? Colors.grey;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: avgScore,
              color: barColor,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text("${(value * 100).toStringAsFixed(0)}%", style: TextStyle(fontSize: 12));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < languageLabels.length) {
                    return Text(languageLabels[index], style: TextStyle(fontSize: 12));
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }
  // 🔹 تحديد فئة اللغة بناءً على المتوس

  // 🔹 Build Education Timeline Chart
  static Widget buildEducationTimelineChart(List<Map<String, String>> educationTimeline) {
    List<FlSpot> spots = [];
    List<String> labels = [];

    for (int i = 0; i < educationTimeline.length; i++) {
      String dates = educationTimeline[i]['DatesAttended'] ?? '';
      String degree = educationTimeline[i]['Degree'] ?? 'Unknown';
      List<String> years = dates.split('–');

      if (years.length == 2) {
        double startYear = double.tryParse(years[0].trim().split(' ').last) ?? 0;
        double endYear = double.tryParse(years[1].trim().split(' ').last) ?? 0;

        spots.add(FlSpot(startYear, i.toDouble()));
        spots.add(FlSpot(endYear, i.toDouble()));
        labels.add(degree);
      }
    }

    return SizedBox(
      height: 500,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10)),

                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  // Helper function to get color for category
  static Color _getColorForCategory(String category) {
    final colorList = Colors.primaries;
    return colorList[category.hashCode % colorList.length].withOpacity(0.8);
  }
}