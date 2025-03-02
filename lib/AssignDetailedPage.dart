import 'package:firedart/firestore/firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

String formatDate(dynamic dateValue) {
  if (dateValue is DateTime) {
    return DateFormat('yyyy-MM-dd').format(dateValue);
  } else if (dateValue is String) {
    try {
      final parsedDate = DateTime.parse(dateValue);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      return dateValue; // Return the original string if parsing fails.
    }
  }
  return dateValue.toString();
}

class AssignDetailedPage extends StatelessWidget {
  final Map<String, dynamic> cv;

  const AssignDetailedPage({super.key, required this.cv});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        title: cv.containsKey('uploadDate') && cv['uploadDate'] != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CV Details',
                      style: TextStyle(color: Colors.white)),
                  Text(
                    'Uploaded on: ${formatDate(cv['uploadDate'])}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              )
            : const Text('CV Details', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailCard(context),
          ],
        ),
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
            CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOut,
            ),
          );
          // Local rotation animation
          final Animation<double> _rotationAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOut,
            ),
          );

          return ScaleTransition(
            scale: _scaleAnimation,
            child: RotationTransition(
              turns: _rotationAnimation,
              child: FloatingActionButton(
                heroTag: "Return",
                onPressed: () {
                  // Trigger the animation
                  _controller.forward().then(
                        (_) => _controller.reverse(),
                      );
                  // Call the original function
                  _returnCVtocollictionCVS(context);
                },
                backgroundColor: Colors.red[800],
                elevation: 8,
                tooltip: 'Return CV to Collection',
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
                  child: const Icon(
                    Icons.assignment_return,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _returnCVtocollictionCVS(BuildContext context) async {
    try {
      final documentId = cv['id'];

      // Fetch the current CV data from the 'Assign' collection.
      final cvData = await Firestore.instance
          .collection('Assign')
          .document(documentId)
          .get();

      // Create a new map with updated isAssigned field.
      final updatedData = Map<String, dynamic>.from(cvData.map);
      updatedData['isAssigned'] = 'No';

      // Save the updated data to the CV collection.
      await Firestore.instance
          .collection('CV')
          .document(documentId)
          .set(updatedData);

      // Remove the document from the 'Assign' collection.
      await Firestore.instance
          .collection('Assign')
          .document(documentId)
          .delete();

      // Update the local state so the UI reflects the change.
      // Since this is a StatelessWidget, you cannot use setState.
      // You can use a callback or other state management solution to update the UI.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CV returned successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error return CV: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetailCard(BuildContext context) {
    final sortedEntries = cv.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    final halfLength = (sortedEntries.length / 2).ceil();
    final firstColumnEntries = sortedEntries.sublist(0, halfLength);
    final secondColumnEntries = sortedEntries.sublist(halfLength);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cv['isAssigned'] == "Yes")
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Assigned',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: firstColumnEntries.map((entry) {
                      if (entry.key == "id" ||
                          entry.key == 'uploadDate' ||
                          entry.key == "isAssigned") {
                        return const SizedBox();
                      }
                      return _buildDetailRow(context, entry.key, entry.value);
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: secondColumnEntries.map((entry) {
                      if (entry.key == "id" ||
                          entry.key == 'uploadDate' ||
                          entry.key == "isAssigned") {
                        return const SizedBox();
                      }
                      return _buildDetailRow(context, entry.key, entry.value);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, dynamic value) {
    if (value == null ||
        (value is String && value.contains("not provided")) ||
        (value is String && value.contains("dont have any Certifications"))) {
      return const SizedBox();
    }

    Widget buildMapWidget(BuildContext context, Map map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: map.entries.map<Widget>((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(fontSize: 16)),
                Flexible(
                  fit: FlexFit.loose,
                  child: Wrap(
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.bold),
                        softWrap: true,
                      ),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(fontSize: 16),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    String? tryFormatDate(String text) {
      try {
        // This will throw if the text is not a valid ISO date (with or without time)
        DateTime parsedDate = DateTime.parse(text);
        return DateFormat('yyyy-MM-dd').format(parsedDate);
      } catch (e) {
        return null;
      }
    }

    Widget buildValueText(BuildContext context, String text) {
      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      final urlRegex = RegExp(r'^(http|https):\/\/');
      final phoneRegex = RegExp(r'^\+?[0-9\s\-\(\)]+$');

      TextStyle linkStyle = const TextStyle(
        fontSize: 16,
        color: Colors.blue,
        decoration: TextDecoration.underline,
      );
      TextStyle normalStyle = const TextStyle(fontSize: 16);

      // Ensure URLs start with https:// if necessary
      String finalUrl = text;
      if (!urlRegex.hasMatch(text) &&
          (text.startsWith("www.") ||
              text.contains("linkedin.com") ||
              text.contains("github.com"))) {
        finalUrl = "https://$text";
      }

      // Try to format the text as a date.
      String? formattedDate = tryFormatDate(text);
      if (formattedDate != null) {
        // If the text is a valid date, display it formatted.
        return Text(formattedDate, style: normalStyle, softWrap: true);
      }

      // Check if the text is a phone number.
      if (phoneRegex.hasMatch(text)) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: normalStyle, softWrap: true),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                _showSnackbar(
                    'Phone number copied to clipboard', Colors.green, context);
              },
            ),
          ],
        );
      }

      // Check if the text is a URL.
      if (urlRegex.hasMatch(finalUrl)) {
        return InkWell(
          onTap: () async {
            final uri = Uri.parse(finalUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              debugPrint('Could not launch $finalUrl');
            }
          },
          child: Text(text, style: linkStyle, softWrap: true),
        );
      }

      // Check if the text is an email.
      if (emailRegex.hasMatch(text)) {
        return InkWell(
          onTap: () async {
            final emailUri = Uri(scheme: 'mailto', path: text);
            if (await canLaunchUrl(emailUri)) {
              await launchUrl(emailUri);
            } else {
              debugPrint('Could not launch email client for $text');
            }
          },
          child: Text(text, style: linkStyle, softWrap: true),
        );
      }
      // Default: plain text.
      return Text(text, style: normalStyle, softWrap: true);
    }

    Widget buildListItem(BuildContext context, dynamic item) {
      if (item is Map) {
        return Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: buildMapWidget(context, item),
        );
      } else {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("• ", style: TextStyle(fontSize: 16)),
            Expanded(child: buildValueText(context, item.toString())),
          ],
        );
      }
    }

    Widget buildLabel(String label) {
      TextStyle headerStyle = const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      );
      TextStyle subHeaderStyle = const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      );
      TextStyle fieldLabelStyle = TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.red[800]!,
      );

      String lowerLabel = label.toLowerCase();
      if (lowerLabel.contains("header") && !lowerLabel.contains("sub")) {
        return Text(label, style: headerStyle);
      } else if (lowerLabel.contains("subheader") ||
          lowerLabel.contains("sub")) {
        return Text(label, style: subHeaderStyle);
      } else {
        return Text('$label:', style: fieldLabelStyle);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLabel(label),
          const SizedBox(height: 4),
          if (value is List)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: value
                  .map<Widget>(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: buildListItem(context, item),
                    ),
                  )
                  .toList(),
            )
          else if (value is Map)
            buildMapWidget(context, value)
          else
            buildValueText(context, value.toString()),
        ],
      ),
    );
  }
}

void _showSnackbar(String message, Color color, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    ),
  );
}
