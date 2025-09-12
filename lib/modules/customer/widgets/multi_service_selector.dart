import 'package:flutter/material.dart';
import '../../../core/constants/service_types.dart';
import '../../../shared/models/service_type_model.dart';

class MultiServiceSelector extends StatelessWidget {
  final List<String> selectedServices;
  final Function(List<String>) onServicesChanged;
  final List<String>?
  availableServices; // Optional: restrict to specific services

  const MultiServiceSelector({
    super.key,
    required this.selectedServices,
    required this.onServicesChanged,
    this.availableServices,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Services',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _getAvailableServiceTypes().map((serviceType) {
            final isSelected = selectedServices.contains(serviceType.name);

            return GestureDetector(
              onTap: () {
                final newSelection = List<String>.from(selectedServices);
                if (isSelected) {
                  newSelection.remove(serviceType.name);
                } else {
                  newSelection.add(serviceType.name);
                }
                onServicesChanged(newSelection);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFCF2049)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? Border.all(color: const Color(0xFFCF2049), width: 2)
                      : Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(Icons.check, size: 16, color: Colors.white),
                    if (isSelected) const SizedBox(width: 4),
                    Text(
                      serviceType.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (selectedServices.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFCF2049).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Services:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFCF2049),
                  ),
                ),
                const SizedBox(height: 8),
                ...selectedServices.map((service) {
                  final serviceType = ServiceTypes.getByName(service);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(service),
                        if (serviceType != null)
                          Text(
                            '${serviceType.durationDisplay} - ${serviceType.costDisplay}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Duration:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${ServiceTypes.calculateTotalDuration(selectedServices)} min',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estimated Cost:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${ServiceTypes.calculateTotalCost(selectedServices).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<ServiceType> _getAvailableServiceTypes() {
    if (availableServices == null) {
      // If no restriction, return all service types
      return ServiceTypes.all;
    } else {
      // Filter service types based on available services
      return ServiceTypes.all
          .where((serviceType) => availableServices!.contains(serviceType.name))
          .toList();
    }
  }
}
