import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/shop_model.dart';

class ShopDataPopulator {
  static final ShopDataPopulator _instance = ShopDataPopulator._internal();
  factory ShopDataPopulator() => _instance;
  ShopDataPopulator._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Populate database with sample shop data
  Future<void> populateSampleData() async {
    try {
      print('🔄 ShopDataPopulator: Starting to populate sample shop data...');

      final List<Shop> sampleShops = _getSampleShops();

      for (final Shop shop in sampleShops) {
        await _firestore
            .collection('shops')
            .doc(shop.id)
            .set(shop.toMap());
        
        print('✅ Added shop: ${shop.name}');
      }

      print('🎉 ShopDataPopulator: Successfully populated ${sampleShops.length} shops');
    } catch (e) {
      print('❌ ShopDataPopulator: Error populating data: $e');
    }
  }

  /// Get sample shop data
  List<Shop> _getSampleShops() {
    final DateTime now = DateTime.now();
    
    return [
      Shop(
        id: 'shop_001',
        name: 'Hup Seng Autoparts Repair Shop',
        description: 'We have more than 25 years experiences on servicing & repairing engines, transmission, suspension with the latest technology troubleshooting devices from UK. Our team of certified mechanics ensures your vehicle gets the best care possible.',
        address: '123 Jalan Ampang, 50450 Kuala Lumpur',
        phoneNumber: '+60 3-2161 2345',
        email: 'info@hupseng.com.my',
        imageUrls: [
          'https://images.unsplash.com/photo-1486754735734-325b5831c3ad?w=800',
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
        ],
        rating: 4.8,
        reviewCount: 1247,
        serviceCounts: {
          'Engines Service': 2800,
          'Transmission': 1900,
          'Suspension': 10000,
        },
        services: ['Engine Repair', 'Transmission Service', 'Suspension Work', 'Brake Service', 'Oil Change'],
        latitude: 3.1390,
        longitude: 101.6869,
        isOpen: true,
        operatingHours: 'Mon-Fri: 8:00 AM - 6:00 PM, Sat: 8:00 AM - 4:00 PM',
        createdAt: now,
        updatedAt: now,
      ),
      Shop(
        id: 'shop_002',
        name: 'AutoCare Plus Workshop',
        description: 'Professional automotive repair and maintenance services. Specializing in European and Japanese vehicles with state-of-the-art diagnostic equipment.',
        address: '456 Jalan Bukit Bintang, 50200 Kuala Lumpur',
        phoneNumber: '+60 3-2145 6789',
        email: 'service@autocareplus.com.my',
        imageUrls: [
          'https://images.unsplash.com/photo-1580414772602-4b8b4b4b4b4b?w=800',
        ],
        rating: 4.6,
        reviewCount: 892,
        serviceCounts: {
          'Engine Service': 1500,
          'Transmission': 1200,
          'Suspension': 8000,
        },
        services: ['Engine Tuning', 'Transmission Repair', 'Suspension Upgrade', 'AC Service'],
        latitude: 3.1478,
        longitude: 101.7000,
        isOpen: true,
        operatingHours: 'Mon-Sat: 8:30 AM - 6:30 PM',
        createdAt: now,
        updatedAt: now,
      ),
      Shop(
        id: 'shop_003',
        name: 'QuickFix Auto Service',
        description: 'Fast and reliable auto repair services. We specialize in quick fixes and routine maintenance to get you back on the road quickly.',
        address: '789 Jalan Puchong, 47100 Puchong, Selangor',
        phoneNumber: '+60 3-8075 1234',
        email: 'info@quickfix.com.my',
        imageUrls: [
          'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=800',
        ],
        rating: 4.4,
        reviewCount: 634,
        serviceCounts: {
          'Quick Service': 5000,
          'Oil Change': 3000,
          'Tire Service': 2000,
        },
        services: ['Quick Oil Change', 'Tire Rotation', 'Battery Check', 'Filter Replacement'],
        latitude: 3.0166,
        longitude: 101.6167,
        isOpen: true,
        operatingHours: 'Mon-Fri: 7:00 AM - 7:00 PM, Sat: 7:00 AM - 5:00 PM',
        createdAt: now,
        updatedAt: now,
      ),
      Shop(
        id: 'shop_004',
        name: 'Premium Motors Workshop',
        description: 'Luxury and high-performance vehicle specialists. We work on premium brands and provide top-tier service with genuine parts.',
        address: '321 Jalan Tun Razak, 50400 Kuala Lumpur',
        phoneNumber: '+60 3-2162 9876',
        email: 'premium@premiummotors.com.my',
        imageUrls: [
          'https://images.unsplash.com/photo-1563720223185-11003d516935?w=800',
        ],
        rating: 4.9,
        reviewCount: 456,
        serviceCounts: {
          'Luxury Service': 800,
          'Performance Tuning': 600,
          'Engine Rebuild': 400,
        },
        services: ['Luxury Car Service', 'Performance Tuning', 'Engine Rebuild', 'Custom Modifications'],
        latitude: 3.1390,
        longitude: 101.6869,
        isOpen: true,
        operatingHours: 'Mon-Fri: 9:00 AM - 6:00 PM, Sat: 9:00 AM - 3:00 PM',
        createdAt: now,
        updatedAt: now,
      ),
      Shop(
        id: 'shop_005',
        name: 'Budget Auto Repair',
        description: 'Affordable auto repair services without compromising quality. We provide honest pricing and reliable service for all vehicle types.',
        address: '654 Jalan Klang Lama, 58000 Kuala Lumpur',
        phoneNumber: '+60 3-2078 5432',
        email: 'budget@budgetauto.com.my',
        imageUrls: [
          'https://images.unsplash.com/photo-1580414772602-4b8b4b4b4b4b?w=800',
        ],
        rating: 4.2,
        reviewCount: 1123,
        serviceCounts: {
          'Basic Service': 4000,
          'Engine Repair': 2500,
          'Transmission': 1800,
        },
        services: ['Basic Maintenance', 'Engine Repair', 'Transmission Service', 'Brake Repair'],
        latitude: 3.1167,
        longitude: 101.6833,
        isOpen: true,
        operatingHours: 'Mon-Sat: 8:00 AM - 6:00 PM',
        createdAt: now,
        updatedAt: now,
      ),
      Shop(
        id: 'shop_006',
        name: '24/7 Emergency Auto Service',
        description: 'Round-the-clock emergency auto repair services. We are always available when you need us most, day or night.',
        address: '987 Jalan Sultan Ismail, 50250 Kuala Lumpur',
        phoneNumber: '+60 3-2143 9999',
        email: 'emergency@24x7auto.com.my',
        imageUrls: [
          'https://images.unsplash.com/photo-1486754735734-325b5831c3ad?w=800',
        ],
        rating: 4.7,
        reviewCount: 789,
        serviceCounts: {
          'Emergency Service': 2000,
          'Towing': 1500,
          'Roadside': 1000,
        },
        services: ['Emergency Repair', 'Towing Service', 'Roadside Assistance', 'Battery Jump Start'],
        latitude: 3.1390,
        longitude: 101.6869,
        isOpen: true,
        operatingHours: '24/7 - Always Open',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
