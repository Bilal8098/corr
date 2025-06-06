class DataProcessing {
  // 🔹 Process Category Data


  // 🔹 Process Certifications Overview
  static Map<String, int> processCertificationsOverview(List<Map<String, dynamic>> allCVs) {
    Map<String, int> certificationCounts = {};
    certificationCounts["Completed"] =
        allCVs.where((cv) => cv["Certifications"] != null).length;
    certificationCounts["In Progress"] =
        allCVs.where((cv) => cv["Certifications"] == null).length;
    return certificationCounts;
  }

  // 🔹 Process Education Timeline
  static List<Map<String, String>> processEducationTimeline(List<Map<String, dynamic>> allCVs) {
    List<Map<String, String>> educationTimeline = [];
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
    return educationTimeline;
  }
  static Map<String, double> processLanguagesAverage(List<Map<String, dynamic>> allCVs) {
    Map<String, double> languageScores = {};
    Map<String, int> languageCounts = {};
    int cvWithLanguagesCount = 0;

    print("🚀 Processing CVs for languages... Total CVs: ${allCVs.length}");

    for (var cv in allCVs) {
      if (!cv.containsKey('Languages')) {
        print("❌ 'Languages' field is missing in one CV!");
        continue;
      }

      var languages = cv['Languages'];
      Map<String, String> convertedMap = {};

      // **تحويل البيانات حسب النوع**
      if (languages is Map<String, dynamic>) {
        print("🎯 'Languages' is a Map: $languages");
        convertedMap = Map<String, String>.from(languages);
      }
      else if (languages is List) {
        print("⚠ 'Languages' is a List! Converting...");
        for (var entry in languages) {
          if (entry is String) {
            RegExp regex = RegExp(r'(\w+)\s*\((.+?)\)');
            Match? match = regex.firstMatch(entry);
            if (match != null) {
              convertedMap[match.group(1)!] = match.group(2)!;
            }
          }
        }
      }
      else if (languages is String) {
        print("⚠ 'Languages' is a String! Converting...");
        List<String> entries = languages.split(", ");
        for (var entry in entries) {
          RegExp regex = RegExp(r'(\w+)\s*\((.+?)\)');
          Match? match = regex.firstMatch(entry);
          if (match != null) {
            convertedMap[match.group(1)!] = match.group(2)!;
          }
        }
      }
      else {
        print("❌ 'Languages' format not recognized: ${languages.runtimeType}");
        continue;
      }

      if (convertedMap.isNotEmpty) {
        cvWithLanguagesCount++;
      }

      for (var entry in convertedMap.entries) {
        String language = entry.key;
        String proficiency = entry.value.toUpperCase();

        double score = getProficiencyScore(proficiency);

        languageScores.update(language, (value) => value + score, ifAbsent: () => score);
        languageCounts.update(language, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    if (cvWithLanguagesCount == 0) {
      print("⚠ No valid CVs with language data found.");
      return {};
    }

    Map<String, double> languageAverages = {};
    languageScores.forEach((language, totalScore) {
      double avg = totalScore / languageCounts[language]!;
      languageAverages[language] = avg;
      print("📊 Language: $language, Average Proficiency: ${avg.toStringAsFixed(2)}");
    });

    return languageAverages;
  }

  /// 🔹 Convert Proficiency Level to Numeric Score
  static double getProficiencyScore(String proficiency) {
    switch (proficiency.toUpperCase()) {
      case "NATIVE":
        return 1.0;
      case "FLUENT":
      case "C1":
        return 0.9;
      case "B2":
        return 0.8;
      case "INTERMEDIATE":
      case "B1":
        return 0.7;
      case "A2":
        return 0.5;
      case "A1":
        return 0.3;
      default:
        return 0.2; // Default for unknown levels
    }
  }

  /// 🔹 Categorize Proficiency Levels for Colors
  static String getCategory(double score) {
    if (score >= 0.9) return "Native";
    if (score >= 0.7) return "Fluent";
    if (score >= 0.5) return "Intermediate";
    return "Beginner";
  }
  // 🔹 Process Projects Contribution
  static Map<String, int> processProjectsContribution(List<Map<String, dynamic>> allCVs) {
    Map<String, int> projectContributions = {};
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
    return projectContributions;
  }

  // 🔹 Process Job Applications Status
  static Map<String, int> processJobApplicationsStatus(List<Map<String, dynamic>> allCVs) {
    Map<String, int> applicationStatusCounts = {};
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
    return applicationStatusCounts;
  }
}