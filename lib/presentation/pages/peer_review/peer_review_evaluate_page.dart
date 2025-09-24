import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/peer_review_controller.dart';
import '../../controllers/activity_controller.dart';
import '../../../domain/models/course_activity.dart';
import '../../widgets/peer_review/rubric_criterion_widget.dart';

class PeerReviewEvaluatePage extends StatefulWidget {
  const PeerReviewEvaluatePage({super.key});
  @override
  State<PeerReviewEvaluatePage> createState() => _PeerReviewEvaluatePageState();
}

class _PeerReviewEvaluatePageState extends State<PeerReviewEvaluatePage> {
  late final String courseId;
  late final String activityId;
  late final String peerId;
  final prCtrl = Get.find<PeerReviewController>();
  final actCtrl = Get.find<ActivityController>();

  int? punctuality;
  int? contributions;
  int? commitment;
  int? attitude;
  bool submitting = false;

  late CourseActivity activity;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    activityId = args?['activityId'] ?? '';
    peerId = args?['peerId'] ?? '';
    final list = actCtrl.activitiesByCourse[courseId] ?? [];
    activity = list.firstWhere((a) => a.id == activityId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Evaluar a $peerId')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RubricCriterionWidget(
              criterionKey: 'punctuality',
              title: 'Punctuality',
              selected: punctuality,
              onChanged: (v) => setState(() => punctuality = v),
            ),
            RubricCriterionWidget(
              criterionKey: 'contributions',
              title: 'Contributions',
              selected: contributions,
              onChanged: (v) => setState(() => contributions = v),
            ),
            RubricCriterionWidget(
              criterionKey: 'commitment',
              title: 'Commitment',
              selected: commitment,
              onChanged: (v) => setState(() => commitment = v),
            ),
            RubricCriterionWidget(
              criterionKey: 'attitude',
              title: 'Attitude',
              selected: attitude,
              onChanged: (v) => setState(() => attitude = v),
            ),
            const SizedBox(height: 10),
            if (_canSubmit()) _overallPreview(),
            const SizedBox(height: 24),
            Obx(() => ElevatedButton(
                  onPressed:
                      _canSubmit() && !prCtrl.creating.value && !submitting
                          ? _submit
                          : null,
                  child: prCtrl.creating.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Enviar'),
                )),
            const SizedBox(height: 12),
            Obx(() => prCtrl.errorMessage.isNotEmpty
                ? Text(prCtrl.errorMessage.value,
                    style: const TextStyle(color: Colors.red))
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _overallPreview() {
    final avg = (punctuality! + contributions! + commitment! + attitude!) / 4.0;
    return Card(
      color: Colors.blueGrey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.insights, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Text('Overall estimado: ${avg.toStringAsFixed(1)}'),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() => [punctuality, contributions, commitment, attitude]
      .every((e) => e != null);

  Future<void> _submit() async {
    setState(() => submitting = true);
    // Necesitamos el groupId del peer review: tomamos uno de los assessments o cargar memberships (simplificado: pedimos al controller recargar y deducir)
    // Aquí por simplicidad no resolvemos groupId dinámico; asumimos que el controller ya lo determinó al cargar y podemos tomar cualquier assessment existente del peer o fallback error.
    final existing = prCtrl.assessmentsForActivity(activityId);
    String? groupId;
    if (existing.isNotEmpty) {
      groupId = existing.first.groupId;
    } else {
      // fallback: no hay assessments aún => no conocemos groupId, abortar amigablemente
      prCtrl.errorMessage.value =
          'No se pudo resolver groupId (carga inicial requerida)';
      setState(() => submitting = false);
      return;
    }
    final created = await prCtrl.createAssessment(
      activity: activity,
      groupId: groupId,
      studentId: peerId,
      punctuality: punctuality!,
      contributions: contributions!,
      commitment: commitment!,
      attitude: attitude!,
    );
    setState(() => submitting = false);
    if (created != null && mounted) {
      Get.back();
    }
  }
}
