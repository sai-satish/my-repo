import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:trip_swift/secrets.dart';
import 'chat_screen.dart';
import 'package:trip_swift/home_page.dart';
import 'package:trip_swift/suggest_trips.dart';
import 'package:trip_swift/testing_features/maps_osm.dart';
import 'package:trip_swift/upcoming_schedule.dart';
import 'package:trip_swift/previoustrips_screens.dart';
import 'package:trip_swift/profile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _selectedStatus = "Free";
  String _location = "New York, USA";
  String _temperature = "22°C";

  // Function to fetch the current location
  Future<Position> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      // Show Snackbar if permission is denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied. Please enable it in settings.")),
      );
      throw Exception("Location permission denied");
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    return position;
  }

  // Function to get the place name based on coordinates
  Future<String> getPlaceName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        return '${placemark.locality}';
      } else {
        return '?'; // Return a default value if no placemark is found
      }
    } catch (e) {
      print('Error getting place name: $e');
      return 'Error'; // Return an error message
    }
  }

  // Function to fetch weather data based on coordinates
  Future<Map<String, dynamic>> getWeather(double latitude, double longitude) async {
    String apiKey = OPENWEATHERMAP_API_KEY;  // Replace with your OpenWeatherMap API key
    String url = 'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body); // Return weather data in JSON format
    } else {
      throw Exception('Failed to load weather');
    }
  }

  // Function to update the location and weather data in the app
  Future<void> updateLocationAndWeather() async {
    try {
      Position position = await getCurrentLocation();
      print("Current Location fetched properly lat:${position.latitude} long:${position.longitude}");
      // String placeName = await getPlaceName(position.latitude, position.longitude);
      // var placeName = await http.get(Uri.parse(
      //     'https://photon.komoot.io/reverse?lat=${position.latitude}&lon=${position.longitude}'));

      // Handle potential errors from getPlaceName
      // if (placeName == 'Error') {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text("Error fetching place name. Please try again.")),
      //   );
      //   // return;
      // }


      Map<String, dynamic> weather = await getWeather(position.latitude, position.longitude);
      print("Weather fetched: $weather");

      // var jsonResponse = json.decode(weather);
      // print("PlaceName json: $jsonResponse");


      setState(() async {
        _location = weather["name"];
        _temperature = weather["temp"];

      });
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch location or weather. Please try again.")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    updateLocationAndWeather();  // Fetch location and weather when the app starts
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateStatus(String? value) {
    setState(() {
      _selectedStatus = value ?? "Free";
    });
  }

  @override
  Widget build(BuildContext context) {
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF131617),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Trip Swift',
          style: TextStyle(color: Color(0xFF22DD85)),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "John Doe",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFF22DD85)),
                    SizedBox(width: 5),
                    Text(_location, style: const TextStyle(fontSize: 14)),
                    SizedBox(width: 10),
                    Text(_temperature, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(),
          SuggestTripScreen(),
          ChatScreen(),
          MapPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF131617),
        selectedItemColor: const Color(0xFF22DD85),
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: "Plan Trip",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Maps",
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF131617),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              child: UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF131617)),
                accountName: const Text(
                  "John Doe",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                accountEmail: null,
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Color(0xFF22DD85),
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle, color: Color(0xFF22DD85)),
              title: DropdownButton<String>(
                isExpanded: true,
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(
                    child: Text("Free", style: TextStyle(color: Colors.white)),
                    value: "Free",
                  ),
                  DropdownMenuItem(
                    child: Text("Busy", style: TextStyle(color: Colors.white)),
                    value: "Busy",
                  ),
                  DropdownMenuItem(
                    child: Text("At Work", style: TextStyle(color: Colors.white)),
                    value: "At Work",
                  ),
                ],
                onChanged: _updateStatus,
                dropdownColor: const Color(0xFF131617),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const Divider(color: Colors.white),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Color(0xFF22DD85)),
              title: const Text(
                "Upcoming Schedule",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UpcomingScheduleScreen()),
                );
              },
            ),
            const Divider(color: Colors.white),
            ListTile(
              leading: const Icon(Icons.trip_origin, color: Color(0xFF22DD85)),
              title: const Text(
                "Previous Trips",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PreviousTripsScreen()),
                );
              },
            ),
            const Divider(color: Colors.white),
            ListTile(
              leading: const Icon(Icons.refresh, color: Color(0xFF22DD85)),
              title: const Text(
                "Refresh Location & Weather",
                style: TextStyle(color: Colors.white),
              ),
              onTap: updateLocationAndWeather,  // Refresh on tap
            ),
          ],
        ),
      ),
    );
  }
}
