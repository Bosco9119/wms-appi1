import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/shop_service.dart';
import '../../../shared/models/shop_model.dart';
import '../../../core/navigation/route_names.dart';

class ShopDetailsScreen extends StatefulWidget {
  final String shopId;

  const ShopDetailsScreen({super.key, required this.shopId});

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  final ShopService _shopService = ShopService();
  Shop? _shop;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadShopDetails();
  }

  Future<void> _loadShopDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final shop = await _shopService.getShopById(widget.shopId);
      setState(() {
        _shop = shop;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load shop details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading shop details...'),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: const Color(0xFFCF2049)),
            const SizedBox(height: 16),
            Text('Error', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(_error),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadShopDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_shop == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Shop not found'),
          ],
        ),
      );
    }

    return _buildShopDetails();
  }

  Widget _buildShopDetails() {
    final shop = _shop!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Image
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey[200]),
            child: shop.imageUrls.isNotEmpty
                ? Image.network(
                    shop.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.car_repair,
                          size: 64,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Icon(Icons.car_repair, size: 64, color: Colors.grey),
                  ),
          ),

          // Shop Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Name
                Text(
                  shop.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFCF2049),
                  ),
                ),

                const SizedBox(height: 8),

                // Rating and Review Count
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(width: 4),
                    Text(
                      shop.rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${shop.reviewCount} reviews)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: shop.isOpen ? Colors.green : const Color(0xFFCF2049),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        shop.isOpen ? 'Open' : 'Closed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  shop.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Services Overview
                const Text(
                  'Services Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (shop.serviceCounts.isNotEmpty)
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: shop.serviceCounts.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCF2049).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFCF2049).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${entry.key}: ${entry.value}+',
                          style: const TextStyle(
                            fontSize: 14,
                            color: const Color(0xFFCF2049),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 24),

                // Contact Information
                const Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _buildContactItem(Icons.location_on, 'Address', shop.address),
                _buildContactItem(Icons.phone, 'Phone', shop.phoneNumber),
                _buildContactItem(Icons.email, 'Email', shop.email),
                _buildContactItem(
                  Icons.access_time,
                  'Hours',
                  shop.operatingHours,
                ),

                const SizedBox(height: 32),

                // Book Now Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: shop.isOpen ? () {
                      context.go(RouteNames.bookingRoute(widget.shopId, shop.name));
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: shop.isOpen ? const Color(0xFFCF2049) : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      shop.isOpen ? 'Book Service' : 'Shop Closed',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
