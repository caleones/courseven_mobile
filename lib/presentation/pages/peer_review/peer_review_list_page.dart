import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_routes.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/peer_review_controller.dart';
import '../../../domain/models/course_activity.dart';
import '../../controllers/membership_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';
import '../../../domain/repositories/user_repository.dart';

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
  final userRepo = Get.find<UserRepository>();
  final Map<String, String> _nameCache = {};
  final Map<String, String> _emailCache = {};

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
      
      final ids = {
        ...prCtrl.pendingPeers(activityId),
        ...prCtrl
            .assessmentsForActivity(activityId)
            .where((as) => as.reviewerId == prCtrl.currentUserId)
            .map((as) => as.studentId)
      };
      for (final id in ids) {
        if (_nameCache.containsKey(id) && _emailCache.containsKey(id)) continue;
        final u = await userRepo.getUserById(id);
        if (u != null) {
          _nameCache[id] = u.fullName.isNotEmpty
              ? u.fullName
              : (u.username.isNotEmpty ? u.username : u.email);
          _emailCache[id] = u.email;
        }
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = prCtrl.activitySummary(activityId);
    final pending = prCtrl.pendingPeers(activityId);
    final progress = prCtrl.progressFor(activityId);
    return Obx(() {
      final isLoading = prCtrl.isLoading.value &&
          prCtrl.assessmentsForActivity(activityId).isEmpty;
      final assessments = prCtrl.assessmentsForActivity(activityId);
      return CoursePageScaffold(
        header: CourseHeader(
          title: activity.title,
          subtitle: 'Peer Review',
          showEdit: false,
          trailingExtras: [
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator()),
              )
          ],
        ),
        sections: [
          _progressHeader(progress['done'] ?? 0, progress['total'] ?? 0),
          if ((progress['total'] ?? 0) == 0)
            _infoCard('Este grupo no requiere peer review (tamaño <= 1).'),
          if (pending.isNotEmpty)
            SectionCard(
              title: 'Pendientes',
              child: Column(
                children: pending
                    .map((pid) => _peerTile(pid, isDone: false, isSelf: false))
                    .toList(),
              ),
            ),
          if (assessments.isNotEmpty)
            SectionCard(
              title: 'Enviadas',
              child: Column(
                children: assessments
                    .where((a) => a.reviewerId == prCtrl.currentUserId)
                    .map((a) =>
                        _peerTile(a.studentId, isDone: true, isSelf: false))
                    .toList(),
              ),
            ),
          if (summary == null &&
              activity.privateReview &&
              prCtrl.isCompleted(activityId))
            _infoCard(
                'Resultados en revisión por el profesor (visibilidad privada).'),
        ],
        onRefresh: () => prCtrl.loadForActivity(activity),
      );
    });
  }

  Widget _progressHeader(int done, int total) {
    final completed = total > 0 && done == total;
    return SectionCard(
      title: 'Progreso',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$done / $total',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            backgroundColor: Colors.grey.shade300,
            color: AppTheme.goldAccent,
          ),
          if (completed) ...[
            const SizedBox(height: 8),
            const Text('¡Has completado todas tus evaluaciones!',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]
        ],
      ),
    );
  }

  Widget _peerTile(String peerId, {required bool isDone, bool isSelf = false}) {
    final name = _nameCache[peerId] ?? 'Compañero $peerId';
    final email = _emailCache[peerId] ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDone
              ? null
              : () {
                  Get.toNamed(AppRoutes.peerReviewEvaluate, arguments: {
                    'courseId': courseId,
                    'activityId': activityId,
                    'peerId': peerId,
                  });
                },
          child: Row(
            children: [
              CircleAvatar(
                child: Text((name.isNotEmpty ? name : peerId)
                    .substring(0, 2)
                    .toUpperCase()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isSelf ? 'Yo' : name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (email.isNotEmpty)
                      Text(email,
                          style: TextStyle(color: Colors.grey.shade700)),
                    Text(
                      isDone
                          ? (isSelf ? 'Auto-evaluación enviada' : 'Evaluado')
                          : (isSelf
                              ? 'Auto-evaluación pendiente'
                              : 'Pendiente'),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              if (isDone) const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
      ),
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
