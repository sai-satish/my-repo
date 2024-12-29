import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MaterialApp(home: TravelPlanner()));
}

class TravelPlanner extends StatefulWidget {
  const TravelPlanner({Key? key}) : super(key: key);

  @override
  _TravelPlannerState createState() => _TravelPlannerState();
}

class _TravelPlannerState extends State<TravelPlanner> {
  List<Map<String, dynamic>> itinerary = [];
  String? currentUserEmail;

  @override
  void initState() {
    super.initState();
    fetchUserEmail();
  }

  Future<void> fetchUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUserEmail = prefs.getString('currentUserEmail');
    fetchItinerary();
  }

  Future<void> fetchItinerary() async {
    if (currentUserEmail == null) return;

    // Fetch the document with the current user's email as the document ID
    final userDoc = await FirebaseFirestore.instance
        .collection('itineraries')
        .doc(currentUserEmail)
        .get();

    if (userDoc.exists) {
      setState(() {
        itinerary = List<Map<String, dynamic>>.from(userDoc['days'] ?? []);
      });
    } else {
      setState(() {
        itinerary = [];
      });
    }
  }

  Future<void> addActivity(String date, Map<String, dynamic> activity) async {
    if (currentUserEmail == null) return;

    // Find the matching day in the local itinerary
    final dayIndex = itinerary.indexWhere((day) => day['date'] == date);

    if (dayIndex != -1) {
      // Update existing day
      itinerary[dayIndex]['activities'].add(activity);
    } else {
      // Add a new day plan
      itinerary.add({
        'date': date,
        'day': itinerary.length + 1,
        'activities': [activity],
      });
    }

    // Update Firestore document
    await FirebaseFirestore.instance
        .collection('itineraries')
        .doc(currentUserEmail)
        .set({'days': itinerary});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Travel Planner"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddActivityDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: itinerary.length,
        itemBuilder: (context, index) {
          final dayPlan = itinerary[index];
          return _buildDayPlan(context, dayPlan);
        },
      ),
    );
  }

  Widget _buildDayPlan(BuildContext context, Map<String, dynamic> dayPlan) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Day ${dayPlan['day']} (${dayPlan['date']})",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayPlan['activities'].length,
                separatorBuilder: (context, index) => const Divider(color: Colors.grey),
                itemBuilder: (context, activityIndex) {
                  final activity = dayPlan['activities'][activityIndex];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          const CircleAvatar(
                            radius: 6,
                            backgroundColor: Colors.teal,
                          ),
                          if (activityIndex != dayPlan['activities'].length - 1)
                            Container(
                              width: 2,
                              height: 40,
                              color: Colors.teal,
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${activity['start_time']} - ${activity['end_time']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity['place'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddActivityDialog(BuildContext context) {
    final TextEditingController dateController = TextEditingController();
    final TextEditingController startTimeController = TextEditingController();
    final TextEditingController endTimeController = TextEditingController();
    final TextEditingController placeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Activity"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: dateController, decoration: const InputDecoration(labelText: "Date")),
              TextField(controller: startTimeController, decoration: const InputDecoration(labelText: "Start Time")),
              TextField(controller: endTimeController, decoration: const InputDecoration(labelText: "End Time")),
              TextField(controller: placeController, decoration: const InputDecoration(labelText: "Place")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                addActivity(
                  dateController.text,
                  {
                    'start_time': startTimeController.text,
                    'end_time': endTimeController.text,
                    'place': placeController.text,
                  },
                );
                Navigator.of(context).pop();
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }
}
