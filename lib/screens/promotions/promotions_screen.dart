// lib/screens/promotions/promotions_screen.dart - Fixed Version
import 'package:flutter/material.dart';
import 'package:grin_rea_app/services/promotions_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grin_rea_app/core/app_theme.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _promotions = [];
  String _selectedCategory = 'all';
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: PromotionsService.promotionCategories.length, vsync: this);
    _loadPromotions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    try {
      final promotions = await PromotionsService.getActivePromotions(
        category: _selectedCategory,
      );
      setState(() {
        _promotions = promotions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading promotions: $e', isError: true);
    }
  }

  Future<void> _refreshPromotions() async {
    setState(() => _isRefreshing = true);
    await _loadPromotions();
    setState(() => _isRefreshing = false);
  }

  void _onCategoryChanged(String category) {
    if (_selectedCategory != category) {
      setState(() {
        _selectedCategory = category;
        _isLoading = true;
      });
      _loadPromotions();
    }
  }

  Future<void> _openPromoLink(Map<String, dynamic> promotion) async {
    final url = promotion['link_url'] as String?;
    if (url == null || url.isEmpty) {
      _showSnackBar('No website available for this promotion');
      return;
    }

    try {
      // Track click interaction
      await PromotionsService.trackInteraction(
        promotionId: promotion['id'],
        interactionType: 'click',
      );

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open link', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error opening link: $e', isError: true);
    }
  }

  void _showPromotionDetails(Map<String, dynamic> promotion) {
    // Track view interaction
    PromotionsService.trackInteraction(
      promotionId: promotion['id'],
      interactionType: 'view',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildPromotionDetailsSheet(promotion),
    );
  }

  Widget _buildPromotionDetailsSheet(Map<String, dynamic> promotion) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          Text(
            promotion['title'],
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          
          // Business info
          Row(
            children: [
              Icon(Icons.business, color: AppTheme.primaryOrange, size: 16),
              const SizedBox(width: 8),
              Text(
                promotion['business_name'] ?? 'Business',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            promotion['description'],
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          
          // Location and expiry
          if (promotion['location_city'] != null) ...[
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.info, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${promotion['location_city']}, ${promotion['location_country']}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.warning, size: 16),
              const SizedBox(width: 8),
              Text(
                PromotionsService.formatDate(promotion['end_date']),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PromotionsService.isEndingSoon(promotion) ? AppTheme.error : null,
                  fontWeight: PromotionsService.isEndingSoon(promotion) ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            children: [
              if (promotion['business_contact'] != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactBusiness(promotion),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.info,
                      side: BorderSide(color: AppTheme.info),
                    ),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Contact'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: promotion['link_url'] != null 
                      ? () {
                          Navigator.pop(context);
                          _openPromoLink(promotion);
                        }
                      : null,
                  style: AppTheme.primaryButtonStyle,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(promotion['link_url'] != null ? 'Visit Website' : 'No Website'),
                ),
              ),
            ],
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _contactBusiness(Map<String, dynamic> promotion) {
    final contact = promotion['business_contact'] as String?;
    if (contact == null) return;

    if (contact.contains('@')) {
      // Email
      final uri = Uri.parse('mailto:$contact');
      launchUrl(uri);
    } else {
      // Phone
      final uri = Uri.parse('tel:$contact');
      launchUrl(uri);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppTheme.error : AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Promotions & Deals'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) {
            final categories = PromotionsService.promotionCategories.keys.toList();
            _onCategoryChanged(categories[index]);
          },
          tabs: PromotionsService.promotionCategories.entries.map((entry) {
            final category = entry.value;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category['icon']!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(category['name']!, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _refreshPromotions,
              color: AppTheme.primaryOrange,
              child: _promotions.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _promotions.length,
                      itemBuilder: (context, index) {
                        final promotion = _promotions[index];
                        return _buildPromotionCard(promotion);
                      },
                    ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryOrange.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircularProgressIndicator(
              color: AppTheme.primaryOrange,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading promotions...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final categoryData = PromotionsService.promotionCategories[_selectedCategory]!;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                categoryData['icon']!,
                style: const TextStyle(fontSize: 80),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${categoryData['name']} Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Check back later for new deals and promotions in this category.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshPromotions,
              style: AppTheme.primaryButtonStyle,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion) {
    final isNew = PromotionsService.isNew(promotion);
    final isEndingSoon = PromotionsService.isEndingSoon(promotion);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEndingSoon 
              ? AppTheme.error.withOpacity(0.3)
              : Theme.of(context).dividerColor,
          width: isEndingSoon ? 2 : 1,
        ),
        boxShadow: Theme.of(context).brightness == Brightness.light ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: InkWell(
        onTap: () => _showPromotionDetails(promotion),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with badges
              Row(
                children: [
                  Expanded(
                    child: Text(
                      promotion['title'],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isEndingSoon) ...[
                    if (isNew) const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ENDING SOON',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Business name
              Row(
                children: [
                  Icon(Icons.business, color: AppTheme.primaryOrange, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    promotion['business_name'] ?? 'Business',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                promotion['description'],
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Footer info
              Row(
                children: [
                  // Location
                  if (promotion['location_city'] != null) ...[
                    Icon(Icons.location_on, color: AppTheme.info, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      promotion['location_city'],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  // Expiry
                  Icon(Icons.schedule, color: AppTheme.warning, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    PromotionsService.formatDate(promotion['end_date']),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isEndingSoon ? AppTheme.error : null,
                      fontWeight: isEndingSoon ? FontWeight.w600 : null,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Action button
                  ElevatedButton(
                    onPressed: promotion['link_url'] != null 
                        ? () => _openPromoLink(promotion)
                        : () => _showPromotionDetails(promotion),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      promotion['link_url'] != null ? 'View Deal' : 'Details',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}