import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlaceFinder {
  Future<List<Place>> findNearbyPlaces(
      double latitude, double longitude, String type) async {
    List<Place> places = [];

    // Replace with your Google Maps API key
    String apiKey = "YOUR_GOOGLE_MAPS_API_KEY";

    String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
        "location=${latitude},${longitude}&radius=5000&type=$type&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'OK') {
          for (var result in jsonResponse['results']) {
            places.add(Place(
              name: result['name'],
              vicinity: result['vicinity'],
              latitude: result['geometry']['location']['lat'],
              longitude: result['geometry']['location']['lng'],
              placeId: result['place_id'],
              rating: result['rating'],
            ));
          }
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching places: $e');
    }

    return places;
  }
}

class Place {
  final String name;
  final String vicinity;
  final double latitude;
  final double longitude;
  final String placeId;
  final double? rating;

  Place({
    required this.name,
    required this.vicinity,
    required this.latitude,
    required this.longitude,
    required this.placeId,
    this.rating,
  });
}