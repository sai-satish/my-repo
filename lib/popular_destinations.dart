import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'components/location_detailed_view.dart';
import 'components/popular_destination_tile.dart';

class PopularDestinationsScreen extends StatelessWidget {
  const PopularDestinationsScreen({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> fetchHighlights() async {
    try {
      // Fetch data from Firestore (assuming the collection is named 'locations')
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('locations').get();

      // Map the data into a list of maps
      List<Map<String, dynamic>> highlights = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'image': doc['image'],
          'name': doc['name'],
          'description': doc['description'],
          'opening_time': doc['opening_time'],
          'closing_time': doc['closing_time'],
          'price': doc['price'],
        };
      }).toList();

      return highlights;
    } catch (e) {
      throw Exception('Failed to load highlights: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Popular Destinations",
          style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchHighlights(), // Fetch data from Firebase
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No highlights found.'));
          } else {
            final highlights = snapshot.data!;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.03),
              child: GridView.builder(
                padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: (screenSize.width > 600) ? 3 : 2, // Responsive grid
                  crossAxisSpacing: screenSize.width * 0.03,
                  mainAxisSpacing: screenSize.height * 0.02,
                  childAspectRatio: 0.65, // Adjust child aspect ratio for responsive tiles
                ),
                itemCount: highlights.length,
                itemBuilder: (context, index) {
                  final highlight = highlights[index];
                  final rating = (highlight['reviews'] != null && highlight['reviews'].isNotEmpty)
                      ? highlight['reviews'][0]['rating']
                      : 0.0;

                  return Padding(
                    padding: EdgeInsets.only(bottom: screenSize.height * 0.01),
                    child: DestinationTile(
                      width: screenSize.width * 0.4, // Responsive width
                      imageUrl: highlight['image'],
                      title: highlight['name'],
                      description: highlight['description'],
                      price: highlight['price'],
                      rating: rating,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationDetailScreen(
                              documentId: highlight["id"],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
