import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trip_swift/components/photo_grid.dart';
import 'package:trip_swift/components/review_input.dart';
// import 'package:trip_swift/theme/theme.dart';  // Assuming you have a custom theme file

class LocationDetailScreen extends StatefulWidget {
  final String documentId;

  const LocationDetailScreen({
    Key? key,
    required this.documentId,
  }) : super(key: key);

  @override
  _LocationDetailScreenState createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  int _currentIndex = 0;
  final List<String> _tabs = ["Overview", "Photo", "Review", "Places Nearby"];
  List<String> _photos = [];
  List<Map<String, dynamic>> _reviews = [];

  bool _isLoading = true;
  Map<String, dynamic>? _locationData; // Make it nullable
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('locations')
          .doc(widget.documentId)
          .get();

      if (snapshot.exists) {
        setState(() {
          _locationData = snapshot.data() as Map<String, dynamic>?;
          _isLoading = false;
        });
        _fetchPhotos();
        _fetchReviews();
      } else {
        setState(() {
          _isLoading = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Location not found."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching location data: $e");
    }
  }

  Future<void> _fetchPhotos() async {
    try {
      QuerySnapshot photoSnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .doc(widget.documentId)
          .collection('photos')
          .get();

      List<String> photoUrls = photoSnapshot.docs
          .map((doc) => doc['url'] as String)
          .toList();

      setState(() {
        _photos = photoUrls;
      });
    } catch (e) {
      print("Error fetching photos: $e");
    }
  }

  Future<void> _fetchReviews() async {
    try {
      QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .doc(widget.documentId)
          .collection('reviews')
          .get();

      List<Map<String, dynamic>> reviews = reviewSnapshot.docs
          .map((doc) {
        return {
          'name': doc['name'] ?? 'Anonymous',
          'rating': doc['rating'] ?? 0.0,
          'comment': doc['comment'] ?? 'No comment',
        };
      })
          .toList();

      setState(() {
        _reviews = reviews;
      });
    } catch (e) {
      print("Error fetching reviews: $e");
    }
  }

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
  }

  Widget _buildTabContent() {
    switch (_currentIndex) {
      case 0:
        return _buildOverviewSection();
      case 1:
        return _isLoading
            ? const Center(child: CircularProgressIndicator())
            : PhotoGrid(photoPaths: _photos);
      case 2:
        return _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildReviewSection(_reviews);
      default:
        return const Center(
          child: Text(
            "Community Section (Coming Soon)",
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }

  Widget _buildOverviewSection() {
    if (_locationData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            _locationData?['description'] ?? 'No description available',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildInfoRow("Opening hours", _locationData?['opening_hours'] ?? 'N/A', Colors.greenAccent),
          _buildInfoRow("Type", _locationData?['type'] ?? 'N/A', Colors.blueAccent),
          _buildInfoRow("Price", _locationData?['price'] ?? 'N/A', Colors.amber),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(color: valueColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(List<Map<String, dynamic>> reviews) {
    return Column(
      children: [
        ReviewInputBox(),
        Expanded(
          child: ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return ListTile(
                title: Text(review['name'], style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
                subtitle: Text(review['comment'], style: TextStyle(color: Colors.grey[400])),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(review['rating'].toString(), style: const TextStyle(color: Colors.white)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    double screenHeight = screenSize.height;
    double screenWidth = screenSize.width;

    if (_locationData == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(child: CircularProgressIndicator(color: Colors.green,)), // Circular indicator while data is being fetched
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Column(
          children: [
            // Top Section: Image and Details
            Stack(
              children: [
                _isLoading
                    ? const Center(child: CircularProgressIndicator()) // Loading indicator while the image is fetched
                    : Image.network(
                  _locationData?['image'] ?? '',
                  height: screenHeight * 0.3, // Adaptive image height
                  width: screenWidth, // Use full width
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : Colors.white,
                      size: 28,
                    ),
                    onPressed: _toggleLike,
                  ),
                ),
              ],
            ),
            // Tab Bar
            Container(
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_tabs.length, (index) {
                  return GestureDetector(
                    onTap: () => _changeTab(index),
                    child: Column(
                      children: [
                        Text(
                          _tabs[index],
                          style: TextStyle(
                            color: _currentIndex == index ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.04, // Adaptive font size
                          ),
                        ),
                        if (_currentIndex == index)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            height: 2,
                            width: screenWidth * 0.1, // Responsive width for indicator
                            color: Colors.amber,
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }
}
