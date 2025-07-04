// lib/services/emergency_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:grin_rea_app/core/supabase_config.dart';
import 'package:grin_rea_app/services/auth_service.dart';
import 'dart:math' show sin, cos, sqrt, atan2, pi;
class EmergencyService {
  static final _client = SupabaseConfig.client;

  // Emergency alert types
  static const String alertTypeAccident = 'accident';
  static const String alertTypeBreakdown = 'breakdown';
  static const String alertTypeMedical = 'medical';
  static const String alertTypeGeneral = 'general';

  // Response types
  static const String responseOnWay = 'on_way';
  static const String responseArrived = 'arrived';
  static const String responseContactedAuthorities = 'contacted_authorities';

  // Send emergency alert
  static Future<Map<String, dynamic>> sendEmergencyAlert({
    required String alertType,
    String? message,
    double? latitude,
    double? longitude,
  }) async {
    if (AuthService.currentUser == null) {
      throw Exception('User not authenticated');
    }

    Position? currentPosition;
    String? locationAddress;

    try {
      // Get current location if not provided
      if (latitude == null || longitude == null) {
        currentPosition = await _getCurrentLocation();
        latitude = currentPosition.latitude;
        longitude = currentPosition.longitude;
      }

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          locationAddress = _formatAddress(place);
        }
      } catch (e) {
        print('Error getting address: $e');
      }

      // Insert emergency alert
      final response = await _client.from('emergency_alerts').insert({
        'user_id': AuthService.currentUser!.id,
        'location_lat': latitude,
        'location_lng': longitude,
        'location_address': locationAddress,
        'message': message ?? _getDefaultMessage(alertType),
        'alert_type': alertType,
      }).select('''
        *,
        profiles:user_id (
          id,
          username,
          full_name,
          avatar_url,
          emergency_contact_name,
          emergency_contact_phone
        )
      ''').single();

      // TODO: Send push notifications to nearby users
      await _notifyNearbyUsers(latitude, longitude, response);

      return response;
    } catch (e) {
      print('Error sending emergency alert: $e');
      rethrow;
    }
  }

  // Get current location
  static Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Format address from placemark
  static String _formatAddress(Placemark place) {
    List<String> addressParts = [];
    
    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }

    return addressParts.join(', ');
  }

  // Get default message for alert type
  static String _getDefaultMessage(String alertType) {
    switch (alertType) {
      case alertTypeAccident:
        return 'I\'ve been in an accident and need help!';
      case alertTypeBreakdown:
        return 'My bike has broken down and I need assistance!';
      case alertTypeMedical:
        return 'I have a medical emergency and need immediate help!';
      case alertTypeGeneral:
      default:
        return 'I need help from nearby bikers!';
    }
  }

  // Notify nearby users (placeholder for push notifications)
  static Future<void> _notifyNearbyUsers(double latitude, double longitude, Map<String, dynamic> alert) async {
    // TODO: Implement push notification logic
    // This would typically involve:
    // 1. Finding users within a certain radius
    // 2. Getting their device tokens
    // 3. Sending push notifications via Firebase Cloud Messaging or similar
    print('Notifying nearby users about emergency alert: ${alert['id']}');
  }

  // Get nearby emergency alerts
  static Future<List<Map<String, dynamic>>> getNearbyEmergencyAlerts({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0, // 50km radius
  }) async {
    try {
      // Get all active emergency alerts
      final response = await _client
          .from('emergency_alerts')
          .select('''
            *,
            profiles:user_id (
              id,
              username,
              full_name,
              avatar_url,
              emergency_contact_name,
              emergency_contact_phone
            )
          ''')
          .eq('is_active', true)
          .eq('is_resolved', false)
          .order('created_at', ascending: false);

      // Filter by distance
      List<Map<String, dynamic>> nearbyAlerts = [];
      for (var alert in response) {
        if (alert['location_lat'] != null && alert['location_lng'] != null) {
          double distance = _calculateDistance(
            latitude,
            longitude,
            alert['location_lat'].toDouble(),
            alert['location_lng'].toDouble(),
          );
          
          if (distance <= radiusKm) {
            final alertData = Map<String, dynamic>.from(alert);
            alertData['distance_km'] = distance;
            nearbyAlerts.add(alertData);
          }
        }
      }

      // Sort by distance (closest first)
      nearbyAlerts.sort((a, b) => a['distance_km'].compareTo(b['distance_km']));
      return nearbyAlerts;
    } catch (e) {
      print('Error getting nearby emergency alerts: $e');
      return [];
    }
  }

  // Calculate distance between two points (Haversine formula)
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

  // Respond to emergency alert
  static Future<Map<String, dynamic>> respondToEmergencyAlert({
    required String alertId,
    required String responseType,
    String? message,
  }) async {
    if (AuthService.currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _client.from('emergency_responses').insert({
        'alert_id': alertId,
        'responder_id': AuthService.currentUser!.id,
        'response_type': responseType,
        'message': message ?? _getDefaultResponseMessage(responseType),
      }).select('''
        *,
        profiles:responder_id (
          id,
          username,
          full_name,
          avatar_url
        )
      ''').single();

      return response;
    } catch (e) {
      print('Error responding to emergency alert: $e');
      rethrow;
    }
  }

  // Get default response message
  static String _getDefaultResponseMessage(String responseType) {
    switch (responseType) {
      case responseOnWay:
        return 'I\'m on my way to help!';
      case responseArrived:
        return 'I\'ve arrived at your location.';
      case responseContactedAuthorities:
        return 'I\'ve contacted the authorities for you.';
      default:
        return 'I\'m here to help!';
    }
  }

  // Get responses for an emergency alert
  static Future<List<Map<String, dynamic>>> getEmergencyResponses(String alertId) async {
    try {
      final response = await _client
          .from('emergency_responses')
          .select('''
            *,
            profiles:responder_id (
              id,
              username,
              full_name,
              avatar_url
            )
          ''')
          .eq('alert_id', alertId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting emergency responses: $e');
      return [];
    }
  }

  // Mark emergency alert as resolved
  static Future<void> resolveEmergencyAlert(String alertId) async {
    if (AuthService.currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _client
          .from('emergency_alerts')
          .update({
            'is_resolved': true,
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId)
          .eq('user_id', AuthService.currentUser!.id);
    } catch (e) {
      print('Error resolving emergency alert: $e');
      rethrow;
    }
  }

  // Get user's emergency alerts
  static Future<List<Map<String, dynamic>>> getUserEmergencyAlerts() async {
    if (AuthService.currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _client
          .from('emergency_alerts')
          .select('*')
          .eq('user_id', AuthService.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user emergency alerts: $e');
      return [];
    }
  }
}

// Helper function imports
