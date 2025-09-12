import 'package:flutter/material.dart';
import '../../../core/services/service_progress_service.dart';
import '../../../shared/models/service_progress_model.dart';
import '../../../core/services/auth_service.dart';

class ServiceProgressScreen extends StatefulWidget {
  const ServiceProgressScreen({super.key});

  @override
  State<ServiceProgressScreen> createState() => _ServiceProgressScreenState();
}

class _ServiceProgressScreenState extends State<ServiceProgressScreen> {
  final ServiceProgressService _serviceProgressService =
      ServiceProgressService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Progress'),
        backgroundColor: const Color(0xFFCF2049),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<ServiceProgress>>(
        stream: _getServiceProgressStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCF2049)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading service progress',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final serviceProgressList = snapshot.data ?? [];

          if (serviceProgressList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.build_circle_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Active Services',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You don\'t have any active vehicle services at the moment.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: serviceProgressList.length,
              itemBuilder: (context, index) {
                final serviceProgress = serviceProgressList[index];
                return ServiceProgressCard(
                  serviceProgress: serviceProgress,
                  onTap: () => _showServiceProgressDetails(serviceProgress),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Stream<List<ServiceProgress>> _getServiceProgressStream() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }
    return _serviceProgressService.streamActiveUserServiceProgress(
      currentUser.uid,
    );
  }

  void _showServiceProgressDetails(ServiceProgress serviceProgress) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ServiceProgressDetailsScreen(serviceProgress: serviceProgress),
      ),
    );
  }
}

class ServiceProgressCard extends StatelessWidget {
  final ServiceProgress serviceProgress;
  final VoidCallback onTap;

  const ServiceProgressCard({
    super.key,
    required this.serviceProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        serviceProgress.currentStatus,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(serviceProgress.currentStatus),
                      color: _getStatusColor(serviceProgress.currentStatus),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceProgress.vehicleModel,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          serviceProgress.vehiclePlate,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(serviceProgress.currentStatus),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      serviceProgress.statusDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: serviceProgress.progressPercentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getStatusColor(serviceProgress.currentStatus),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${serviceProgress.progressPercentage}% Complete',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      serviceProgress.shopName,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.build, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      serviceProgress.serviceTypes.join(', '),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              if (serviceProgress.estimatedTimeRemaining != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Estimated completion: ${_formatDuration(serviceProgress.estimatedTimeRemaining!)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.scheduled:
        return Colors.blue;
      case ServiceStatus.inInspection:
        return Colors.orange;
      case ServiceStatus.partsAwaiting:
        return Colors.amber;
      case ServiceStatus.inRepair:
        return Colors.purple;
      case ServiceStatus.qualityCheck:
        return Colors.indigo;
      case ServiceStatus.readyForCollection:
        return Colors.green;
      case ServiceStatus.completed:
        return Colors.green[700]!;
      case ServiceStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.scheduled:
        return Icons.schedule;
      case ServiceStatus.inInspection:
        return Icons.search;
      case ServiceStatus.partsAwaiting:
        return Icons.inventory;
      case ServiceStatus.inRepair:
        return Icons.build;
      case ServiceStatus.qualityCheck:
        return Icons.verified;
      case ServiceStatus.readyForCollection:
        return Icons.check_circle;
      case ServiceStatus.completed:
        return Icons.done_all;
      case ServiceStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

class ServiceProgressDetailsScreen extends StatelessWidget {
  final ServiceProgress serviceProgress;

  const ServiceProgressDetailsScreen({
    super.key,
    required this.serviceProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Details'),
        backgroundColor: const Color(0xFFCF2049),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Model', serviceProgress.vehicleModel),
                    _buildInfoRow('Plate', serviceProgress.vehiclePlate),
                    _buildInfoRow('Shop', serviceProgress.shopName),
                    _buildInfoRow(
                      'Services',
                      serviceProgress.serviceTypes.join(', '),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Current Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              serviceProgress.currentStatus,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getStatusIcon(serviceProgress.currentStatus),
                            color: _getStatusColor(
                              serviceProgress.currentStatus,
                            ),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                serviceProgress.statusDisplayName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                serviceProgress.statusDescription,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: serviceProgress.progressPercentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(serviceProgress.currentStatus),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${serviceProgress.progressPercentage}% Complete',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status History
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status History',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...serviceProgress.statusHistory.reversed.map((update) {
                      return _buildStatusHistoryItem(context, update);
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHistoryItem(
    BuildContext context,
    ServiceStatusUpdate update,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getStatusColor(update.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.statusDisplayName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (update.notes != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    update.notes!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '${_formatDateTime(update.timestamp)} • ${update.updatedBy}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.scheduled:
        return Colors.blue;
      case ServiceStatus.inInspection:
        return Colors.orange;
      case ServiceStatus.partsAwaiting:
        return Colors.amber;
      case ServiceStatus.inRepair:
        return Colors.purple;
      case ServiceStatus.qualityCheck:
        return Colors.indigo;
      case ServiceStatus.readyForCollection:
        return Colors.green;
      case ServiceStatus.completed:
        return Colors.green[700]!;
      case ServiceStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.scheduled:
        return Icons.schedule;
      case ServiceStatus.inInspection:
        return Icons.search;
      case ServiceStatus.partsAwaiting:
        return Icons.inventory;
      case ServiceStatus.inRepair:
        return Icons.build;
      case ServiceStatus.qualityCheck:
        return Icons.verified;
      case ServiceStatus.readyForCollection:
        return Icons.check_circle;
      case ServiceStatus.completed:
        return Icons.done_all;
      case ServiceStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
