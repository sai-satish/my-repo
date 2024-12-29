import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trip_swift/components/highlights_tile.dart';
import 'package:trip_swift/popular_destinations.dart';
import 'package:trip_swift/testing_features/view_schedule.dart';
import 'package:trip_swift/trip_hightlight_photos.dart';
import 'components/location_detailed_view.dart';
import 'components/ticket_tile.dart'; // Import the TicketTile widget
import 'highligts_data.dart';
// import 'tickets_data.dart'; // Ticket data source

void main() {
  runApp(const MaterialApp(home: HomeScreen()));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> fetchHighlights() async {
    try {
      // Fetch data from Firestore
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('locations').get();

      return snapshot.docs.map((doc) {
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
    } catch (e) {
      throw Exception('Failed to load highlights: $e');
    }
  }
  Future<List<Map<String, dynamic>>> fetchTickets() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('tickets').get();
      List<Map<String, dynamic>> ticketsList = [];
      for (var doc in snapshot.docs) {
        ticketsList.add(doc.data() as Map<String, dynamic>);
      }
      return ticketsList;
    } catch (e) {
      throw Exception("Error fetching tickets: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Popular Destinations Section
            _buildSectionHeader(
              context,
              title: "Popular Destinations",
              onSeeMoreTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PopularDestinationsScreen()),
                );
              },
              isButtonRequired: true,
            ),
            SizedBox(
              height: screenSize.height * 0.37 > 240 ? 255:screenSize.height * 0.37,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchHighlights(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No highlights found.'));
                  } else {
                    final highlights = snapshot.data!;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final highlight = highlights[index];
                        return HighLightTile(
                          width: screenSize.width * 0.4,
                          imageUrl: highlight['image'],
                          title: highlight['name'],
                          subtitle: highlight['description'],
                          price: highlight['price'],
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
                        );
                      },
                    );
                  }
                },
              ),
            ),
            // Highlights Section
            _buildSectionHeader(
              context,
              title: "Highlights",
              onSeeMoreTap: () {},
              isButtonRequired: true,
            ),
            SizedBox(
              height: screenSize.height * 0.37 > 240 ? 255:screenSize.height * 0.37,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04),
                itemCount: highlights.length,
                itemBuilder: (context, index) {
                  final highlight = highlights[index];
                  return HighLightTile(
                    width: screenSize.width * 0.4,
                    imageUrl: highlight["photoUrl"] ?? "",
                    title: highlight["location"] ?? "",
                    subtitle: "Visited by ${highlight["userId"]}",
                    price: highlight['price'] ?? "",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HighlightsScreen(
                            locationName: "Eiffel Tower",
                            imageUrls: highlightImages,
                            visitDate: DateTime.now(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // TravelPlanner(),
            // View Tickets Section
            _buildSectionHeader(
              context,
              title: "Your Tickets",
              onSeeMoreTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ViewTickets()),
                );
              },
              isButtonRequired: true,
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchTickets(), // Call the fetchTickets function
              builder: (context, snapshot) {
                // Show CircularProgressIndicator while waiting for data
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Show an error message if fetching fails
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                // Display tickets if data is loaded
                if (snapshot.hasData && snapshot.data != null) {
                  final tickets = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return TicketTile(
                        startDate: ticket["startDate"] ?? "",
                        startTime: ticket["startTime"] ?? "",
                        endDate: ticket["endDate"] ?? "",
                        endTime: ticket["endTime"] ?? "",
                        startLocation: ticket["startLocation"] ?? "",
                        endLocation: ticket["endLocation"] ?? "",
                        totalDuration: ticket["totalDuration"] ?? "",
                        ticketType: ticket["ticketType"] ?? "",
                        imagePath: ticket["imagePath"] ?? "",
                      );
                    },
                  );
                }

                // Default case if no data is available
                return const Center(child: Text("No tickets available"));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, {
        required String title,
        required VoidCallback onSeeMoreTap,
        required bool isButtonRequired,
      }) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.04,
        vertical: screenSize.height * 0.01,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          isButtonRequired
              ? TextButton(
            onPressed: onSeeMoreTap,
            child: const Text(
              "See More",
              style: TextStyle(color: Colors.blueAccent),
            ),
          )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
class ViewTickets extends StatelessWidget {
  ViewTickets({super.key});


  void AddTicketPopup(BuildContext context) async{

    final TextEditingController emailController = TextEditingController();
    final TextEditingController startDateController = TextEditingController();
    final TextEditingController startTimeController = TextEditingController();
    final TextEditingController endDateController = TextEditingController();
    final TextEditingController endTimeController = TextEditingController();
    final TextEditingController startLocationController = TextEditingController();
    final TextEditingController endLocationController = TextEditingController();
    final TextEditingController totalDurationController = TextEditingController();
    final TextEditingController ticketTypeController = TextEditingController();
    final TextEditingController imagePathController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isWideScreen = screenWidth > 600; // Check for tablet/desktop screens

        return AlertDialog(
          title: Text(
            'Add New Ticket',
            style: TextStyle(fontSize: isWideScreen ? 24 : 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // buildInputField(emailController, "User Email", isWideScreen),
                buildInputField(startDateController, "Start Date", isWideScreen),
                buildInputField(startTimeController, "Start Time", isWideScreen),
                buildInputField(endDateController, "End Date", isWideScreen),
                buildInputField(endTimeController, "End Time", isWideScreen),
                buildInputField(startLocationController, "Start Location", isWideScreen),
                buildInputField(endLocationController, "End Location", isWideScreen),
                buildInputField(totalDurationController, "Total Duration", isWideScreen),
                buildInputField(ticketTypeController, "Ticket Type", isWideScreen),
                // buildInputField(imagePathController, "Image Path", isWideScreen),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(fontSize: isWideScreen ? 18 : 14)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add Ticket', style: TextStyle(fontSize: isWideScreen ? 18 : 14)),
              onPressed: () async {
                try {
                  await addTicketToFirestore({
                    "currentUserEmail": emailController.text.trim(),
                    "startDate": startDateController.text.trim(),
                    "startTime": startTimeController.text.trim(),
                    "endDate": endDateController.text.trim(),
                    "endTime": endTimeController.text.trim(),
                    "startLocation": startLocationController.text.trim(),
                    "endLocation": endLocationController.text.trim(),
                    "totalDuration": totalDurationController.text.trim(),
                    "ticketType": ticketTypeController.text.trim(),
                    "imagePath": imagePathController.text.trim(),
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ticket added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding ticket: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildInputField(TextEditingController controller, String label, bool isWideScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          labelStyle: TextStyle(fontSize: isWideScreen ? 18 : 14),
        ),
      ),
    );
  }

  Future<void> addTicketToFirestore(Map<String, String> ticketData) async {
    final ticketsCollection = FirebaseFirestore.instance.collection('tickets');
    await ticketsCollection.add(ticketData);
  }
  Future<List<Map<String, dynamic>>> fetchTickets() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('tickets').get();
      List<Map<String, dynamic>> ticketsList = [];
      for (var doc in snapshot.docs) {
        ticketsList.add(doc.data() as Map<String, dynamic>);
      }
      return ticketsList;
    } catch (e) {
      throw Exception("Error fetching tickets: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: ()=>AddTicketPopup,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchTickets(), // Call the fetchTickets function
        builder: (context, snapshot) {
          // Show CircularProgressIndicator while waiting for data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show an error message if fetching fails
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // Display tickets if data is loaded
          if (snapshot.hasData && snapshot.data != null) {
            final tickets = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return TicketTile(
                  startDate: ticket["startDate"] ?? "",
                  startTime: ticket["startTime"] ?? "",
                  endDate: ticket["endDate"] ?? "",
                  endTime: ticket["endTime"] ?? "",
                  startLocation: ticket["startLocation"] ?? "",
                  endLocation: ticket["endLocation"] ?? "",
                  totalDuration: ticket["totalDuration"] ?? "",
                  ticketType: ticket["ticketType"] ?? "",
                  imagePath: ticket["imagePath"] ?? "",
                );
              },
            );
          }

          // Default case if no data is available
          return const Center(child: Text("No tickets available"));
        },
      ),
    );
  }



}

