import 'package:corr/main.dart';
import 'package:firedart/firestore/firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class CVDetailPage extends StatefulWidget {
  final Map<String, dynamic> cv;
  final bool isArchived;

  static const projectId = 'ocrcv-1e6fe';

  const CVDetailPage({super.key, required this.cv, this.isArchived = false});

  @override
  State<CVDetailPage> createState() => _CVDetailPageState();
}

bool showBackButton = true;

class _CVDetailPageState extends State<CVDetailPage>
    with TickerProviderStateMixin {
  late Map<String, dynamic> cv;

  void main() async {
    Firestore.initialize(CVDetailPage.projectId);
  }

  Future<bool> _documentExistsInArchive() async {
    final documentId = cv['id'];
    try {
      final doc = await Firestore.instance
          .collection('Archive')
          .document(documentId)
          .get();
      // If the returned map is not empty, assume the document exists in Archive.
      return doc.map.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    cv = widget.cv;
  }

  Future<void> _deleteCV() async {
    // Show confirmation dialog before deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete CV',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to delete this CV?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => showBackButton = false);
        final documentId = cv['id'];
        // Determine the collection name based on the archive state.
        final collectionName = cv['isArchived'] == 'Yes' ? 'Archive' : 'CV';
        // Delete the document from Firestore.
        await Firestore.instance
            .collection(collectionName)
            .document(documentId)
            .delete();
        Navigator.of(context).pop();
        _showSnackbar('CV deleted successfully', Colors.green);
      } catch (e) {
        _showSnackbar('Error deleting CV: $e', Colors.red);
      } finally {
        setState(() => showBackButton = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBackButton,
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
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
              onPressed: () async {
                await _deleteCV();
              },
              icon: Icon(
                Icons.delete,
                color: Colors.white,
              ))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [_buildDetailCard(context)],
        ),
      ),
      // Floating Action Buttons without blocking multiple presses.
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Archive/Unarchive Button
          StatefulBuilder(
            builder: (context, localSetState) {
              final AnimationController _controller = AnimationController(
                duration: const Duration(milliseconds: 300),
                vsync: this,
              );
              final Animation<double> _scaleAnimation = Tween<double>(
                begin: 1.0,
                end: 1.2,
              ).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeInOut,
                ),
              );
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
                    heroTag:
                        cv['isArchived'] == 'Yes' ? "Unarchive" : "Archive",
                    onPressed: showBackButton
                        ? () async {
                            await _controller.forward();
                            if (cv['isArchived'] == 'Yes') {
                              await _unarchiveCV();
                            } else {
                              await _archiveCV();
                            }
                            await _controller.reverse();
                          }
                        : null,
                    backgroundColor:
                        showBackButton ? Colors.red[800] : Colors.grey,
                    elevation: 8,
                    tooltip: cv['isArchived'] == 'Yes'
                        ? 'Unarchive CV'
                        : 'Archive CV',
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
                      child: showBackButton
                          ? Icon(
                              cv['isArchived'] == 'Yes'
                                  ? Icons.outbox_outlined
                                  : Icons.archive,
                              color: Colors.white,
                              size: 28,
                            )
                          : CircularProgressIndicator(
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Assign Button (only show if not archived)
          if (cv['isArchived'] != 'Yes') ...[
            const SizedBox(width: 10),
            StatefulBuilder(
              builder: (context, localSetState) {
                final AnimationController _controller = AnimationController(
                  duration: const Duration(milliseconds: 300),
                  vsync: this,
                );
                final Animation<double> _scaleAnimation = Tween<double>(
                  begin: 1.0,
                  end: 1.2,
                ).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeInOut,
                  ),
                );
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
                      heroTag: "Assign",
                      onPressed: showBackButton
                          ? () async {
                              await _controller.forward();
                              await _assignCV();
                              await _controller.reverse();
                            }
                          : null,
                      backgroundColor: Colors.red[800],
                      elevation: 8,
                      tooltip: 'Assign CV',
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
                        child: showBackButton
                            ? Icon(
                                Icons.assignment_ind_rounded,
                                color: Colors.white,
                                size: 28,
                              )
                            : CircularProgressIndicator(
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // Function to archive a CV
  Future<void> _archiveCV() async {
    try {
      setState(() => showBackButton = false);

      final documentId = cv['id'];
      // Fetch the current CV data from the 'CV' collection.
      final cvData =
          await Firestore.instance.collection('CV').document(documentId).get();
      // Create a new map with updated isArchived field.
      final updatedData = Map<String, dynamic>.from(cvData.map);
      updatedData['isArchived'] = 'Yes';
      // Save the updated data to the Archive collection.
      await Firestore.instance
          .collection('Archive')
          .document(documentId)
          .set(updatedData);
      // Remove the document from the 'CV' collection.
      await Firestore.instance.collection('CV').document(documentId).delete();
      // Update the local state so the UI reflects the change.
      setState(() {
        cv['isArchived'] = 'Yes';
      });

      Navigator.of(context).pop();
      _showSnackbar('CV archived successfully', Colors.green);
    } catch (e) {
      _showSnackbar('Error archiving CV: $e', Colors.red);
    } finally {
      setState(() => showBackButton = true);
    }
  }

  // Function to unarchive a CV
  Future<void> _unarchiveCV() async {
    try {
      setState(() => showBackButton = false);

      final documentId = cv['id'];
      // Fetch the CV data from the Archive collection.
      final cvData = await Firestore.instance
          .collection('Archive')
          .document(documentId)
          .get();
      // Create a new map with updated isArchived field.
      final updatedData = Map<String, dynamic>.from(cvData.map);
      updatedData['isArchived'] = 'No';
      // Move the document to the 'CV' collection using the updated data.
      await Firestore.instance
          .collection('CV')
          .document(documentId)
          .set(updatedData);
      // Delete the document from the Archive collection.
      await Firestore.instance
          .collection('Archive')
          .document(documentId)
          .delete();
      // Update the local state so the UI reflects the change.
      setState(() {
        cv['isArchived'] = 'No';
      });
      Navigator.of(context).pop();
      _showSnackbar('CV unArchived successfully', Colors.green);
    } catch (e) {
      _showSnackbar('Error unArchiving CV: $e', Colors.red);
    } finally {
      setState(() => showBackButton = true);
    }
  }

  // Function to assign a CV
  Future<void> _assignCV() async {
    try {
      setState(() => showBackButton = false);
      final documentId = cv['id'];
      // Fetch the current CV data from the 'CV' or 'Archive' collection.
      final cvData = await Firestore.instance
          .collection(widget.isArchived ? 'Archive' : 'CV')
          .document(documentId)
          .get();
      // Create a new map with updated isAssigned field.
      final updatedData = Map<String, dynamic>.from(cvData.map);
      updatedData['isAssigned'] = 'Yes';
      // Save the updated data to the Assign collection.
      await Firestore.instance
          .collection('Assign')
          .document(documentId)
          .set(updatedData);
      // Remove the document from the 'CV' or 'Archive' collection.
      await Firestore.instance
          .collection(widget.isArchived ? 'Archive' : 'CV')
          .document(documentId)
          .delete();
      // Update the local state so the UI reflects the change.
      setState(() {
        cv['isAssigned'] = 'Yes';
      });

      Navigator.of(context).pop();
      _showSnackbar('CV Assigned successfully', Colors.green);
    } catch (e) {
      _showSnackbar('Error assigning CV: $e', Colors.red);
    } finally {
      setState(() => showBackButton = true);
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
            FutureBuilder<bool>(
              future: _documentExistsInArchive(),
              builder: (context, snapshot) {
                bool archived = snapshot.data ?? false;
                return archived
                    ? Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Archived',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      )
                    : SizedBox();
              },
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
                          entry.key == "uploadDate" ||
                          entry.key == "isAssigned" ||
                          entry.key == "isArchived") {
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
                          entry.key == "isAssigned" ||
                          entry.key == "isArchived") {
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

  String formatDate(dynamic dateValue) {
    if (dateValue is DateTime) {
      return DateFormat('yyyy-MM-dd').format(dateValue);
    } else if (dateValue is String) {
      try {
        final parsedDate = DateTime.parse(dateValue);
        return DateFormat('yyyy-MM-dd').format(parsedDate);
      } catch (e) {
        return dateValue;
      }
    }
    return dateValue.toString();
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
                      Text('${entry.key}: ',
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
                          softWrap: true),
                      Text('${entry.value}',
                          style: const TextStyle(fontSize: 16), softWrap: true),
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
        DateTime parsedDate = DateTime.parse(text);
        if (text.contains(' ') || text.contains(':')) {
          return DateFormat('yyyy-MM-dd').format(parsedDate);
        }
        return null;
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
          decoration: TextDecoration.underline);
      TextStyle normalStyle = const TextStyle(fontSize: 16);
      String finalUrl = text;
      if (!urlRegex.hasMatch(text) &&
          (text.startsWith("www.") ||
              text.contains("linkedin.com") ||
              text.contains("github.com"))) {
        finalUrl = "https://$text";
      }
      String? formattedDate = tryFormatDate(text);
      if (formattedDate != null) {
        return Text(formattedDate, style: normalStyle, softWrap: true);
      }
      if (phoneRegex.hasMatch(text)) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: normalStyle, softWrap: true),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                _showSnackbar('Phone number copied to clipboard', Colors.green);
              },
            ),
          ],
        );
      }
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
          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black);
      TextStyle subHeaderStyle = const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey);
      TextStyle fieldLabelStyle = TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[800]!);

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
