// lib/services/map_service.dart
import 'dart:convert';
import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class MapService {
  // Google Places API key (you'll need to get this from Google Cloud Console)
  static const String _placesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
  static const String _placesBaseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Location types for bikers
  static const Map<String, Map<String, String>> locationTypes = {
    'gas_station': {
      'name': 'Gas Stations',
      'icon': '⛽',
      'type': 'gas_station',
    },
    'motorcycle_dealer': {
      'name': 'Motorcycle Dealers',
      'icon': '🏍️',
      'type': 'car_dealer',
    },
    'car_repair': {
      'name': 'Repair Shops',
      'icon': '🔧',
      'type': 'car_repair',
    },
    'restaurant': {
      'name': 'Restaurants',
      'icon': '🍽️',
      'type': 'restaurant',
    },
    'cafe': {
      'name': 'Cafes',
      'icon': '☕',
      'type': 'cafe',
    },
    'lodging': {
      'name': 'Hotels',
      'icon': '🏨',
      'type': 'lodging',
    },
  };

  // Get current location safely
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Get nearby places using Google Places API
  static Future<List<Map<String, dynamic>>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    required String placeType,
    int radius = 5000, // 5km radius
  }) async {
    try {
      if (!isConfigured) {
        print('Google Places API not configured, using mock data');
        return _getMockPlaces(placeType, latitude, longitude);
      }

      final url = '$_placesBaseUrl/nearbysearch/json'
          '?location=$latitude,$longitude'
          '&radius=$radius'
          '&type=$placeType'
          '&key=$_placesApiKey';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final places = data['results'] as List;
          return places.map((place) => _formatPlaceData(place, latitude, longitude)).toList();
        } else {
          print('Places API error: ${data['status']}');
          return _getMockPlaces(placeType, latitude, longitude);
        }
      } else {
        print('Places API HTTP error: ${response.statusCode}');
        return _getMockPlaces(placeType, latitude, longitude);
      }
    } catch (e) {
      print('Error getting nearby places: $e');
      return _getMockPlaces(placeType, latitude, longitude);
    }
  }

  // Format place data from Google Places API
  static Map<String, dynamic> _formatPlaceData(
    Map<String, dynamic> place,
    double userLat,
    double userLng,
  ) {
    final location = place['geometry']['location'];
    final placeLat = location['lat'].toDouble();
    final placeLng = location['lng'].toDouble();
    final distance = _calculateDistance(userLat, userLng, placeLat, placeLng);

    return {
      'id': place['place_id'],
      'name': place['name'],
      'address': place['vicinity'] ?? place['formatted_address'] ?? 'Address not available',
      'latitude': placeLat,
      'longitude': placeLng,
      'distance_km': distance,
      'rating': place['rating']?.toDouble() ?? 0.0,
      'rating_count': place['user_ratings_total'] ?? 0,
      'price_level': place['price_level'] ?? 0,
      'is_open': place['opening_hours']?['open_now'] ?? true,
      'types': place['types'] ?? [],
      'photo_reference': place['photos']?.isNotEmpty == true 
          ? place['photos'][0]['photo_reference'] 
          : null,
    };
  }

  // Get place photo URL
  static String? getPlacePhotoUrl(String? photoReference, {int maxWidth = 400}) {
    if (photoReference == null || !isConfigured) return null;
    return '$_placesBaseUrl/photo?maxwidth=$maxWidth&photoreference=$photoReference&key=$_placesApiKey';
  }

  // Calculate distance between two points
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * (sin(dLon / 2) * sin(dLon / 2));
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  // Mock places data for demo/testing
  static List<Map<String, dynamic>> _getMockPlaces(String placeType, double lat, double lng) {
    final mockData = {
      'gas_station': [
        {
          'name': 'Shell Station',
          'address': 'Rue de la Paix, Lille',
          'distance_offset': [0.005, 0.003],
          'rating': 4.2,
          'is_open': true,
        },
        {
          'name': 'Total Access',
          'address': 'Avenue du Peuple Belge, Lille',
          'distance_offset': [0.008, -0.004],
          'rating': 4.0,
          'is_open': true,
        },
        {
          'name': 'BP Station',
          'address': 'Boulevard Louis XIV, Lille',
          'distance_offset': [-0.006, 0.007],
          'rating': 3.8,
          'is_open': false,
        },
      ],
      'restaurant': [
        {
          'name': 'Café Biker',
          'address': 'Place du Général de Gaulle, Lille',
          'distance_offset': [0.003, 0.002],
          'rating': 4.5,
          'is_open': true,
        },
        {
          'name': 'Route 66 Diner',
          'address': 'Rue Faidherbe, Lille',
          'distance_offset': [0.007, -0.003],
          'rating': 4.3,
          'is_open': true,
        },
      ],
      'car_repair': [
        {
          'name': 'Moto Expert',
          'address': 'Rue de Tournai, Lille',
          'distance_offset': [0.009, 0.005],
          'rating': 4.7,
          'is_open': true,
        },
        {
          'name': 'Garage Ducati',
          'address': 'Avenue de la République, Lille',
          'distance_offset': [-0.004, 0.008],
          'rating': 4.4,
          'is_open': false,
        },
      ],
    };

    final places = mockData[placeType] ?? mockData['gas_station']!;
    
    return places.map((place) {
      final distanceOffset = place['distance_offset'] as List;
      final placeLat = lat + (distanceOffset[0] as double);
      final placeLng = lng + (distanceOffset[1] as double);
      final distance = _calculateDistance(lat, lng, placeLat, placeLng);
      
      return {
        'id': 'mock_${(place['name'] as String).toLowerCase().replaceAll(' ', '_')}',
        'name': place['name'],
        'address': place['address'],
        'latitude': placeLat,
        'longitude': placeLng,
        'distance_km': distance,
        'rating': place['rating'],
        'rating_count': 50 + ((place['rating'] as double) * 20).round(),
        'price_level': 2,
        'is_open': place['is_open'],
        'types': [placeType],
        'photo_reference': null,
      };
    }).toList();
  }

  // Check if Google Places API is configured
  static bool get isConfigured => 
      _placesApiKey != 'YOUR_GOOGLE_PLACES_API_KEY' && 
      _placesApiKey.isNotEmpty;

  // Get directions URL (opens in external maps app)
  static String getDirectionsUrl({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    String mode = 'driving',
  }) {
    return 'https://www.google.com/maps/dir/$fromLat,$fromLng/$toLat,$toLng';
  }
}