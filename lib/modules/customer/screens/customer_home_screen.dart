import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/route_names.dart';
import '../../../shared/providers/customer_provider.dart';
import '../widgets/service_type_selector.dart';
import '../widgets/last_visited_list.dart';
import '../widgets/nearby_shops_list.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String selectedServiceType = 'All';
  int selectedTab = 0; // 0 = Last Visited, 1 = Nearby Shop

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomerData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Service Type Selection
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ServiceTypeSelector(
            selectedType: selectedServiceType,
            onTypeSelected: (type) {
              setState(() {
                selectedServiceType = type;
              });
            },
          ),
        ),

        // Tab Selection
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedTab == 0
                          ? const Color(0xFFCF2049)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Last Visited',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedTab == 1
                          ? const Color(0xFFCF2049)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Nearby Shop',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Content based on selected tab
        Expanded(
          child: selectedTab == 0
              ? LastVisitedList(serviceType: selectedServiceType)
              : NearbyShopsList(serviceType: selectedServiceType),
        ),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Service Progress Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go('/service-progress');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCF2049),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.build_circle_outlined),
                  label: const Text(
                    'Track Service Progress',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Search Shops Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.go(RouteNames.searchShops);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFCF2049),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Search Shops',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
