import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/shop_service.dart';
import '../../../core/services/shop_data_populator.dart';
import '../../../shared/models/shop_model.dart';
import '../widgets/shop_card.dart';

class ShopSearchScreen extends StatefulWidget {
  const ShopSearchScreen({super.key});

  @override
  State<ShopSearchScreen> createState() => _ShopSearchScreenState();
}

class _ShopSearchScreenState extends State<ShopSearchScreen> {
  final ShopService _shopService = ShopService();
  final ShopDataPopulator _dataPopulator = ShopDataPopulator();
  final TextEditingController _searchController = TextEditingController();

  List<Shop> _shops = [];
  List<Shop> _filteredShops = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // First, populate sample data if needed
      await _dataPopulator.populateSampleData();

      // Then load shops
      final shops = await _shopService.getAllShops();

      setState(() {
        _shops = shops;
        _filteredShops = shops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load shops: $e';
        _isLoading = false;
      });
    }
  }

  void _filterShops(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredShops = _shops;
      } else {
        _filteredShops = _shops.where((shop) {
          return shop.name.toLowerCase().contains(query.toLowerCase()) ||
              shop.description.toLowerCase().contains(query.toLowerCase()) ||
              shop.services.any(
                (service) =>
                    service.toLowerCase().contains(query.toLowerCase()),
              );
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search shops, services...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterShops('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _filterShops,
            ),
          ),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading shops...'),
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
            ElevatedButton(onPressed: _loadShops, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_filteredShops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No shops available'
                  : 'No shops found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'Shops will appear here once they are added to the database.'
                  : 'Try searching with different keywords.',
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _filteredShops.length,
      itemBuilder: (context, index) {
        final shop = _filteredShops[index];
        return ShopCard(
          shop: shop,
          onTap: () {
            context.go('/shop-details/${shop.id}');
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
