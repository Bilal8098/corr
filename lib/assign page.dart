import 'package:flutter/material.dart';
import 'package:firedart/firestore/firestore.dart';
import 'AssignDetailedPage.dart';

class AssignPage extends StatefulWidget {
  @override
  _AssignPageState createState() => _AssignPageState();
}

class _AssignPageState extends State<AssignPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> assignedCVs = [];
  bool isLoading = false;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    getAssignedData();
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the animation controller
    super.dispose();
  }

  Future<void> getAssignedData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final querySnapshot = await Firestore.instance.collection('Assign').get();
      assignedCVs = querySnapshot.map((doc) {
        final data = doc.map;
        return {"id": doc.id, ...data};
      }).toList();
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains("Quota exceeded")) {
        _showSnackbar("⚠ Firestore quota exceeded! Please try again later",
            Colors.red, context);
      } else if(errorMessage.contains('Error connecting')){
        _showSnackbar("No internet connection", Colors.red, context);
      } 
      else {
        _showSnackbar(
            "⚠ Error fetching data: $errorMessage", Colors.red, context);
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Assigned CVs', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Trigger the animation
              _controller.forward().then((_) {
                _controller.reset(); // Reset the animation for the next press
              });
              // Call the original function
              getAssignedData();
            },
            icon: Tooltip(
              message: 'Refresh',
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10), // Padding inside the tooltip
              preferBelow: false, // Show tooltip above the icon
              decoration: BoxDecoration(
                color: Colors.red[800], // Background color
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
        ],
        backgroundColor: Colors.red[800],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red))
          : assignedCVs.isEmpty
              ? Center(
                  child: Text(
                    'No assigned CVs found',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 1200 ? 4 : 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: assignedCVs.length,
                    itemBuilder: (context, index) {
                      return _buildCVCard(assignedCVs[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildCVCard(Map<String, dynamic> cv) {
    return InkWell(
      onTap: () => _navigateToDetail(cv),
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  void _navigateToDetail(Map<String, dynamic> cv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AssignDetailedPage(cv: cv), // Navigate to the new page
      ),
    );
  }
}
