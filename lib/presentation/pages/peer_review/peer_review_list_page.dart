import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_routes.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/peer_review_controller.dart';
import '../../../domain/models/course_activity.dart';
import '../../controllers/membership_controller.dart';
import '../../../domain/models/peer_review_summaries.dart';

class PeerReviewListPage extends StatefulWidget {
  const PeerReviewListPage({super.key});
  @override
  State<PeerReviewListPage> createState() => _PeerReviewListPageState();
}

class _PeerReviewListPageState extends State<PeerReviewListPage> {
  late final String courseId;
  late final String activityId;
  late CourseActivity activity;
  final prCtrl = Get.find<PeerReviewController>();
  final actCtrl = Get.find<ActivityController>();
  final membershipCtrl = Get.find<MembershipController>();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    activityId = args?['activityId'] ?? '';
    _initLoad();
  }

  Future<void> _initLoad() async {
    final list = actCtrl.activitiesByCourse[courseId] ?? [];
    final a = list.firstWhereOrNull((x) => x.id == activityId);
    if (a != null) {
      activity = a;
      await prCtrl.loadForActivity(activity);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = prCtrl.activitySummary(activityId);
    final pending = prCtrl.pendingPeers(activityId);
    final progress = prCtrl.progressFor(activityId);
    return Scaffold(
      appBar: AppBar(title: const Text('Peer Review')),
      body: Obx(() {
        if (prCtrl.isLoading.value &&
            prCtrl.assessmentsForActivity(activityId).isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final assessments = prCtrl.assessmentsForActivity(activityId);
        return RefreshIndicator(
          onRefresh: () => prCtrl.loadForActivity(activity),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _progressHeader(progress['done'] ?? 0, progress['total'] ?? 0),
              const SizedBox(height: 16),
              if ((progress['total'] ?? 0) == 0)
                _infoCard('Este grupo no requiere peer review (tamaño <= 1).'),
              if (pending.isNotEmpty) ...[
                Text('Pendientes',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...pending.map((pid) => _peerTile(pid, isDone: false)).toList(),
                const SizedBox(height: 20),
              ],
              if (assessments.isNotEmpty) ...[
                Text('Enviadas',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...assessments
                    .where((a) => a.reviewerId == prCtrl.currentUserId)
                    .map((a) => _peerTile(a.studentId, isDone: true))
                    .toList(),
                const SizedBox(height: 24),
              ],
              if (summary != null &&
                  prCtrl.canStudentSeePublicResults(activity))
                _publicResults(summary),
              if (summary == null &&
                  activity.peerVisibility == 'private' &&
                  prCtrl.isCompleted(activityId))
                _infoCard(
                    'Resultados en revisión por el profesor (visibilidad privada).'),
            ],
          ),
        );
      }),
    );
  }

  Widget _progressHeader(int done, int total) {
    final completed = total > 0 && done == total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progreso: $done / $total',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: total == 0 ? 0 : done / total,
          backgroundColor: Colors.grey.shade300,
        ),
        if (completed) ...[
          const SizedBox(height: 8),
          const Text('¡Has completado todas tus evaluaciones!',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ]
      ],
    );
  }

  Widget _peerTile(String peerId, {required bool isDone}) {
    return Card(
      child: ListTile(
        leading:
            CircleAvatar(child: Text(peerId.substring(0, 2).toUpperCase())),
        title: Text('Usuario $peerId'),
        subtitle: Text(isDone ? 'Evaluado' : 'Pendiente'),
        trailing: isDone
            ? const Icon(Icons.check, color: Colors.green)
            : const Icon(Icons.play_arrow),
        onTap: isDone
            ? null
            : () {
                Get.toNamed(AppRoutes.peerReviewEvaluate, arguments: {
                  'courseId': courseId,
                  'activityId': activityId,
                  'peerId': peerId,
                });
              },
      ),
    );
  }

  Widget _publicResults(ActivityPeerReviewSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resultados (Promedios)',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...summary.groups.expand((g) => g.students).map((s) => ListTile(
              title: Text('Estudiante ${s.studentId}'),
              subtitle: Text('Avg: ${s.averages.overall.toStringAsFixed(2)}'),
            )),
      ],
    );
  }

  Widget _infoCard(String msg) => Card(
        color: Colors.blueGrey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(msg),
        ),
      );
}
