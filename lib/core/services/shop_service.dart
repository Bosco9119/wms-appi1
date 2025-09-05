import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/shop_model.dart';

class ShopService {
  static final ShopService _instance = ShopService._internal();
  factory ShopService() => _instance;
  ShopService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all shops
  Future<List<Shop>> getAllShops() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('shops')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => Shop.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ ShopService: Error getting all shops: $e');
      return [];
    }
  }

  /// Get shop by ID
  Future<Shop?> getShopById(String shopId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('shops')
          .doc(shopId)
          .get();

      if (!doc.exists) return null;

      return Shop.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('❌ ShopService: Error getting shop by ID: $e');
      return null;
    }
  }

  /// Search shops by name or service
  Future<List<Shop>> searchShops(String query) async {
    try {
      if (query.isEmpty) return await getAllShops();

      final QuerySnapshot snapshot = await _firestore
          .collection('shops')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      return snapshot.docs
          .map((doc) => Shop.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ ShopService: Error searching shops: $e');
      return [];
    }
  }

  /// Get nearby shops (within radius)
  Future<List<Shop>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      // For now, return all shops. In production, you'd implement geospatial queries
      final List<Shop> allShops = await getAllShops();

      // Filter by distance (simplified calculation)
      return allShops.where((shop) {
        final double distance = _calculateDistance(
          latitude,
          longitude,
          shop.latitude,
          shop.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      print('❌ ShopService: Error getting nearby shops: $e');
      return [];
    }
  }

  /// Add shop to database
  Future<bool> addShop(Shop shop) async {
    try {
      await _firestore.collection('shops').doc(shop.id).set(shop.toMap());

      print('✅ ShopService: Shop added successfully: ${shop.name}');
      return true;
    } catch (e) {
      print('❌ ShopService: Error adding shop: $e');
      return false;
    }
  }

  /// Update shop
  Future<bool> updateShop(Shop shop) async {
    try {
      await _firestore.collection('shops').doc(shop.id).update(shop.toMap());

      print('✅ ShopService: Shop updated successfully: ${shop.name}');
      return true;
    } catch (e) {
      print('❌ ShopService: Error updating shop: $e');
      return false;
    }
  }

  /// Delete shop
  Future<bool> deleteShop(String shopId) async {
    try {
      await _firestore.collection('shops').doc(shopId).delete();

      print('✅ ShopService: Shop deleted successfully: $shopId');
      return true;
    } catch (e) {
      print('❌ ShopService: Error deleting shop: $e');
      return false;
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.cos() * lat2.cos() * (dLon / 2).sin() * (dLon / 2).sin();

    final double c = 2 * a.sqrt().asin();

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
}

// Extension for math functions
extension MathExtensions on double {
  double sin() => this * 3.14159265359 / 180;
  double cos() => this * 3.14159265359 / 180;
  double sqrt() => this * this;
  double asin() => this;
}
