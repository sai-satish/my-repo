import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpcomingScheduleScreen extends StatefulWidget {
  @override
  _UpcomingScheduleScreenState createState() => _UpcomingScheduleScreenState();
}

class _UpcomingScheduleScreenState extends State<UpcomingScheduleScreen> {
  late Size screenSize;
  bool isInitialized = false;
  String? currentUserEmail;
  Map<String, List<Map<String, dynamic>>> events = {};

  @override
  void initState() {
    super.initState();
    fetchUserEmailAndSchedule();
  }

  Future<void> fetchUserEmailAndSchedule() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUserEmail = prefs.getString('currentUserEmail');
    if (currentUserEmail != null) {
      fetchSchedule();
    }
  }

  Future<void> fetchSchedule() async {
    try {
      final scheduleDoc = FirebaseFirestore.instance.collection('schedules').doc(currentUserEmail);
      final snapshot = await scheduleDoc.get();

      if (snapshot.exists) {
        // Safely parse and validate the 'schedule' field
        final rawSchedule = snapshot.data()?['schedule'];
        if (rawSchedule is Map<String, dynamic>) {
          setState(() {
            events = rawSchedule.map<String, List<Map<String, dynamic>>>((key, value) {
              if (value is List && value.every((item) => item is Map<String, dynamic>)) {
                return MapEntry(key, List<Map<String, dynamic>>.from(value));
              } else {
                return MapEntry(key, []);
              }
            });
          });
        } else {
          // If 'schedule' is not a valid map, initialize an empty schedule
          setState(() {
            events = {};
          });
        }
      } else {
        // If the document doesn't exist, initialize it with an empty schedule
        setState(() {
          events = {};
        });

        // Create the document in Firestore with an empty schedule field
        await scheduleDoc.set({
          'schedule': {},
        });
      }
    } catch (e) {
      // Handle any unexpected errors
      print("Error fetching schedule: $e");
      setState(() {
        events = {};
      });
    }
  }



  Future<void> updateScheduleInFirestore() async {
    if (currentUserEmail == null) return;

    final scheduleDoc = FirebaseFirestore.instance.collection('schedules').doc(currentUserEmail);

    // Check if the document exists
    final snapshot = await scheduleDoc.get();

    if (!snapshot.exists) {
      // If the document doesn't exist, create a new one with an empty schedule
      await scheduleDoc.set({
        'schedule': events,
      }, SetOptions(merge: true)); // Merge to ensure existing data isn't overwritten
    } else {
      // If the document exists, simply update the schedule field
      await scheduleDoc.update({
        'schedule': events,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!isInitialized) {
      screenSize = MediaQuery.of(context).size;
      isInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upcoming Schedule"),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 1,
      ),
      body: events.isEmpty
          ? Center(
        child: Text(
          "No upcoming events",
          style: theme.textTheme.bodyMedium,
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.symmetric(
          vertical: screenSize.height * 0.02,
          horizontal: screenSize.width * 0.04,
        ),
        itemCount: events.keys.length,
        itemBuilder: (context, index) {
          final dateKey = events.keys.elementAt(index);
          final dayEvents = events[dateKey]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Padding(
                padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.01),
                child: Text(
                  dateKey,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Event List
              ...dayEvents.map<Widget>((event) {
                return Dismissible(
                  key: Key(event["title"]),
                  direction: DismissDirection.startToEnd,
                  background: Container(
                    color: theme.colorScheme.error,
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.05),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Delete Event"),
                        content: const Text("Are you sure you want to delete this event?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    setState(() {
                      dayEvents.remove(event);
                    });
                    updateScheduleInFirestore();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Event deleted")),
                    );
                  },
                  child: GestureDetector(
                    onTap: () => _showEventDetails(event),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: screenSize.height * 0.01),
                      decoration: BoxDecoration(
                        color: _getEventColor(event["category"], event["priority"]).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: event.containsKey("icon")
                            ? Icon(event["icon"], color: _getEventColor(event["category"], event["priority"]))
                            : null,
                        title: Text(
                          event["title"],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          event["time"],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
        onPressed: () => _showAddEventDialog(context),
      ),
    );
  }

  void _showEventDetails(Map<String, dynamic> event) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event["title"]),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Time: ${event["time"]}", style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text("Category: ${event["category"]}", style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text("Priority: ${event["priority"]}", style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text("Details: ${event["details"] ?? 'No details available'}", style: theme.textTheme.bodyMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String title = '';
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String category = 'Personal';
    String priority = 'Low';
    String details = ''; // Added details field

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text("Add Event"),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Title
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Title",
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    validator: (value) => value == null || value.isEmpty ? "Title is required" : null,
                    onSaved: (value) => title = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  // Date Picker
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Date",
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    readOnly: true,
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    },
                    validator: (value) => selectedDate == null ? "Date is required" : null,
                    controller: TextEditingController(
                      text: selectedDate != null
                          ? DateFormat('EEE, dd MMM yyyy').format(selectedDate!)
                          : '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Time Picker
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Time",
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    readOnly: true,
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      setState(() {
                        selectedTime = pickedTime;
                      });
                    },
                    validator: (value) => selectedTime == null ? "Time is required" : null,
                    controller: TextEditingController(
                      text: selectedTime != null
                          ? selectedTime!.format(context)
                          : '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(labelText: "Category"),
                    items: ['Personal', 'Work', 'Other'].map((value) {
                      return DropdownMenuItem(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (value) => setState(() => category = value!),
                    validator: (value) => value == null ? "Category is required" : null,
                  ),
                  const SizedBox(height: 16),
                  // Priority Dropdown
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: InputDecoration(labelText: "Priority"),
                    items: ['Low', 'Medium', 'High'].map((value) {
                      return DropdownMenuItem(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (value) => setState(() => priority = value!),
                    validator: (value) => value == null ? "Priority is required" : null,
                  ),
                  const SizedBox(height: 16),
                  // Details TextField
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Details (Optional)",
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    onSaved: (value) => details = value ?? '',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  final dateKey = DateFormat('EEE, dd MMM yyyy').format(selectedDate!);
                  final eventTime = selectedTime != null
                      ? selectedTime!.format(context)
                      : 'No time set';

                  final newEvent = {
                    "title": title,
                    "time": eventTime,
                    "category": category,
                    "priority": priority,
                    "details": details,
                    // Do not store the color, determine dynamically in UI
                  };

                  setState(() {
                    if (!events.containsKey(dateKey)) {
                      events[dateKey] = [];
                    }
                    events[dateKey]!.add(newEvent);
                  });

                  updateScheduleInFirestore();
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Color _getEventColor(String category, String priority) {
    // Example logic to determine the color dynamically
    if (category == "Work" && priority == "High") {
      return Colors.red;
    } else if (category == "Personal" && priority == "Low") {
      return Colors.blue;
    }
    return Colors.green; // Default color
  }
}
