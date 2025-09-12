import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/shop_service.dart';
import '../../../core/constants/service_types.dart';
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
            const Icon(
              Icons.error_outline,
              size: 64,
              color: const Color(0xFFCF2049),
            ),
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
                        color: shop.isOpen
                            ? Colors.green
                            : const Color(0xFFCF2049),
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

                const SizedBox(height: 24),

                // Available Services Section
                _buildServicesSection(shop),

                const SizedBox(height: 32),

                // Book Now Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: shop.isOpen
                        ? () {
                            context.go(
                              RouteNames.bookingRoute(widget.shopId, shop.name),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: shop.isOpen
                          ? const Color(0xFFCF2049)
                          : Colors.grey,
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

  Widget _buildServicesSection(Shop shop) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.build_circle_outlined,
                  color: Color(0xFFCF2049),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Available Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCF2049),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (shop.services.isEmpty)
              const Text(
                'No services available',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shop.services.map((serviceName) {
                  final serviceType = ServiceTypes.getByName(serviceName);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCF2049).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFCF2049).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getServiceIcon(serviceName),
                          size: 16,
                          color: const Color(0xFFCF2049),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          serviceName,
                          style: const TextStyle(
                            color: Color(0xFFCF2049),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        if (serviceType != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${serviceType.durationDisplay})',
                            style: TextStyle(
                              color: const Color(0xFFCF2049).withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            if (shop.services.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All services shown are available for booking at this shop',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getServiceIcon(String serviceName) {
    switch (serviceName) {
      case 'Oil Change':
        return Icons.oil_barrel;
      case 'Brake Check':
        return Icons.stop_circle_outlined;
      case 'Tire Rotation':
        return Icons.rotate_right;
      case 'Engine Diagnostic':
        return Icons.engineering;
      case 'Transmission Service':
        return Icons.settings;
      case 'Battery Check':
        return Icons.battery_charging_full;
      case 'Air Filter Replacement':
        return Icons.air;
      case 'Spark Plug Replacement':
        return Icons.flash_on;
      case 'Coolant Flush':
        return Icons.water_drop;
      case 'AC System Check':
        return Icons.ac_unit;
      case 'Wheel Alignment':
        return Icons.straighten;
      case 'Exhaust System Check':
        return Icons.smoke_free;
      default:
        return Icons.build;
    }
  }
}
