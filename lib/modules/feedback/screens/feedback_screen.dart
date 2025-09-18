import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/feedback_service.dart';
import '../../../shared/models/service_progress_model.dart';
import 'feedback_form_screen.dart';
import 'view_feedback_screen.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final FeedbackService _feedbackService = FeedbackService();

  bool _loading = true;
  List<ServiceProgress> _completed = [];
  String? _selectedVehiclePlate;
  Map<String, bool> _hasFeedback = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _feedbackService.getCompletedServicesForCurrentUser();
    // Check which services already have feedback
    final feedbackMap = <String, bool>{};
    for (final item in items) {
      final hasFeedback = await _feedbackService.hasFeedbackForBooking(item.bookingId);
      feedbackMap[item.bookingId] = hasFeedback;
    }
    setState(() {
      _completed = items;
      _selectedVehiclePlate = items.isNotEmpty ? items.first.vehiclePlate : null;
      _hasFeedback = feedbackMap;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Feedback'),
        backgroundColor: const Color(0xFFCF2049),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _completed.isEmpty
              ? _buildEmpty()
              : _buildContent(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inbox, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('No completed services yet'),
          SizedBox(height: 4),
          Text('You can submit feedback after a service is completed.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final vehicles = _completed
        .map((e) => e.vehiclePlate)
        .toSet()
        .toList()
      ..sort();

    final filtered = _completed
        .where((e) => _selectedVehiclePlate == null
            ? true
            : e.vehiclePlate == _selectedVehiclePlate)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose Your Vehicle',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedVehiclePlate,
                  items: vehicles
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedVehiclePlate = v),
                ),
                const SizedBox(height: 12),
                ...filtered.map((sp) => _ServiceTile(
                  sp: sp,
                  hasFeedback: _hasFeedback[sp.bookingId] ?? false,
                  onTap: () async {
                    // Always check Firestore to avoid stale UI
                    final feedback = await _feedbackService.getFeedbackByBookingId(sp.bookingId);
                    if (!mounted) return;
                    if (feedback != null) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ViewFeedbackScreen(
                            feedback: feedback,
                            serviceProgress: sp,
                            onEdit: () async {
                              Navigator.pop(context);
                              await context.push(
                                '/feedback/form',
                                extra: {
                                  'sp': sp,
                                  'feedback': feedback,
                                },
                              );
                            },
                          ),
                        ),
                      );
                      // Refresh after returning from view (and possible edit)
                      if (mounted) await _load();
                    } else {
                      await context.push(
                        '/feedback/form',
                        extra: {'sp': sp},
                      );
                      // Refresh after returning from create
                      if (mounted) await _load();
                    }
                  },
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final ServiceProgress sp;
  final bool hasFeedback;
  final VoidCallback onTap;
  const _ServiceTile({required this.sp, required this.hasFeedback, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: const Color(0xFFF8F8F8),
        title: Text(
          'Workshop: ${sp.shopName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Service types: ${sp.serviceTypes.join(', ')}\nCompleted at: ${sp.updatedAt}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasFeedback) 
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}