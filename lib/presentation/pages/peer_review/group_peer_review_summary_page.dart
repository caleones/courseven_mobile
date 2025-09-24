import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/peer_review_controller.dart';
import '../../../domain/models/peer_review_summaries.dart';

class GroupPeerReviewSummaryPage extends StatelessWidget {
  final String activityId;
  const GroupPeerReviewSummaryPage({super.key, required this.activityId});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PeerReviewController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen por Grupo')),
      body: Obx(() {
        final summary = ctrl.activitySummary(activityId);
        if (summary == null) {
          return const Center(child: Text('No hay datos aún.'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: summary.groups.map((g) => _groupTile(g)).toList(),
        );
      }),
    );
  }

  Widget _groupTile(GroupActivityReviewStats stats) {
    return Card(
      child: ExpansionTile(
        title: Text('Grupo ${stats.groupId}'),
        subtitle: Text(_formatAverages(stats.averages)),
        children: [
          if (stats.students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Integrantes',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...stats.students.map((s) => ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.only(left: 0, right: 0),
                        title: Text(s.studentId),
                        subtitle: Text(_formatAverages(s.averages)),
                        trailing: Text('n=${s.receivedCount}'),
                      ))
                ],
              ),
            )
        ],
      ),
    );
  }

  String _formatAverages(ScoreAverages a) =>
      'Punt: ${a.punctuality.toStringAsFixed(2)}  Contrib: ${a.contributions.toStringAsFixed(2)}  Comprom: ${a.commitment.toStringAsFixed(2)}  Actit: ${a.attitude.toStringAsFixed(2)}  Global: ${a.overall.toStringAsFixed(2)}';
}
