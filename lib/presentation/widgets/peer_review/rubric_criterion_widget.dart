import 'package:flutter/material.dart';
import '../../../core/config/peer_review_rubric.dart';

class RubricCriterionWidget extends StatelessWidget {
  final String criterionKey; 
  final String title;
  final int? selected;
  final ValueChanged<int> onChanged;

  const RubricCriterionWidget({
    super.key,
    required this.criterionKey,
    required this.title,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const scores = [2, 3, 4, 5];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: scores.map((s) => _chip(context, s)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, int score) {
    final isSel = selected == score;
    final text = rubricLabel(criterionKey, score);
    return ChoiceChip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(score.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(text, style: const TextStyle(fontSize: 10)),
        ],
      ),
      selected: isSel,
      onSelected: (_) => onChanged(score),
    );
  }
}
