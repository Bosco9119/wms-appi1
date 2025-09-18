import 'package:flutter/material.dart';
import '../../../core/services/feedback_service.dart';
import '../../../shared/models/service_progress_model.dart';

class FeedbackFormScreen extends StatefulWidget {
  final ServiceProgress serviceProgress;
  final Map<String, dynamic>? existingFeedback;
  const FeedbackFormScreen({super.key, required this.serviceProgress, this.existingFeedback});

  @override
  State<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<FeedbackFormScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  int _overall = 0;
  int _speed = 0;
  int _attitude = 0;
  int _quality = 0;
  final TextEditingController _comment = TextEditingController();
  bool _allowContact = false;
  final Set<String> _tags = {};
  bool _submitting = false;
  final Map<String, bool?> _answers = {
    'explained_clearly': null,
    'price_reasonable': null,
    'delivered_on_time': null,
    'service_quality_satisfactory': null,
    'staff_professional': null,
  };

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existingFeedback == null) return;
    final f = widget.existingFeedback!;
    _overall = f['rating'] ?? 0;
    _speed = f['timeliness'] ?? 0;
    _attitude = f['communication'] ?? 0;
    _quality = f['serviceQuality'] ?? 0;
    _comment.text = f['comment'] ?? '';
    _allowContact = f['allowContact'] ?? false;
    _tags.addAll(List<String>.from(f['tags'] ?? []));
    final rawQ = f['questions'];
    if (rawQ is Map) {
      final Map<String, dynamic> q = rawQ.map((k, v) => MapEntry(k.toString(), v));
      for (final entry in q.entries) {
        if (_answers.containsKey(entry.key) && entry.value is bool) {
          _answers[entry.key] = entry.value as bool;
        }
      }
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = widget.serviceProgress;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingFeedback == null ? 'Service Feedback' : 'Edit Feedback'),
        backgroundColor: const Color(0xFFCF2049),
        foregroundColor: Colors.white,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(
                title: sp.shopName,
                subtitle: '${sp.vehiclePlate} • ${sp.serviceTypes.join(', ')}',
              ),
              const SizedBox(height: 16),
              _RatingSection(
              title: 'RATE OUR SERVICE',
              children: [
                _StarRow(label: 'Service speed', value: _speed, onChanged: (v) => setState(() => _speed = v)),
                const SizedBox(height: 8),
                _StarRow(label: 'Staff Attitude', value: _attitude, onChanged: (v) => setState(() => _attitude = v)),
                const SizedBox(height: 8),
                _StarRow(label: 'Service Quality', value: _quality, onChanged: (v) => setState(() => _quality = v)),
                const SizedBox(height: 16),
                _StarRow(label: 'Overall', value: _overall, onChanged: (v) => setState(() => _overall = v)),
              ],
            ),
            const SizedBox(height: 16),
            _TagSelector(
              selected: _tags,
              onToggle: (t) => setState(() {
                if (_tags.contains(t)) {
                  _tags.remove(t);
                } else {
                  _tags.add(t);
                }
              }),
            ),
            const SizedBox(height: 16),
            _QuestionsCard(
              answers: _answers,
              onChanged: (key, val) => setState(() => _answers[key] = val),
            ),
            const SizedBox(height: 16),
            _CommentCard(controller: _comment),
            const SizedBox(height: 12),
            _SwitchCard(
              value: _allowContact,
              onChanged: (v) => setState(() => _allowContact = v),
            ),
            const SizedBox(height: 24),
            _BottomCTA(
              submitting: _submitting,
              label: widget.existingFeedback == null ? 'Submit' : 'Update',
              onPressed: _submitting ? null : _submit,
            ),
          ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_overall == 0 || _speed == 0 || _attitude == 0 || _quality == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate all categories.')),
      );
      return;
    }

    print('🔍 Debug: existingFeedback = ${widget.existingFeedback}');
    print('🔍 Debug: isEditMode = ${widget.existingFeedback != null}');

    setState(() => _submitting = true);

    bool ok;
    if (widget.existingFeedback == null) {
      ok = await _feedbackService.submitFeedback(
        bookingId: widget.serviceProgress.bookingId,
        shopId: widget.serviceProgress.shopId,
        ratingOverall: _overall,
        serviceQuality: _quality,
        timeliness: _speed,
        communication: _attitude,
        comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        tags: _tags.toList(),
        allowContact: _allowContact,
        // images removed
        questions: _answers
            .map((k, v) => v == null ? MapEntry<String, dynamic>(k, null) : MapEntry<String, dynamic>(k, v))
          ..removeWhere((key, value) => value == null),
      );
    } else {
      ok = await _feedbackService.updateFeedbackByBooking(
        bookingId: widget.serviceProgress.bookingId,
        ratingOverall: _overall,
        serviceQuality: _quality,
        timeliness: _speed,
        communication: _attitude,
        comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        tags: _tags.toList(),
        allowContact: _allowContact,
        // images removed
        questions: _answers
            .map((k, v) => v == null ? MapEntry<String, dynamic>(k, null) : MapEntry<String, dynamic>(k, v))
          ..removeWhere((key, value) => value == null),
      );
    }

    if (!mounted) return;
    
    setState(() => _submitting = false);

    if (ok) {
      // 編輯模式：返回上一頁並顯示成功提示
      if (widget.existingFeedback != null) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.maybePop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Feedback updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          });
        }
      } else {
        // 新增模式：返回上一頁並提示成功，避免與 page-based 導航衝突
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.maybePop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Feedback submitted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to submit feedback.')),
        );
      }
    }
  }

  // image upload removed
}

class _RatingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _RatingSection({required this.title, required this.children});

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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _StarRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label)),
        Row(
          children: List.generate(5, (i) {
            final idx = i + 1;
            final filled = idx <= value;
            return IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                filled ? Icons.star : Icons.star_border,
                color: filled ? const Color(0xFFCF2049) : Colors.grey,
              ),
              onPressed: () => onChanged(idx),
            );
          }),
        ),
      ],
    );
  }
}

class _CommentBox extends StatelessWidget {
  final TextEditingController controller;
  const _CommentBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'Leave a comment',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final TextEditingController controller;
  const _CommentCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Text('Leave a comment', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Share more details about your experience...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
      child: SwitchListTile(
        title: const Text('Allow the workshop to contact me'),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _QuestionsCard extends StatelessWidget {
  final Map<String, bool?> answers;
  final void Function(String key, bool value) onChanged;
  const _QuestionsCard({required this.answers, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget tile(String key, String label) {
      final groupVal = answers[key];
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
            ListTile(title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Yes'),
                    selected: groupVal == true,
                    onSelected: (_) => onChanged(key, true),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('No'),
                    selected: groupVal == false,
                    onSelected: (_) => onChanged(key, false),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Questions', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        tile('explained_clearly', 'Did staff explain clearly?'),
        const SizedBox(height: 12),
        tile('price_reasonable', 'Was the price reasonable?'),
        const SizedBox(height: 12),
        tile('delivered_on_time', 'Was the car delivered on time?'),
        const SizedBox(height: 12),
        tile('service_quality_satisfactory', 'Was the service quality satisfactory?'),
        const SizedBox(height: 12),
        tile('staff_professional', 'Was the staff professional?'),
      ],
    );
  }
}

class _BottomCTA extends StatelessWidget {
  final bool submitting;
  final String label;
  final VoidCallback? onPressed;
  const _BottomCTA({required this.submitting, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCF2049),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        child: submitting
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HeaderCard({required this.title, required this.subtitle});

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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _TagSelector extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const _TagSelector({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    const tags = [
      'Price',
      'Speed',
      'Quality',
      'Attitude',
      'Cleanliness',
      'Communication',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        const Text('Common Issues/Highlights:'),
        ...tags.map((t) => FilterChip(
              label: Text(t),
              selected: selected.contains(t),
              onSelected: (_) => onToggle(t),
            )),
      ],
    );
  }
}
