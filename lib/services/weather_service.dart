// lib/services/weather_service.dart - Platform-Agnostic Version
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WeatherService {
  // OpenWeatherMap API key (replace with your actual key)
  static const String _apiKey = 'bbbf87cd86f4c8b25a640aee07e6f4dd';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Default locations for different scenarios
  static const Map<String, Map<String, double>> _defaultLocations = {
    'lille': {'lat': 50.6292, 'lon': 3.0573},
    'paris': {'lat': 48.8566, 'lon': 2.3522},
    'london': {'lat': 51.5074, 'lon': -0.1278},
    'berlin': {'lat': 52.5200, 'lon': 13.4050},
  };

  // Get current weather (using fixed location for now)
  static Future<Map<String, dynamic>> getCurrentWeather({
    double? latitude,
    double? longitude,
    String defaultCity = 'lille',
  }) async {
    try {
      // Use provided coordinates or default location
      latitude ??= _defaultLocations[defaultCity]!['lat']!;
      longitude ??= _defaultLocations[defaultCity]!['lon']!;

      print('Getting weather for coordinates: $latitude, $longitude');
      print('API Key configured: ${isConfigured}');
      print('API Key length: ${_apiKey.length}');
      print('API Key starts with: ${_apiKey.substring(0, 8)}...');

      // Bypass check and force API call (temporary fix)
      final shouldUseAPI = _apiKey.length == 32 && _apiKey.startsWith('bbbf87cd');
      print('Force API call: $shouldUseAPI');
      
      if (!shouldUseAPI) {
        print('Weather API not configured, using mock data');
        return _getMockWeatherData(defaultCity);
      }

      final url = '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric';
      print('Weather API URL: $url');
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      print('Weather API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Weather API response successful');
        print('Weather data: ${data['name']}, ${data['main']['temp']}°C');
        return _formatWeatherData(data);
      } else {
        print('Weather API error: ${response.statusCode} - ${response.body}');
        return _getMockWeatherData(defaultCity);
      }
    } catch (e) {
      print('Error getting current weather: $e');
      return _getMockWeatherData(defaultCity);
    }
  }

  // Get weather forecast
  static Future<List<Map<String, dynamic>>> getWeatherForecast({
    double? latitude,
    double? longitude,
    String defaultCity = 'lille',
  }) async {
    try {
      // Use provided coordinates or default location
      latitude ??= _defaultLocations[defaultCity]!['lat']!;
      longitude ??= _defaultLocations[defaultCity]!['lon']!;

      print('Getting forecast for coordinates: $latitude, $longitude');
      print('API Key configured for forecast: ${isConfigured}');

      // Bypass check and force API call (temporary fix)
      final shouldUseAPI = _apiKey.length == 32 && _apiKey.startsWith('bbbf87cd');
      print('Force forecast API call: $shouldUseAPI');
      
      if (!shouldUseAPI) {
        print('Weather API not configured, using mock forecast data');
        return _getMockForecastData();
      }

      final url = '$_baseUrl/forecast?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric';
      print('Forecast API URL: $url');
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      print('Forecast API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Forecast API response successful');
        print('Forecast data count: ${data['list']?.length ?? 0}');
        return _formatForecastData(data);
      } else {
        print('Forecast API error: ${response.statusCode} - ${response.body}');
        return _getMockForecastData();
      }
    } catch (e) {
      print('Error getting weather forecast: $e');
      return _getMockForecastData();
    }
  }

  // Get weather for specific city
  static Future<Map<String, dynamic>> getWeatherByCity(String cityName) async {
    try {
      if (!isConfigured) {
        return _getMockWeatherData(cityName.toLowerCase());
      }

      final url = '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _formatWeatherData(data);
      } else {
        return _getMockWeatherData(cityName.toLowerCase());
      }
    } catch (e) {
      print('Error getting weather by city: $e');
      return _getMockWeatherData(cityName.toLowerCase());
    }
  }

  // Format weather data
  static Map<String, dynamic> _formatWeatherData(Map<String, dynamic> data) {
    return {
      'location': data['name'] ?? 'Unknown Location',
      'country': data['sys']?['country'] ?? '',
      'temperature': (data['main']?['temp'] ?? 18.0).toDouble(),
      'feels_like': (data['main']?['feels_like'] ?? 19.0).toDouble(),
      'humidity': data['main']?['humidity'] ?? 65,
      'pressure': data['main']?['pressure'] ?? 1013,
      'visibility': data['visibility'] != null ? data['visibility'] / 1000 : 10.0,
      'wind_speed': (data['wind']?['speed'] ?? 5.0).toDouble(),
      'wind_direction': data['wind']?['deg'] ?? 0,
      'weather_main': data['weather']?[0]?['main'] ?? 'Clear',
      'weather_description': data['weather']?[0]?['description'] ?? 'clear sky',
      'weather_icon': data['weather']?[0]?['icon'] ?? '01d',
      'sunrise': data['sys']?['sunrise'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['sys']['sunrise'] * 1000)
          : DateTime.now().subtract(const Duration(hours: 6)),
      'sunset': data['sys']?['sunset'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['sys']['sunset'] * 1000)
          : DateTime.now().add(const Duration(hours: 6)),
      'timestamp': DateTime.now(),
    };
  }

  // Format forecast data
  static List<Map<String, dynamic>> _formatForecastData(Map<String, dynamic> data) {
    List<Map<String, dynamic>> forecast = [];
    
    final list = data['list'] as List? ?? [];
    
    for (var item in list.take(24)) { // Take only 24 items (3 days)
      forecast.add({
        'datetime': item['dt'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000)
            : DateTime.now(),
        'temperature': (item['main']?['temp'] ?? 18.0).toDouble(),
        'feels_like': (item['main']?['feels_like'] ?? 19.0).toDouble(),
        'humidity': item['main']?['humidity'] ?? 65,
        'wind_speed': (item['wind']?['speed'] ?? 5.0).toDouble(),
        'weather_main': item['weather']?[0]?['main'] ?? 'Clear',
        'weather_description': item['weather']?[0]?['description'] ?? 'clear sky',
        'weather_icon': item['weather']?[0]?['icon'] ?? '01d',
        'pop': ((item['pop'] ?? 0) * 100).toInt(),
      });
    }
    
    return forecast;
  }

  // Get weather icon URL
  static String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  // Get weather condition for biking
  static Map<String, dynamic> getBikingConditions(Map<String, dynamic> weatherData) {
    final temp = weatherData['temperature'] ?? 18.0;
    final windSpeed = weatherData['wind_speed'] ?? 5.0;
    final humidity = weatherData['humidity'] ?? 65;
    final weatherMain = (weatherData['weather_main'] ?? 'Clear').toString().toLowerCase();
    final visibility = weatherData['visibility'] ?? 10.0;

    String condition;
    String advice;
    String color;

    if (weatherMain.contains('rain') || weatherMain.contains('storm')) {
      condition = 'Poor';
      advice = 'Not recommended for biking. Roads may be slippery.';
      color = 'red';
    } else if (weatherMain.contains('snow') || weatherMain.contains('fog')) {
      condition = 'Poor';
      advice = 'Dangerous conditions. Consider postponing your ride.';
      color = 'red';
    } else if (temp < 5 || temp > 35 || windSpeed > 20 || visibility < 5) {
      condition = 'Fair';
      advice = 'Ride with caution. Extreme weather conditions.';
      color = 'orange';
    } else if (temp < 10 || temp > 30 || windSpeed > 15 || humidity > 85) {
      condition = 'Good';
      advice = 'Good conditions but take precautions.';
      color = 'yellow';
    } else {
      condition = 'Excellent';
      advice = 'Perfect weather for biking!';
      color = 'green';
    }

    return {
      'condition': condition,
      'advice': advice,
      'color': color,
      'temperature_rating': _getTemperatureRating(temp),
      'wind_rating': _getWindRating(windSpeed),
      'visibility_rating': _getVisibilityRating(visibility),
    };
  }

  static String _getTemperatureRating(double temp) {
    if (temp < 0) return 'Freezing';
    if (temp < 10) return 'Cold';
    if (temp < 20) return 'Cool';
    if (temp < 30) return 'Warm';
    if (temp < 35) return 'Hot';
    return 'Very Hot';
  }

  static String _getWindRating(double windSpeed) {
    if (windSpeed < 5) return 'Calm';
    if (windSpeed < 10) return 'Light';
    if (windSpeed < 15) return 'Moderate';
    if (windSpeed < 20) return 'Strong';
    return 'Very Strong';
  }

  static String _getVisibilityRating(double visibility) {
    if (visibility < 1) return 'Very Poor';
    if (visibility < 5) return 'Poor';
    if (visibility < 10) return 'Moderate';
    return 'Good';
  }

  // Mock weather data for demo purposes
  static Map<String, dynamic> _getMockWeatherData(String city) {
    final cityData = {
      'lille': {'temp': 18.5, 'name': 'Lille'},
      'paris': {'temp': 20.2, 'name': 'Paris'},
      'london': {'temp': 15.8, 'name': 'London'},
      'berlin': {'temp': 16.3, 'name': 'Berlin'},
    };

    final data = cityData[city] ?? cityData['lille']!;
    
    return {
      'location': data['name'],
      'country': 'FR',
      'temperature': data['temp'],
      'feels_like': (data['temp']! as double) + 0.7,
      'humidity': 65,
      'pressure': 1013,
      'visibility': 10.0,
      'wind_speed': 5.2,
      'wind_direction': 230,
      'weather_main': 'Clear',
      'weather_description': 'clear sky',
      'weather_icon': '01d',
      'sunrise': DateTime.now().subtract(const Duration(hours: 6)),
      'sunset': DateTime.now().add(const Duration(hours: 6)),
      'timestamp': DateTime.now(),
    };
  }

  // Mock forecast data for demo purposes
  static List<Map<String, dynamic>> _getMockForecastData() {
    return List.generate(24, (index) {
      final baseTime = DateTime.now();
      final temp = 18.0 + (index % 8) * 2.5;
      
      return {
        'datetime': baseTime.add(Duration(hours: index * 3)),
        'temperature': temp,
        'feels_like': temp + 0.5,
        'humidity': 60 + (index % 5) * 5,
        'wind_speed': 4.0 + (index % 3) * 2.0,
        'weather_main': index % 4 == 0 ? 'Clouds' : 'Clear',
        'weather_description': index % 4 == 0 ? 'few clouds' : 'clear sky',
        'weather_icon': index % 4 == 0 ? '02d' : '01d',
        'pop': index % 6 == 0 ? 20 : 0,
      };
    });
  }

  // Check if API key is configured
  static bool get isConfigured {
    // Direct check - if the API key starts with your key, it's configured
    final startsWithYourKey = _apiKey.startsWith('bbbf87cd');
    final notDefault = _apiKey != 'bbbf87cd86f4c8b25a640aee07e6f4dd';
    final hasCorrectLength = _apiKey.length >= 32;
    
    return startsWithYourKey && hasCorrectLength;
  }

  // Get available cities
  static List<String> get availableCities => _defaultLocations.keys.toList();
}