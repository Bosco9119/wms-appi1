import 'package:flutter/material.dart';
import '../../../shared/models/service_progress_model.dart';

class ViewFeedbackScreen extends StatelessWidget {
  final Map<String, dynamic> feedback;
  final ServiceProgress serviceProgress;
  final VoidCallback? onEdit;
  const ViewFeedbackScreen({super.key, required this.feedback, required this.serviceProgress, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final createdAt = _parseDate(feedback['createdAt']);
    final updatedAt = _parseDate(feedback['updatedAt']);
    final tags = List<String>.from(feedback['tags'] ?? const []);
    final allowContact = (feedback['allowContact'] ?? false) == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Details'),
        backgroundColor: const Color(0xFFCF2049),
        foregroundColor: Colors.white,
        actions: [
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
        ],
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFEEF2), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(
                title: serviceProgress.shopName,
                subtitle: '${serviceProgress.vehiclePlate} • ${serviceProgress.serviceTypes.join(', ')}',
                meta: serviceProgress.updatedAt?.toLocal().toString() ?? '',
              ),
              const SizedBox(height: 16),
              _ScoreCard(
                overall: feedback['rating'] ?? 0,
                quality: feedback['serviceQuality'] ?? 0,
                timeliness: feedback['timeliness'] ?? 0,
                communication: feedback['communication'] ?? 0,
              ),
              const SizedBox(height: 16),
              if (tags.isNotEmpty)
                _TagsCard(tags: tags),
              if (tags.isNotEmpty) const SizedBox(height: 16),
              _QuestionsCard(feedback: feedback),
              const SizedBox(height: 16),
              _CommentCard(text: (feedback['comment'] ?? '').toString()),
              const SizedBox(height: 16),
              _MetaCard(
                createdAt: createdAt,
                updatedAt: updatedAt,
                allowContact: allowContact,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: onEdit == null
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCF2049),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: const Text('Edit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
    );
  }

  String _parseDate(dynamic d) {
    if (d == null) return 'N/A';
    try {
      return DateTime.parse(d.toString()).toLocal().toString();
    } catch (_) {
      return d.toString();
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String meta;
  const _HeaderCard({required this.title, required this.subtitle, required this.meta});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFCF2049).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store, color: Color(0xFFCF2049)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 4),
                Text(meta, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int overall;
  final int quality;
  final int timeliness;
  final int communication;
  const _ScoreCard({required this.overall, required this.quality, required this.timeliness, required this.communication});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          const Text('Overall Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(5, (i) => Icon(
                i < overall ? Icons.star : Icons.star_border,
                color: const Color(0xFFCF2049),
              )),
              const SizedBox(width: 8),
              Text('$overall/5', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _ScoreRow(label: 'Service Quality', value: quality),
          _ScoreRow(label: 'Timeliness', value: timeliness),
          _ScoreRow(label: 'Communication', value: communication),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int value;
  const _ScoreRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: List.generate(5, (i) => Icon(
              i < value ? Icons.star : Icons.star_border,
              color: const Color(0xFFCF2049),
              size: 16,
            )),
          ),
        ],
      ),
    );
  }
}

class _TagsCard extends StatelessWidget {
  final List<String> tags;
  const _TagsCard({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          const Text('Tags', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((t) => Chip(label: Text(t))).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuestionsCard extends StatelessWidget {
  final Map<String, dynamic> feedback;
  const _QuestionsCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final rawQ = feedback['questions'];
    if (rawQ == null || rawQ is! Map) return const SizedBox.shrink();
    final Map<String, dynamic> q = rawQ.map((k, v) => MapEntry(k.toString(), v));
    final questions = {
      'explained_clearly': 'Did staff explain clearly?',
      'price_reasonable': 'Was the price reasonable?',
      'delivered_on_time': 'Was the car delivered on time?',
      'service_quality_satisfactory': 'Was the service quality satisfactory?',
      'staff_professional': 'Was the staff professional?',
    };
    return Container(
      width: double.infinity,
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
          const Text('Quick Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...questions.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.value),
                Text(
                  q[e.key] == true ? 'Yes' : q[e.key] == false ? 'No' : 'N/A',
                  style: TextStyle(
                    color: q[e.key] == true ? Colors.green : q[e.key] == false ? Colors.red : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final String text;
  const _CommentCard({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
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
          const Text('Comment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(text),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  final String createdAt;
  final String updatedAt;
  final bool allowContact;
  const _MetaCard({required this.createdAt, required this.updatedAt, required this.allowContact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          const Text('Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Created: $createdAt'),
          Text('Updated: $updatedAt'),
          Text('Allow contact: ${allowContact ? 'Yes' : 'No'}'),
        ],
      ),
    );
  }
}
