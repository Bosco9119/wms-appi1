import 'package:flutter/material.dart';
import '../../../core/constants/service_types.dart';

class ServiceTypeSelector extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeSelected;

  const ServiceTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Service Type',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _getServiceTypes().length,
            itemBuilder: (context, index) {
              final serviceType = _getServiceTypes()[index];
              final isSelected = selectedType == serviceType;
              final isAll = serviceType == 'All';

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () => onTypeSelected(serviceType),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isAll ? const Color(0xFFCF2049) : Colors.blue)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? Border.all(
                              color: isAll
                                  ? const Color(0xFFCF2049)
                                  : Colors.blue,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        serviceType,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<String> _getServiceTypes() {
    // Get all service types including "All"
    return ['All', ...ServiceTypes.all.map((s) => s.name)];
  }
}
