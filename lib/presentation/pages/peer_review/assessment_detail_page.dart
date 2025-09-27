import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/enrollment_controller.dart';
import '../../controllers/peer_review_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';
import '../../../domain/models/course_activity.dart';

class AssessmentDetailPage extends StatefulWidget {
  final String courseId;
  final String activityId;
  final String assessmentId;
  const AssessmentDetailPage(
      {super.key,
      required this.courseId,
      required this.activityId,
      required this.assessmentId});
  @override
  State<AssessmentDetailPage> createState() => _AssessmentDetailPageState();
}

class _AssessmentDetailPageState extends State<AssessmentDetailPage> {
  final activityController = Get.find<ActivityController>();
  final enrollmentController = Get.find<EnrollmentController>();
  PeerReviewController? _peerReviewController;
  CourseActivity? _cachedActivity;
  @override
  void initState() {
    super.initState();
    try {
      _peerReviewController = Get.find<PeerReviewController>();
    } catch (_) {}
    if (widget.courseId.isNotEmpty) {
      activityController.loadForCourse(widget.courseId);
      enrollmentController.loadEnrollmentsForCourse(widget.courseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pr = _peerReviewController;
    if (pr == null) {
      return const Scaffold(
          body: Center(child: Text('PeerReviewController no disponible')));
    }
    final assessments = pr.assessmentsForActivity(widget.activityId);
    final assessment =
        assessments.firstWhereOrNull((a) => a.id == widget.assessmentId);
    if (assessment == null) {
      return const Scaffold(
          body: Center(child: Text('Evaluación no encontrada')));
    }
    final activity = _resolveActivity();
    final isTeacherViewer =
        activity != null && pr.currentUserId == activity.createdBy;

    return CoursePageScaffold(
      header: CourseHeader(
        title: 'Evaluación',
        subtitle: 'Detalle',
        showEdit: false,
      ),
      sections: [
        _meta(assessment, pr.currentUserId, isTeacherViewer),
        _scores(assessment),
      ],
    );
  }

  Widget _meta(assessment, String? currentUserId, bool isTeacherViewer) {
    final reviewerLabel = isTeacherViewer
        ? _userName(assessment.reviewerId)
        : 'Compañero anónimo';
    String evaluatedLabel;
    if (isTeacherViewer) {
      evaluatedLabel = _userName(assessment.studentId);
    } else if (assessment.studentId == currentUserId) {
      evaluatedLabel = 'Tú';
    } else {
      evaluatedLabel = 'Compañero';
    }
    return SectionCard(
      title: 'Información',
      leadingIcon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Revisor', reviewerLabel),
          _kv('Evaluado', evaluatedLabel),
          _kv('Registrado', assessment.createdAt.toLocal().toString()),
        ],
      ),
    );
  }

  Widget _scores(assessment) {
    return SectionCard(
      title: 'Puntajes',
      leadingIcon: Icons.analytics_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _scoreRow('Puntualidad', assessment.punctualityScore),
          _scoreRow('Contribuciones', assessment.contributionsScore),
          _scoreRow('Compromiso', assessment.commitmentScore),
          _scoreRow('Actitud', assessment.attitudeScore),
          const Divider(height: 28),
          Row(
            children: [
              const Icon(Icons.star, color: AppTheme.goldAccent, size: 20),
              const SizedBox(width: 8),
              Text('Overall: ${assessment.overallScore.toStringAsFixed(1)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 110,
              child: Text(k,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: onSurface.withOpacity(.75)))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.goldAccent.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.goldAccent.withOpacity(.4)),
            ),
            child: Text('$score',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }

  CourseActivity? _resolveActivity() {
    if (_cachedActivity != null) return _cachedActivity;
    for (final list in activityController.activitiesByCourse.values) {
      final match = list.firstWhereOrNull((a) => a.id == widget.activityId);
      if (match != null) {
        _cachedActivity = match;
        break;
      }
    }
    return _cachedActivity;
  }

  String _userName(String userId) {
    final name = enrollmentController.userName(userId);
    if (name.isNotEmpty && name != 'Estudiante') return name;
    final email = enrollmentController.userEmail(userId);
    return email.isNotEmpty ? email : userId;
  }
}
