// lib/services/promotions_service.dart
import 'package:grin_rea_app/core/supabase_config.dart';
import 'package:grin_rea_app/services/auth_service.dart';

class PromotionsService {
  static final _client = SupabaseConfig.client;

  // Promotion types
  static const String typeGear = 'gear';
  static const String typeService = 'service';
  static const String typeEvents = 'events';
  static const String typeParts = 'parts';
  static const String typeGeneral = 'general';

  // Get all active promotions
  static Future<List<Map<String, dynamic>>> getActivePromotions({
    String? category,
    int limit = 20,
  }) async {
    try {
      // Build the query step by step
      final baseQuery = _client
          .from('promotions')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);

      // Execute the base query
      final response = await baseQuery;
      
      // Filter the results in Dart
      var filteredPromotions = List<Map<String, dynamic>>.from(response);
      
      // Filter by category if specified
      if (category != null && category != 'all') {
        filteredPromotions = filteredPromotions.where((promo) {
          return promo['promotion_type'] == category;
        }).toList();
      }
      
      // Filter by date (only show current and future promotions)
      final now = DateTime.now();
      filteredPromotions = filteredPromotions.where((promo) {
        final endDate = promo['end_date'] as String?;
        if (endDate == null) return true; // No end date means always active
        try {
          final endDateTime = DateTime.parse(endDate);
          return endDateTime.isAfter(now) || endDateTime.isAtSameMomentAs(now);
        } catch (e) {
          return true; // If date parsing fails, include the promotion
        }
      }).toList();

      return filteredPromotions;
    } catch (e) {
      print('Error getting promotions: $e');
      // Return mock data for demo
      return _getMockPromotions(category);
    }
  }

  // Track promotion interaction
  static Future<void> trackInteraction({
    required String promotionId,
    required String interactionType, // 'view', 'click', 'save'
  }) async {
    if (AuthService.currentUser == null) return;

    try {
      await _client.from('promotion_interactions').insert({
        'user_id': AuthService.currentUser!.id,
        'promotion_id': promotionId,
        'interaction_type': interactionType,
      });
    } catch (e) {
      print('Error tracking interaction: $e');
    }
  }

  // Get promotion categories
  static Map<String, Map<String, String>> get promotionCategories => {
    'all': {
      'name': 'All',
      'icon': '🏷️',
      'color': 'orange',
    },
    typeGear: {
      'name': 'Gear & Equipment',
      'icon': '🧥',
      'color': 'blue',
    },
    typeParts: {
      'name': 'Parts & Accessories',
      'icon': '🔧',
      'color': 'green',
    },
    typeService: {
      'name': 'Services',
      'icon': '⚙️',
      'color': 'purple',
    },
    typeEvents: {
      'name': 'Events & Rallies',
      'icon': '🏁',
      'color': 'red',
    },
    typeGeneral: {
      'name': 'General Offers',
      'icon': '💫',
      'color': 'teal',
    },
  };

  // Mock promotions data for demo
  static List<Map<String, dynamic>> _getMockPromotions(String? category) {
    final allPromotions = [
      // Gear promotions
      {
        'id': 'promo_1',
        'title': '30% Off Premium Helmets',
        'description': 'Get 30% discount on all DOT certified helmets. Safety first!',
        'business_name': 'SafeRide Gear',
        'business_contact': 'contact@saferidegear.com',
        'promotion_type': typeGear,
        'image_url': null,
        'link_url': 'https://saferidegear.com/helmets',
        'location_city': 'Lille',
        'location_country': 'France',
        'start_date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String().split('T')[0],
        'end_date': DateTime.now().add(const Duration(days: 25)).toIso8601String().split('T')[0],
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': 'promo_2',
        'title': 'Free Jacket with Boot Purchase',
        'description': 'Buy any pair of motorcycle boots and get a free riding jacket!',
        'business_name': 'BikerStyle',
        'business_contact': 'info@bikerstyle.fr',
        'promotion_type': typeGear,
        'image_url': null,
        'link_url': 'https://bikerstyle.fr/promo',
        'location_city': 'Paris',
        'location_country': 'France',
        'start_date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String().split('T')[0],
        'end_date': DateTime.now().add(const Duration(days: 18)).toIso8601String().split('T')[0],
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      
      // Parts promotions
      {
        'id': 'promo_3',
        'title': 'Engine Oil Change Special',
        'description': 'Complete oil change service for only €49. Includes premium oil and filter.',
        'business_name': 'MotoService Pro',
        'business_contact': '03 20 XX XX XX',
        'promotion_type': typeParts,
        'image_url': null,
        'link_url': null,
        'location_city': 'Lille',
        'location_country': 'France',
        'start_date': DateTime.now().toIso8601String().split('T')[0],
        'end_date': DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0],
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'promo_4',
        'title': 'Tire Installation Discount',
        'description': '20% off tire installation. Professional mounting and balancing included.',
        'business_name': 'TireExperts',
        'business_contact': 'service@tireexperts.com',
        'promotion_type': typeParts,
        'image_url': null,
        'link_url': 'https://tireexperts.com/booking',
        'location_city': 'Lyon',
        'location_country': 'France',
        'start_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0],
        'end_date': DateTime.now().add(const Duration(days: 14)).toIso8601String().split('T')[0],
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      
      // Service promotions
      {
        'id': 'promo_5',
        'title': 'Free Motorcycle Inspection',
        'description': 'Comprehensive 50-point inspection absolutely free. Book your appointment today!',
        'business_name': 'Garage Central',
        'business_contact': '03 20 YY YY YY',
        'promotion_type': typeService,
        'image_url': null,
        'link_url': null,
        'location_city': 'Lille',
        'location_country': 'France',
        'start_date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String().split('T')[0],
        'end_date': DateTime.now().add(const Duration(days: 21)).toIso8601String().split('T')[0],
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
      
      // Events promotions
      {
        'id': 'promo_6',
        'title': 'Northern France Bike Rally',
        'description': 'Join us for the biggest motorcycle rally in Northern France! Live music, contests, and great food.',
        'business_name': 'Rally Organizers',
        'business_contact': 'info@northernrally.fr',
        'promotion_type': typeEvents,
        'image_url': null,
        'link_url': 'https://northernrally.fr/tickets',
        'location_city': 'Arras',
        'location_country': 'France',
        'start_date': DateTime.now().add(const Duration(days: 5)).toIso8601String().split('T')[0],
        'end_date': DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0],
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      },
      {
        'id': 'promo_7',
        'title': 'Weekend Group Ride',
        'description': 'Scenic route through Belgian countryside. All skill levels welcome!',
        'business_name': 'Lille Riders Club',
        'business_contact': 'contact@lilleriders.com',
        'promotion_type': typeEvents,
        'image_url': null,
        'link_url': null,
        'location_city': 'Lille',
        'location_country': 'France',
        'start_date': DateTime.now().add(const Duration(days: 12)).toIso8601String().split('T')[0],
        'end_date': DateTime.now().add(const Duration(days: 14)).toIso8601String().split('T')[0],
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
      },
      
      // General promotions
      {
        'id': 'promo_8',
        'title': 'Student Discount Program',
        'description': '15% discount on all services and parts for students with valid ID.',
        'business_name': 'Multiple Partners',
        'business_contact': 'student@discounts.fr',
        'promotion_type': typeGeneral,
        'image_url': null,
        'link_url': 'https://studentdiscounts.fr/motorcycle',
        'location_city': 'France',
        'location_country': 'France',
        'start_date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T')[0],
        'end_date': DateTime.now().add(const Duration(days: 335)).toIso8601String().split('T')[0],
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      },
    ];

    if (category == null || category == 'all') {
      return allPromotions;
    }

    return allPromotions.where((promo) => promo['promotion_type'] == category).toList();
  }

  // Check if promotion is ending soon (within 7 days)
  static bool isEndingSoon(Map<String, dynamic> promotion) {
    if (promotion['end_date'] == null) return false;
    
    try {
      final endDate = DateTime.parse(promotion['end_date']);
      final now = DateTime.now();
      final difference = endDate.difference(now).inDays;
      return difference <= 7 && difference >= 0;
    } catch (e) {
      return false;
    }
  }

  // Check if promotion is new (created within 7 days)
  static bool isNew(Map<String, dynamic> promotion) {
    try {
      final createdAt = DateTime.parse(promotion['created_at']);
      final now = DateTime.now();
      final difference = now.difference(createdAt).inDays;
      return difference <= 7;
    } catch (e) {
      return false;
    }
  }

  // Format date for display
  static String formatDate(String? dateString) {
    if (dateString == null) return 'No expiry';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = date.difference(now).inDays;
      
      if (difference < 0) return 'Expired';
      if (difference == 0) return 'Expires today';
      if (difference == 1) return 'Expires tomorrow';
      if (difference <= 7) return 'Expires in $difference days';
      
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return 'Until ${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}