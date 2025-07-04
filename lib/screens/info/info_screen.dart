// lib/screens/info/info_screen.dart - Enhanced Version
import 'package:flutter/material.dart';
import 'package:grin_rea_app/core/app_theme.dart';
import 'package:grin_rea_app/services/weather_service.dart';
import 'package:intl/intl.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _weatherData;
  List<Map<String, dynamic>>? _forecastData;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWeatherData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherData() async {
    try {
      print('Loading weather data...');
      final weather = await WeatherService.getCurrentWeather(defaultCity: 'lille');
      final forecast = await WeatherService.getWeatherForecast(defaultCity: 'lille');
      
      setState(() {
        _weatherData = weather;
        _forecastData = forecast;
        _isLoadingWeather = false;
      });
      print('Weather data loaded successfully');
    } catch (e) {
      setState(() {
        _isLoadingWeather = false;
      });
      print('Error loading weather data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Info Hub'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Weather', icon: Icon(Icons.wb_sunny, size: 18)),
            Tab(text: 'Safety', icon: Icon(Icons.security, size: 18)),
            Tab(text: 'Tips', icon: Icon(Icons.lightbulb, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWeatherTab(),
          _buildSafetyTab(),
          _buildTipsTab(),
        ],
      ),
    );
  }

  Widget _buildWeatherTab() {
    if (_isLoadingWeather) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryOrange),
      );
    }

    if (_weatherData == null) {
      return _buildErrorState('Unable to load weather data');
    }

    final bikingConditions = WeatherService.getBikingConditions(_weatherData!);

    return RefreshIndicator(
      onRefresh: _loadWeatherData,
      color: AppTheme.primaryOrange,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current Weather Card
          _buildWeatherCard(),
          const SizedBox(height: 16),
          
          // Biking Conditions Card
          _buildBikingConditionsCard(bikingConditions),
          const SizedBox(height: 16),
          
          // Forecast Card
          _buildForecastCard(),
          const SizedBox(height: 16),
          
          // Weather Details Card
          _buildWeatherDetailsCard(),
          
          // Extra padding to ensure content is not cut off
          SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryOrange.withOpacity(0.1),
            AppTheme.secondaryOrange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _weatherData!['location'],
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _weatherData!['weather_description'].toString().toUpperCase(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (WeatherService.isConfigured && _weatherData!['weather_icon'] != null)
                Image.network(
                  WeatherService.getWeatherIconUrl(_weatherData!['weather_icon']),
                  width: 64,
                  height: 64,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.wb_sunny,
                    size: 64,
                    color: AppTheme.primaryOrange,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_weatherData!['temperature'].toStringAsFixed(1)}°C',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feels like ${_weatherData!['feels_like'].toStringAsFixed(1)}°C',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Humidity: ${_weatherData!['humidity']}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBikingConditionsCard(Map<String, dynamic> conditions) {
    Color conditionColor;
    IconData conditionIcon;
    
    switch (conditions['color']) {
      case 'green':
        conditionColor = AppTheme.success;
        conditionIcon = Icons.check_circle;
        break;
      case 'yellow':
        conditionColor = AppTheme.warning;
        conditionIcon = Icons.warning;
        break;
      case 'orange':
        conditionColor = AppTheme.warning;
        conditionIcon = Icons.warning;
        break;
      case 'red':
        conditionColor = AppTheme.error;
        conditionIcon = Icons.dangerous;
        break;
      default:
        conditionColor = AppTheme.info;
        conditionIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: conditionColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: conditionColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(conditionIcon, color: conditionColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Biking Conditions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Condition: ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                conditions['condition'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: conditionColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            conditions['advice'],
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildConditionItem(
                  'Temperature',
                  conditions['temperature_rating'],
                  Icons.thermostat,
                ),
              ),
              Expanded(
                child: _buildConditionItem(
                  'Wind',
                  conditions['wind_rating'],
                  Icons.air,
                ),
              ),
              Expanded(
                child: _buildConditionItem(
                  'Visibility',
                  conditions['visibility_rating'],
                  Icons.visibility,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryOrange, size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastCard() {
    if (_forecastData == null || _forecastData!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.primaryOrange, size: 24),
              const SizedBox(width: 8),
              Text(
                '24-Hour Forecast',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _forecastData!.take(8).length,
              itemBuilder: (context, index) {
                final forecast = _forecastData![index];
                return _buildForecastItem(forecast);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastItem(Map<String, dynamic> forecast) {
    final time = DateFormat('HH:mm').format(forecast['datetime']);
    final temp = forecast['temperature'].toStringAsFixed(0);
    
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (WeatherService.isConfigured && forecast['weather_icon'] != null)
            Image.network(
              WeatherService.getWeatherIconUrl(forecast['weather_icon']),
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.wb_sunny,
                size: 24,
                color: AppTheme.primaryOrange,
              ),
            )
          else
            Icon(Icons.wb_sunny, size: 24, color: AppTheme.primaryOrange),
          const SizedBox(height: 8),
          Text(
            '${temp}°',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryOrange, size: 24),
              const SizedBox(width: 8),
              Text(
                'Weather Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Wind Speed',
                  '${_weatherData!['wind_speed'].toStringAsFixed(1)} m/s',
                  Icons.air,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Pressure',
                  '${_weatherData!['pressure']} hPa',
                  Icons.speed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Visibility',
                  '${_weatherData!['visibility'].toStringAsFixed(1)} km',
                  Icons.visibility,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Humidity',
                  '${_weatherData!['humidity']}%',
                  Icons.opacity,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Sunrise',
                  DateFormat('HH:mm').format(_weatherData!['sunrise']),
                  Icons.wb_sunny,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Sunset',
                  DateFormat('HH:mm').format(_weatherData!['sunset']),
                  Icons.brightness_3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primaryOrange, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSafetyTipCard(
          'Pre-Ride Safety Check',
          'Always perform these checks before riding',
          Icons.checklist,
          [
            'Check tire pressure and tread',
            'Test brakes and brake fluid',
            'Inspect lights and signals',
            'Check chain and sprockets',
            'Verify fuel and oil levels',
            'Adjust mirrors and seat',
          ],
        ),
        const SizedBox(height: 16),
        _buildSafetyTipCard(
          'Protective Gear',
          'Essential equipment for every ride',
          Icons.security,
          [
            'DOT/ECE approved helmet',
            'Protective jacket and pants',
            'Gloves with good grip',
            'Over-the-ankle boots',
            'Eye protection',
            'Reflective vest (night riding)',
          ],
        ),
        const SizedBox(height: 16),
        _buildSafetyTipCard(
          'Road Safety Tips',
          'Stay safe on the road',
          Icons.traffic,
          [
            'Maintain safe following distance',
            'Use your signals early',
            'Stay visible to other drivers',
            'Check blind spots regularly',
            'Avoid riding in bad weather',
            'Never ride under influence',
          ],
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
      ],
    );
  }

  Widget _buildTipsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTipCard(
          'Maintenance Tips',
          'Keep your bike in top condition',
          Icons.build,
          [
            'Regular oil changes every 3,000-5,000 miles',
            'Clean and lubricate chain every 500 miles',
            'Check tire pressure weekly',
            'Replace air filter annually',
            'Inspect brake pads regularly',
            'Keep battery terminals clean',
          ],
        ),
        const SizedBox(height: 16),
        _buildTipCard(
          'Riding Techniques',
          'Improve your riding skills',
          Icons.psychology,
          [
            'Look through turns, not at them',
            'Use both brakes smoothly',
            'Keep your body relaxed',
            'Practice emergency braking',
            'Learn to counter-steer',
            'Maintain steady throttle in turns',
          ],
        ),
        const SizedBox(height: 16),
        _buildTipCard(
          'Group Riding',
          'Tips for riding with others',
          Icons.group,
          [
            'Ride in staggered formation',
            'Maintain your lane position',
            'Use hand signals',
            'Keep group size manageable',
            'Plan stops and routes ahead',
            'Stay with your riding level',
          ],
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
      ],
    );
  }

  Widget _buildSafetyTipCard(String title, String subtitle, IconData icon, List<String> tips) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.error, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    tip,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildTipCard(String title, String subtitle, IconData icon, List<String> tips) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.info, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.info,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.info,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    tip,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWeatherData,
              style: AppTheme.primaryButtonStyle,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}