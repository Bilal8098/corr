import 'dart:convert';
import 'dart:io';
import 'package:firedart/firedart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:process_run/process_run.dart';
import 'package:flutter/material.dart';
import 'assign page.dart';
import 'CVDetailedPage.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

const projectId = 'ocrcv-1e6fe';
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
void main() async {
  Firestore.initialize(projectId);
  runApp(const FireStoreApp());
}

class FireStoreApp extends StatelessWidget {
  const FireStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'CV Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.red, // Material Colors
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const FireStoreHome(),
    );
  }
}

class FireStoreHome extends StatefulWidget {
  const FireStoreHome({super.key});

  @override
  _FireStoreHomeState createState() => _FireStoreHomeState();
}

class _FireStoreHomeState extends State<FireStoreHome>
    with SingleTickerProviderStateMixin {
  CollectionReference cvCollection = Firestore.instance.collection('CV');
  List<File> selectedFiles = [];
  bool isUploading = false;
  DateTime? startDate;
  DateTime? endDate;

  List<Map<String, dynamic>> allCVs = [];
  List<Map<String, dynamic>> displayedCVs = [];
  String searchQuery = "";
  final ScrollController _scrollController = ScrollController();
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool isSkillsChecked = false;
  bool isCertificationChecked = false;
  bool isEducationChecked = false;
  bool isLanguageChecked = false;

  bool isLoading = false;
  int cvCount = 0;
  Map<String, int> categoryCounts = {};

  // Chart Data Variables
  Map<String, int> certificationCounts = {};
  List<Map<String, String>> educationTimeline = [];
  Map<String, int> languageCounts = {};
  Map<String, int> projectContributions = {};
  Map<String, int> applicationStatusCounts = {};
  List<String> projectList = ["All Projects"];
  List<String> technologyList = ["All Technologies"];
  List<BarChartGroupData> filteredBarGroups = [];
  List<String> projectNames = [];
  String selectedProjectFilter = "All Projects";
  String selectedTechnologyFilter = "All Technologies";
  bool animateChart = false;
  TextEditingController searchController = TextEditingController();
  bool showArchivedCVs = false;
  bool showAssignedCVs = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    getData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> getData() async {
    setState(() => isLoading = true);
    try {
      CollectionReference collection;
      if (showAssignedCVs) {
        collection = Firestore.instance.collection('Assign');
      } else if (showArchivedCVs) {
        collection = Firestore.instance.collection('Archive');
      } else {
        collection = Firestore.instance.collection('CV');
      }

      final querySnapshot = await collection.get();

      List<Map<String, dynamic>> docs = querySnapshot.map((doc) {
        final data = doc.map;

        // Handle 'uploadDate' conversion
        dynamic uploadDate = data['uploadDate'];
        DateTime? parsedDate;
        if (uploadDate is String) {
          try {
            parsedDate = DateFormat('yyyy-MM-dd').parse(uploadDate);
          } catch (e) {
            _showSnackbar(
                '⚠ Error parsing date for document ${doc.id}: $e', Colors.red);
          }
        }
        return {
          "id": doc.id,
          ...data,
          "uploadDate": parsedDate, // Ensure it's a DateTime object
        };
      }).toList();

      // Filter CVs: Only include those with isArchived == 'No' if collection is 'CV'
      if (!showAssignedCVs && !showArchivedCVs) {
        docs = docs.where((cv) => cv['isArchived'] == 'No').toList();
      }

      // Sort: First, those with a date (newest first), then those without a date
      docs.sort((a, b) {
        DateTime? dateA = a["uploadDate"];
        DateTime? dateB = b["uploadDate"];

        if (dateA == null && dateB == null) return 0; // Both missing dates
        if (dateA == null) return 1; // A has no date, move it down
        if (dateB == null) return -1; // B has no date, move it down

        return dateB.compareTo(dateA); // Sort by newest first
      });

      // Filter out CVs missing required fields
      allCVs = docs.where((cv) {
        return !isFieldEmpty(cv["Full Name"]) &&
            !isFieldEmpty(cv["Email address"]);
      }).toList();

      // Update the CV count
      cvCount = allCVs.length;

      // Process data for UI
      _processCategoryData();
      _processCertificationsOverview();
      _processEducationTimeline();
      _processLanguagesProficiency();
      _processProjectsContribution();
      _processJobApplicationsStatus();

      projectList = ["All Projects"];
      technologyList = ["All Technologies"];

      for (var cv in allCVs) {
        if (cv['Projects'] is List) {
          for (var project in cv['Projects']) {
            if (project is Map) {
              if (project['Name'] is String &&
                  !projectList.contains(project['Name'])) {
                projectList.add(project['Name']);
              }
              if (project['Technologies'] is List) {
                for (var tech in project['Technologies']) {
                  if (tech is Map &&
                      tech['Name'] is String &&
                      !technologyList.contains(tech['Name'])) {
                    technologyList.add(tech['Name']);
                  }
                }
              }
            }
          }
        }
      }
      _filterProjects();
      _applyFilters();
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains("Quota exceeded")) {
        _showSnackbar(
            "⚠ Firestore quota exceeded! Please try again later", Colors.red);
      } else if (errorMessage.contains('Error connecting')) {
        _showSnackbar("No internet connection", Colors.red);
      } else {
        _showSnackbar("⚠ Error fetching data: $errorMessage", Colors.red);
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> assignCV(Map<String, dynamic> cv) async {
    try {
      await Firestore.instance.collection('Assign').add(cv);

      if (showArchivedCVs) {
        await Firestore.instance
            .collection('Archive')
            .document(cv['id'])
            .delete();
      } else {
        await Firestore.instance.collection('CV').document(cv['id']).delete();
      }
      _showSnackbar("CV assigned successfully!", Colors.green);
      getData(); // Refresh the data
    } catch (e) {
      _showSnackbar("Error assigning CV: $e", Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<String> _getActiveFilterFields() {
    List<String> activeFields = [];
    if (isSkillsChecked) activeFields.add('Skills');
    if (isCertificationChecked) activeFields.add('Certifications');
    if (isEducationChecked) activeFields.add('Education');
    if (isLanguageChecked) activeFields.add('Languages');
    if (activeFields.isEmpty) activeFields.add('Full Name');
    return activeFields;
  }

  bool isFieldEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String && value.trim().isEmpty) return true;
    if (value is List && value.isEmpty) return true;
    return false;
  }

  // Updated to optionally use filtered data if needed.
  void _applyFilters() {
    List<Map<String, dynamic>> filtered = allCVs.where((cv) {
      if (isEducationChecked &&
          (cv['Education'] == null ||
              (cv['Education'] is List && cv['Education'].isEmpty))) {
        return false;
      }

      if (isSkillsChecked &&
          (cv['Skills'] == null ||
              (cv['Skills'] is List && cv['Skills'].isEmpty))) {
        return false;
      }

      if (isCertificationChecked &&
          (cv['Certifications'] == null ||
              (cv['Certifications'] is List && cv['Certifications'].isEmpty))) {
        return false;
      }

      if (isLanguageChecked &&
          (cv['Languages'] == null ||
              (cv['Languages'] is List && cv['Languages'].isEmpty))) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        // Split the query into individual terms (ignoring extra spaces)
        final searchTerms = searchQuery
            .split(RegExp(r'\s+'))
            .where((term) => term.isNotEmpty)
            .toList();
        // Check that every term is found in at least one of the active fields
        bool matchesAllTerms = searchTerms.every((term) {
          return _getActiveFilterFields().any((field) {
            final fieldValue = (cv[field] ?? '').toString().toLowerCase();
            return fieldValue.contains(term);
          });
        });

        if (!matchesAllTerms) return false;
      }

      // Date range filter
// Date range filter
      final uploadDateValue = cv['uploadDate'];
      if (uploadDateValue != null) {
        DateTime cvDate;
        if (uploadDateValue is DateTime) {
          cvDate = uploadDateValue;
        } else if (uploadDateValue is String) {
          try {
            cvDate = DateTime.parse(uploadDateValue);
          } catch (e) {
            // If parsing fails, you might choose to skip this CV
            return true;
          }
        } else {
          return true;
        }

        if (startDate != null && cvDate.isBefore(startDate!)) {
          return false;
        }
        if (endDate != null && cvDate.isAfter(endDate!)) {
          return false;
        }
      }

      return true;
    }).toList();

    setState(() {
      displayedCVs = filtered;
    });
  }

  /// 🔹 *File Picker*
  Future<void> pickFiles() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      _showSnackbar("⚠ Permission denied!", Colors.orange);
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFiles = result.files.map((file) => File(file.path!)).toList();
      });

      for (var file in selectedFiles) {
        await runPythonScript(file.path);
      }
    }
  }

  void _processCertificationsOverview() {
    certificationCounts.clear();

    certificationCounts["Completed"] =
        allCVs.where((cv) => cv["Certifications"] != null).length;
    certificationCounts["In Progress"] =
        allCVs.where((cv) => cv["Certifications"] == null).length;
  }

  // 🔹 3. Education Timeline
  void _processEducationTimeline() {
    educationTimeline.clear();

    for (var cv in allCVs) {
      if (cv['Education'] is List) {
        for (var edu in cv['Education']) {
          if (edu is Map && edu['Degree'] is String) {
            educationTimeline.add({
              "Degree": edu['Degree'],
              "DatesAttended": edu['DatesAttended'] ?? "",
            });
          }
        }
      }
    }
  }

  // 🔹 4. Languages Proficiency
  void _processLanguagesProficiency() {
    languageCounts.clear();

    for (var cv in allCVs) {
      if (cv['Languages'] is List) {
        for (var language in cv['Languages']) {
          languageCounts[language] = (languageCounts[language] ?? 0) + 1;
        }
      }
    }
  }

  void _filterProjects() {
    List<BarChartGroupData> barGroups = [];
    Map<String, int> projectCounts = {};
    projectNames = [];

    for (var cv in allCVs) {
      if (cv['Projects'] is List) {
        for (var project in cv['Projects']) {
          if (project is Map && project['Name'] is String) {
            // Apply Project Name Filter
            bool projectMatch = selectedProjectFilter == "All Projects" ||
                project['Name'] == selectedProjectFilter;
            // Apply Technology Filter
            bool techMatch = selectedTechnologyFilter == "All Technologies" ||
                (project['Technologies'] is List &&
                    (project['Technologies'] as List).any(
                      (tech) => tech['Name'] == selectedTechnologyFilter,
                    ));

            if (projectMatch && techMatch) {
              String projectName = project['Name'];
              projectCounts[projectName] =
                  (projectCounts[projectName] ?? 0) + 1;
            }
          }
        }
      }
    }

    int index = 0;
    projectCounts.forEach((projectName, count) {
      projectNames.add(projectName);
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: Colors.blue,
              width: 20,
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
      index++;
    });

    setState(() {
      filteredBarGroups = barGroups; // Ensure this is set
    });
  } // 🔹 5. Projects Contribution

  void _processProjectsContribution() {
    projectContributions.clear();

    for (var cv in allCVs) {
      if (cv['Projects'] is List) {
        for (var project in cv['Projects']) {
          if (project is Map && project['Role'] is String) {
            projectContributions[project['Role']] =
                (projectContributions[project['Role']] ?? 0) + 1;
          }
        }
      }
    }
  }

  // 🔹 6. Job Applications Status
  void _processJobApplicationsStatus() {
    applicationStatusCounts.clear();

    applicationStatusCounts["Submitted"] = allCVs
        .where(
          (cv) =>
              cv["ApplicationTracking"] != null &&
              cv["ApplicationTracking"]["Status"] == "Submitted",
        )
        .length;
    applicationStatusCounts["Interview Scheduled"] = allCVs
        .where(
          (cv) =>
              cv["ApplicationTracking"] != null &&
              cv["ApplicationTracking"]["Status"] == "Interview Scheduled",
        )
        .length;
    applicationStatusCounts["Accepted"] = allCVs
        .where(
          (cv) =>
              cv["ApplicationTracking"] != null &&
              cv["ApplicationTracking"]["Status"] == "Accepted",
        )
        .length;
    applicationStatusCounts["Rejected"] = allCVs
        .where(
          (cv) =>
              cv["ApplicationTracking"] != null &&
              cv["ApplicationTracking"]["Status"] == "Rejected",
        )
        .length;
  }

  void _processCategoryData() {
    categoryCounts.clear();
    categoryCounts["Skills"] =
        allCVs.where((cv) => cv["Skills"] != null).length;
    categoryCounts["Certifications"] =
        allCVs.where((cv) => cv["Certifications"] != null).length;
    categoryCounts["Languages"] =
        allCVs.where((cv) => cv["Languages"] != null).length;
    categoryCounts["Education"] =
        allCVs.where((cv) => cv["Education"] != null).length;
    setState(() {}); // Refresh UI after processing
  }

  /// 🔹 *Run Python Script*

  Future<void> runPythonScript(String filePath) async {
    setState(() => isUploading = true);

    try {
      const pythonPath = 'python'; // Or 'python3'
      const scriptPath = 'assets/scripts/extract_text.py';

      Map<String, dynamic>? jsonData;

      while (true) {
        // Loop until valid data is extracted
        final result = await runExecutableArguments(pythonPath, [
          scriptPath,
          filePath,
        ]);

        if (result.exitCode == 0) {
          jsonData = jsonDecode(result.stdout.trim());

          // Check if extracted data is valid
          if (jsonData != null && jsonData.isNotEmpty) {
            jsonData["isAssigned"] = "No";
            jsonData["isArchived"] = "No";
            jsonData["uploadDate"] =
                DateFormat('yyyy-MM-dd').format(DateTime.now());
            break;
          } else {
            _showSnackbar("⚠ Retrying extraction...", Colors.orange);
            await Future.delayed(Duration(seconds: 2)); // Delay before retrying
          }
        } else {
          _showSnackbar("❌ Error running script: ${result.stderr}", Colors.red);
          return; // Exit function on error
        }
      }
      // Upload to Firestore once valid data is extracted
      await uploadDataToFirestore(jsonData!);
    } catch (e) {
      _showSnackbar("❌ Error: $e", Colors.red);
    } finally {
      setState(() => isUploading = false);
    }
  }

  /// 🔹 *Upload Data to Firestore*
  Future<void> uploadDataToFirestore(Map<String, dynamic> data) async {
    try {
      CollectionReference collection = Firestore.instance.collection('CV');
      final document = await collection.add(data);
      _showSnackbar(
        "✅ Data uploaded to Firestore: ${document.id}",
        Colors.green,
      );
      getData();
    } catch (e) {
      _showSnackbar("❌ Error uploading data: $e", Colors.red);
    }
  }

  Widget buildCategoryChart(Map<String, int> categoryCounts) {
    // Generate pie chart sections with consistent colors
    List<PieChartSectionData> sections = categoryCounts.entries.map((entry) {
      return PieChartSectionData(
        color: _getColorForCategory(entry.key),
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
              startDegreeOffset: -90, // Rotate chart for better visual
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
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getColorForCategory(entry.key),
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

  Color _getColorForCategory(String category) {
    final colorList = Colors.primaries;
    return colorList[category.hashCode % colorList.length].withOpacity(0.8);
  }

  Widget buildCertificationsOverviewChart() {
    List<PieChartSectionData> sections =
        certificationCounts.entries.map((entry) {
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

  Widget buildProjectsContributionChart() {
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
        // Animation Duration
        swapAnimationCurve: Curves.easeInOut,
      ),
    );
  }

  Widget buildLanguagesProficiencyChart() {
    Map<String, int> displayData = Map<String, int>.from(languageCounts);

    // Ensure at least 3 entries by adding placeholders
    while (displayData.length < 3) {
      displayData["Placeholder ${displayData.length + 1}"] = 0;
    }

    List<RadarDataSet> dataSets = [
      RadarDataSet(
        dataEntries: displayData.entries
            .map((entry) => RadarEntry(value: entry.value.toDouble()))
            .toList(),
        fillColor: Colors.blue.withOpacity(0.4),
        borderColor: Colors.blue,
        entryRadius: 3,
      ),
    ];

    return SizedBox(
      height: 300,
      child: RadarChart(
        RadarChartData(
          dataSets: dataSets,
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          titlePositionPercentageOffset: 0.2,
          getTitle: (index, angle) {
            return RadarChartTitle(
              text: displayData.keys.elementAt(index),
              angle: angle,
            );
          },
        ),
      ),
    );
  }

  Widget buildEducationTimelineChart() {
    List<FlSpot> spots = [];
    List<String> labels = [];

    for (int i = 0; i < educationTimeline.length; i++) {
      String dates = educationTimeline[i]['DatesAttended'] ?? '';
      String degree = educationTimeline[i]['Degree'] ?? 'Unknown';
      List<String> years = dates.split('–');

      if (years.length == 2) {
        double startYear =
            double.tryParse(years[0].trim().split(' ').last) ?? 0;
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
                      style: TextStyle(fontSize: 10),
                    ),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.red[800],
          title: Column(
            children: [
              const Text(
                'CVs Dashboard',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AssignPage()),
                );
              },
              icon: Tooltip(
                message: 'Assigned CVs', // Tooltip message
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                preferBelow: false,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.red[800]!, Colors.red[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.assignment_turned_in_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                // Trigger the animation
                _controller.forward().then((_) {
                  _controller.reset(); // Reset the animation for the next press
                });
                // Call the original function
                getData();
              },
              icon: Tooltip(
                message: 'Refresh',
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10), // Padding inside the tooltip
                preferBelow: false, // Show tooltip above the icon
                decoration: BoxDecoration(
                  color: Colors.black, // Background color
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
                textStyle: const TextStyle(
                  color: Colors.white, // Text color
                  fontSize: 14,
                ),
                child: RotationTransition(
                  turns: _rotationAnimation,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        colors: [Colors.white, Colors.redAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: const Icon(
                      Icons.refresh,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            // Color of the tab indicator
            indicatorWeight: 4.0,
            // Thickness of the indicator
            labelColor: Colors.white,
            // Color of the selected tab text
            unselectedLabelColor: Colors.white70,
            // Color of unselected tab text
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),

            unselectedLabelStyle: TextStyle(fontSize: 14),

            tabs: [Tab(text: 'Cvs'), Tab(text: "Dashboard")],
          ),
        ),
        body: Row(
          children: [
            _buildSidebarFilters(context, screenHeight),
            Expanded(
              child: TabBarView(
                children: [
                  // Data Tab: Search Bar + Grid
                  Column(
                    children: [
                      _buildSearchBar(screenWidth),
                      Expanded(child: _buildCVGrid()),
                    ],
                  ),
                  // Chart Tab
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        Center(
                          child: categoryCounts.isNotEmpty
                              ? buildCategoryChart(categoryCounts)
                              : const Text("No data available"),
                        ),
                        // Certifications Overview Chart
                        Text(
                          "Certifications Overview",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        certificationCounts.isNotEmpty
                            ? buildCertificationsOverviewChart()
                            : const Text("No certifications data available"),

                        const SizedBox(height: 100),

                        // Education Timeline Chart
                        Text(
                          "Education Timeline",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        educationTimeline.isNotEmpty
                            ? buildEducationTimelineChart()
                            : const Text("No education data available"),

                        const SizedBox(height: 20),

                        // Projects Contribution Filter Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Project Name Filter
                            DropdownButton<String>(
                              value: selectedProjectFilter,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedProjectFilter = newValue!;
                                });
                                _filterProjects(); // Apply filters when selection changes
                              },
                              items: projectList.map<DropdownMenuItem<String>>((
                                String value,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),

                            // Technology Filter
                            DropdownButton<String>(
                              value: selectedTechnologyFilter,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedTechnologyFilter = newValue!;
                                });
                                _filterProjects(); // Apply filters when selection changes
                              },
                              items:
                                  technologyList.map<DropdownMenuItem<String>>((
                                String value,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                        // Projects Contribution Chart
                        Text(
                          "Projects Contribution",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        filteredBarGroups.isNotEmpty
                            ? buildProjectsContributionChart()
                            : const Text(
                                "No project contribution data available",
                              ),

                        const SizedBox(height: 120),

                        // Languages Proficiency Chart
                        Text(
                          "Languages Proficiency",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        languageCounts.isNotEmpty
                            ? buildLanguagesProficiencyChart()
                            : const Text("No languages data available"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: StatefulBuilder(
          builder: (context, setState) {
            // Local animation controller
            final AnimationController _controller = AnimationController(
              duration: const Duration(milliseconds: 300),
              vsync: Scaffold.of(context),
            );
            // Local scale animation
            final Animation<double> _scaleAnimation = Tween<double>(
              begin: 1.0,
              end: 1.2,
            ).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            );
            // Local rotation animation
            final Animation<double> _rotationAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            );
            return ScaleTransition(
              scale: _scaleAnimation,
              child: RotationTransition(
                turns: _rotationAnimation,
                child: FloatingActionButton(
                  heroTag: "Add",
                  onPressed: () {
                    _controller.forward();
                    isUploading ? null : pickFiles();
                    _controller.reverse();
                  },
                  backgroundColor: Colors.red[800],
                  elevation: 8,
                  tooltip: 'Add CV(s)',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red[800]!, Colors.red[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: Colors.red[800]),
          child: Row(
            children: [
              const SizedBox(width: 30),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/ntgschool.png',
                  width: 80,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'NTG School',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '2025',
                textAlign: TextAlign.left,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Padding(padding: EdgeInsets.only(right: 100)),
              Text(
                " Copyright (c) 2025 NTG school .",
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              Padding(padding: EdgeInsets.only(right: 8)),
              Text(
                "All rights reserved. Use of this source code is governed by a CV manager team license.   V 1.0.2",
                style: TextStyle(color: Colors.white, fontSize: 10),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(
        top: screenWidth * 0.02,
        left: screenWidth * 0.04,
        right: screenWidth * 0.04,
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          searchQuery = value.toLowerCase();
          _applyFilters();
        },
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.red[800]),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.red[800]),
                  onPressed: () {
                    searchQuery = '';
                    searchController.clear();
                    _applyFilters();
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          hintText: 'Search for CVs...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            vertical: screenWidth * 0.015,
            horizontal: screenWidth * 0.03,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red[800]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red[800]!, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red[800]!, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFilters(BuildContext context, double screenHeight) {
    return Container(
      width: 280,
      height: screenHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 4,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Count of retrieved CVs: $cvCount',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.red[800],
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterSection(
                  title: 'Show Archived CVs',
                  value: showArchivedCVs,
                  icon: Icons.archive_outlined,
                  onChanged: (newValue) {
                    setState(() => showArchivedCVs = newValue!);
                    getData();
                    Builder(
                      builder: (context) {
                        DefaultTabController.of(context).animateTo(0);
                        return SizedBox();
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Content Filters'),
                const SizedBox(height: 16),
                _buildFilterItem(
                  title: 'Skills',
                  icon: Icons.work_outline,
                  value: isSkillsChecked,
                  onChanged: (v) => setState(() => isSkillsChecked = v!),
                ),
                _buildFilterItem(
                  title: 'Certifications',
                  icon: Icons.verified_outlined,
                  value: isCertificationChecked,
                  onChanged: (v) => setState(() => isCertificationChecked = v!),
                ),
                _buildFilterItem(
                  title: 'Education',
                  icon: Icons.school_outlined,
                  value: isEducationChecked,
                  onChanged: (v) => setState(() => isEducationChecked = v!),
                ),
                _buildFilterItem(
                  title: 'Languages',
                  icon: Icons.language_outlined,
                  value: isLanguageChecked,
                  onChanged: (v) => setState(() => isLanguageChecked = v!),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSectionHeader('Filter by date'),
                    const SizedBox(width: 55),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            startDate = null;
                            endDate = null;
                          });
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)))),
                        child: Text(
                          'Reset',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                // Start Date Picker
                TextButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        startDate = pickedDate;
                      });
                      _applyFilters();
                    }
                  },
                  child: Text(
                    startDate != null
                        ? 'Start Date: ${DateFormat('yyyy-MM-dd').format(startDate!)}'
                        : 'Select Start Date',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
                // End Date Picker
                TextButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        endDate = pickedDate;
                      });
                      _applyFilters();
                    }
                  },
                  child: Text(
                    endDate != null
                        ? 'End Date: ${DateFormat('yyyy-MM-dd').format(endDate!)}'
                        : 'Select End Date',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required bool value,
    required IconData icon,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.red[800]),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.red[800],
          ),
        ),
        trailing: Transform.scale(
          scale: 1.2,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: Colors.red[800],
            inactiveThumbColor: Colors.grey[300],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterItem({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[700], size: 22),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: value ? Colors.red[800] : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: value ? Colors.red[800]! : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: value
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCVGrid() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (displayedCVs.isEmpty) {
      return const Center(
        child: Text(
          'No data found',
          style: TextStyle(
            fontSize: 18,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        key: ValueKey(displayedCVs.length),
        padding: const EdgeInsets.all(8.0),
        child: AnimationLimiter(
          child: GridView.builder(
            controller: _scrollController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemCount: displayedCVs.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 500),
                columnCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildCVCard(displayedCVs[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCVCard(Map<String, dynamic> cv) {
    return InkWell(
      key: ValueKey(cv['id']),
      onTap: () => _navigateToDetail(cv),
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                cv["Full Name"] ?? "No Name",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[800],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                cv["Email address"] ?? "No Email",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> cv) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) =>
            CVDetailPage(cv: cv, isArchived: showArchivedCVs),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }
}
