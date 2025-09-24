import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/models/peer_review_summaries.dart';
import '../../controllers/peer_review_controller.dart';

class CoursePeerReviewSummaryPage extends StatefulWidget {
  final String courseId;
  final List<String> activityIds; // Activities with peer review enabled
  const CoursePeerReviewSummaryPage(
      {super.key, required this.courseId, required this.activityIds});

  @override
  State<CoursePeerReviewSummaryPage> createState() =>
      _CoursePeerReviewSummaryPageState();
}

class _CoursePeerReviewSummaryPageState
    extends State<CoursePeerReviewSummaryPage> {
  final ctrl = Get.find<PeerReviewController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.loadCourseSummary(
          courseId: widget.courseId, activityIds: widget.activityIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peer Review - Resumen Curso')),
      body: Obx(() {
        if (ctrl.isLoading.value &&
            ctrl.courseSummary(widget.courseId) == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final error = ctrl.errorMessage.value;
        if (error.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: $error'),
            ),
          );
        }
        final summary = ctrl.courseSummary(widget.courseId);
        if (summary == null) {
          return const Center(child: Text('Sin datos de evaluaciones aún.'));
        }
        return _buildSummary(summary);
      }),
    );
  }

  Widget _buildSummary(CoursePeerReviewSummary summary) {
    return RefreshIndicator(
      onRefresh: () => ctrl
          .loadCourseSummary(
              courseId: widget.courseId,
              activityIds: widget.activityIds,
              force: true)
          .then((_) => null),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Actividades consideradas: ${widget.activityIds.length}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildStudentSection(summary),
          const SizedBox(height: 24),
          _buildGroupSection(summary),
        ],
      ),
    );
  }

  Widget _buildStudentSection(CoursePeerReviewSummary summary) {
    final stats = summary.students;
    if (stats.isEmpty) {
      return const SizedBox();
    }
    return ExpansionTile(
      title: const Text('Promedios por Estudiante'),
      children: stats.map((s) {
        return ListTile(
          dense: true,
          title: Text(s.studentId),
          subtitle: Text(_formatAverages(s.averages)),
          trailing: Text('n=${s.assessmentsReceived}'),
        );
      }).toList(),
    );
  }

  Widget _buildGroupSection(CoursePeerReviewSummary summary) {
    final stats = summary.groups;
    if (stats.isEmpty) return const SizedBox();
    return ExpansionTile(
      initiallyExpanded: false,
      title: const Text('Promedios por Grupo'),
      children: stats.map((g) {
        return ListTile(
          dense: true,
          title: Text('Grupo ${g.groupId}'),
          subtitle: Text(_formatAverages(g.averages)),
          trailing: Text('n=${g.assessmentsCount}'),
        );
      }).toList(),
    );
  }

  String _formatAverages(ScoreAverages a) =>
      'Punt: ${a.punctuality.toStringAsFixed(2)}  Contrib: ${a.contributions.toStringAsFixed(2)}  Comprom: ${a.commitment.toStringAsFixed(2)}  Actit: ${a.attitude.toStringAsFixed(2)}  Global: ${a.overall.toStringAsFixed(2)}';
}
