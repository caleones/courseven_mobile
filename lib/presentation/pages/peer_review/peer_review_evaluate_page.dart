import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/peer_review_rubric.dart';
import '../../../domain/models/assessment.dart';
import '../../../domain/models/course_activity.dart';
import '../../../domain/repositories/group_repository.dart';
import '../../../domain/repositories/membership_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/peer_review_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course/course_ui_components.dart';

class PeerReviewEvaluatePage extends StatefulWidget {
  const PeerReviewEvaluatePage({super.key});
  @override
  State<PeerReviewEvaluatePage> createState() => _PeerReviewEvaluatePageState();
}

class _PeerReviewEvaluatePageState extends State<PeerReviewEvaluatePage> {
  static const Map<String, String> _criterionTitles = {
    'punctuality': 'Puntualidad',
    'contributions': 'Contribuciones al equipo',
    'commitment': 'Compromiso',
    'attitude': 'Actitud y colaboración',
  };

  static const Map<String, String> _criterionDescriptions = {
    'punctuality':
        'Evalúa si la persona entrega sus trabajos y cumple acuerdos en los tiempos establecidos por el equipo.',
    'contributions':
        'Observa qué tanto aporta en entregables, ideas y trabajo efectivo para que el equipo avance.',
    'commitment':
        'Refleja cuánto se involucra con los objetivos del proyecto, asume tareas y las saca adelante.',
    'attitude':
        'Considera su disposición para escuchar, apoyar y mantener un ambiente saludable de trabajo.',
  };

  static const Map<String, IconData> _criterionIcons = {
    'punctuality': Icons.schedule_rounded,
    'contributions': Icons.handshake_rounded,
    'commitment': Icons.task_alt_rounded,
    'attitude': Icons.emoji_emotions_rounded,
  };

  static const List<int> _scoreScale = [2, 3, 4, 5];

  late final String courseId;
  late final String activityId;
  late final String peerId;

  final prCtrl = Get.find<PeerReviewController>();
  final actCtrl = Get.find<ActivityController>();
  final membershipRepo = Get.find<MembershipRepository>();
  final groupRepo = Get.find<GroupRepository>();
  final userRepo = Get.find<UserRepository>();

  CourseActivity? _activity;
  Assessment? _existingAssessment;
  String _peerName = '';
  String _peerEmail = '';
  bool _loading = true;

  int? _punctuality;
  int? _contributions;
  int? _commitment;
  int? _attitude;

  bool get _isReadOnly => _existingAssessment != null;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? const {};
    courseId = args['courseId'] ?? '';
    activityId = args['activityId'] ?? '';
    peerId = args['peerId'] ?? '';
    prCtrl.markEnterEvaluate(activityId, peerId);
    _bootstrap();
  }

  @override
  void dispose() {
    prCtrl.markFinishEvaluate(activityId, peerId);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      await _ensureActivityLoaded();
      final activity = _activity;
      if (activity == null) {
        setState(() => _loading = false);
        prCtrl.errorMessage.value = 'Actividad no encontrada.';
        return;
      }

      await prCtrl.loadForActivity(activity);
      final myAssessments = prCtrl.assessmentsForActivity(activityId);
      _existingAssessment = _findExistingAssessment(myAssessments);
      if (_existingAssessment != null) {
        _punctuality = _existingAssessment!.punctualityScore;
        _contributions = _existingAssessment!.contributionsScore;
        _commitment = _existingAssessment!.commitmentScore;
        _attitude = _existingAssessment!.attitudeScore;
      }

      final peer = await userRepo.getUserById(peerId);
      if (peer != null) {
        _peerName = peer.fullName.isNotEmpty
            ? peer.fullName
            : (peer.username.isNotEmpty ? peer.username : peer.email);
        _peerEmail = peer.email;
      }

      if (!_isReadOnly) {
        
        prCtrl.errorMessage.value = '';
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _ensureActivityLoaded() async {
    final cached = actCtrl.activitiesByCourse[courseId] ?? const [];
    _activity = _findActivity(cached, activityId);
    if (_activity != null) return;
    await actCtrl.loadForCourse(courseId);
    final refreshed = actCtrl.activitiesByCourse[courseId] ?? const [];
    _activity = _findActivity(refreshed, activityId);
  }

  CourseActivity? _findActivity(List<CourseActivity> list, String id) {
    for (final a in list) {
      if (a.id == id) return a;
    }
    return null;
  }

  Assessment? _findExistingAssessment(List<Assessment> list) {
    final userId = prCtrl.currentUserId;
    for (final assessment in list) {
      if (assessment.reviewerId == userId && assessment.studentId == peerId) {
        return assessment;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final activity = _activity;
    if (activity == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Peer Review')),
        body: const Center(
          child: Text('No pudimos cargar esta actividad para evaluar.'),
        ),
      );
    }

    final peerDisplay = _peerName.isNotEmpty ? _peerName : peerId;
    final isReadOnly = _isReadOnly;
    final statusChip = Chip(
      backgroundColor: isReadOnly ? Colors.green.shade100 : AppTheme.goldAccent,
      side: isReadOnly
          ? BorderSide(color: Colors.green.shade400, width: 1)
          : BorderSide.none,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      label: DefaultTextStyle(
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isReadOnly ? Colors.green.shade800 : AppTheme.premiumBlack,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isReadOnly ? Icons.check_circle : Icons.pending_actions,
              size: 16,
              color: isReadOnly ? Colors.green.shade700 : AppTheme.premiumBlack,
            ),
            const SizedBox(width: 6),
            Text(isReadOnly ? 'Enviada' : 'Pendiente'),
          ],
        ),
      ),
    );

    return CoursePageScaffold(
      header: CourseHeader(
        title: activity.title,
        subtitle: 'Evaluar a $peerDisplay',
        trailingExtras: [statusChip],
      ),
      sections: [
        _instructionsSection(peerDisplay),
        _peerSummarySection(peerDisplay),
        if (_existingAssessment != null) _submissionSummarySection(),
        _criterionSection('punctuality'),
        _criterionSection('contributions'),
        _criterionSection('commitment'),
        _criterionSection('attitude'),
        _overallSection(),
        _actionsSection(),
      ],
      showDock: false,
    );
  }

  Widget _instructionsSection(String peerDisplay) {
    return SectionCard(
      title: 'Antes de enviar',
      leadingIcon: Icons.menu_book_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona la opción que mejor describa la participación de $peerDisplay en tu equipo. Usa la escala de 2 (mínimo) a 5 (excelente).',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _bullet('Lee las descripciones detalladas de cada nivel y criterio.'),
          _bullet(
              'Compara con el desempeño real del compañero, no con expectativas ideales.'),
          _bullet(
              'Envía la evaluación solo cuando estés seguro; no se puede editar luego.'),
        ],
      ),
    );
  }

  Widget _peerSummarySection(String peerDisplay) {
    return SectionCard(
      title: 'Persona a evaluar',
      leadingIcon: Icons.person_rounded,
      child: SolidListTile(
        leadingIcon: Icons.account_circle,
        title: peerDisplay,
        subtitle: _peerEmail.isNotEmpty ? _peerEmail : 'ID: $peerId',
        trailing: _existingAssessment != null
            ? const Icon(Icons.verified_rounded, color: Colors.green)
            : const Icon(Icons.pending_rounded, color: AppTheme.goldAccent),
      ),
    );
  }

  Widget _submissionSummarySection() {
    final createdAt = _existingAssessment!.createdAt;
    final local = createdAt.toLocal();
    final formatted =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    return SectionCard(
      title: 'Evaluación enviada',
      leadingIcon: Icons.history_edu_rounded,
      outlined: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Promedio registrado: ${_existingAssessment!.overallScore.toStringAsFixed(1)} / 5'),
          const SizedBox(height: 8),
          Text('Fecha de envío: $formatted'),
          const SizedBox(height: 12),
          Text(
            'Los valores seleccionados se muestran abajo. Esta evaluación ya no se puede modificar.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _criterionSection(String key) {
    final title = _criterionTitles[key] ?? key;
    final description = _criterionDescriptions[key] ?? '';
    final icon = _criterionIcons[key] ?? Icons.star_rate_rounded;
    final selectedValue = _valueForKey(key);

    return SectionCard(
      title: title,
      leadingIcon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.85))),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              if (maxWidth < 360) {
                final itemWidth = (maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _scoreScale
                      .map((score) => SizedBox(
                            width: itemWidth,
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: _scoreOption(
                                key,
                                score,
                                isSelected: selectedValue == score,
                              ),
                            ),
                          ))
                      .toList(),
                );
              }
              return Row(
                children: _scoreScale
                    .map((score) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: score == _scoreScale.last ? 0 : 12),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: _scoreOption(
                                key,
                                score,
                                isSelected: selectedValue == score,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          _scoreGuidelines(key),
        ],
      ),
    );
  }

  Widget _scoreOption(String key, int score, {required bool isSelected}) {
    final enabled = !_isReadOnly;
    final bgColor = isSelected
        ? AppTheme.goldAccent.withValues(alpha: 0.95)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final textColor = isSelected
        ? AppTheme.premiumBlack
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: enabled
          ? () {
              setState(() {
                _assignValueForKey(key, score);
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppTheme.goldAccent
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
            width: isSelected ? 1.4 : 1.1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Text(
                '$score',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.check_rounded,
                      size: 16, color: AppTheme.premiumBlack),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _scoreGuidelines(String key) {
    final criteria = rubricCriteria[key];
    if (criteria == null) return const SizedBox.shrink();
    final entries = criteria.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.star_rate_rounded,
                      size: 16, color: AppTheme.goldAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _overallSection() {
    final average = _calculatedAverage();
    double progressValue = 0;
    if (average != null) {
      final normalized = average / 5;
      if (normalized < 0) {
        progressValue = 0;
      } else if (normalized > 1) {
        progressValue = 1;
      } else {
        progressValue = normalized;
      }
    }
    return SectionCard(
      title: 'Promedio general',
      leadingIcon: Icons.insights_rounded,
      outlined: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (average != null)
            Text(
              'Tu evaluación suma ${average.toStringAsFixed(1)} puntos sobre 5.',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            )
          else
            Text(
              'Selecciona todas las opciones para calcular el promedio.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progressValue,
            minHeight: 6,
            color: AppTheme.goldAccent,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _actionsSection() {
    final ready = _canSubmit();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          final busy = prCtrl.creating.value;
          return FilledButton.icon(
            onPressed: ready && !busy ? _handleSubmit : null,
            icon: busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppTheme.premiumBlack,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label:
                Text(_isReadOnly ? 'EVALUACIÓN ENVIADA' : 'ENVIAR EVALUACIÓN'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor:
                  ready && !busy ? AppTheme.goldAccent : Colors.grey.shade400,
              foregroundColor: AppTheme.premiumBlack,
              textStyle: const TextStyle(
                  letterSpacing: 0.8, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Obx(() {
          final msg = prCtrl.errorMessage.value;
          if (msg.isEmpty) return const SizedBox.shrink();
          return Text(
            msg,
            style: const TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.w600),
          );
        }),
      ],
    );
  }

  bool _canSubmit() {
    if (_isReadOnly) return false;
    return [_punctuality, _contributions, _commitment, _attitude]
        .every((value) => value != null);
  }

  double? _calculatedAverage() {
    if (!_canSubmit() && !_isReadOnly) return null;
    final p = _punctuality;
    final c = _contributions;
    final co = _commitment;
    final a = _attitude;
    if (p == null || c == null || co == null || a == null) return null;
    final avg = (p + c + co + a) / 4.0;
    return double.parse(avg.toStringAsFixed(2));
  }

  int? _valueForKey(String key) {
    switch (key) {
      case 'punctuality':
        return _punctuality;
      case 'contributions':
        return _contributions;
      case 'commitment':
        return _commitment;
      case 'attitude':
        return _attitude;
      default:
        return null;
    }
  }

  void _assignValueForKey(String key, int value) {
    switch (key) {
      case 'punctuality':
        _punctuality = value;
        break;
      case 'contributions':
        _contributions = value;
        break;
      case 'commitment':
        _commitment = value;
        break;
      case 'attitude':
        _attitude = value;
        break;
    }
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    final activity = _activity;
    if (activity == null) return;

    
    if (_isReadOnly) {
      prCtrl.errorMessage.value = 'Esta evaluación ya fue enviada.';
      return;
    }

    final groupId = await _resolveGroupId(activity);
    if (groupId == null) {
      prCtrl.errorMessage.value =
          'No se pudo resolver el grupo para esta evaluación.';
      return;
    }

    final created = await prCtrl.createAssessment(
      activity: activity,
      groupId: groupId,
      studentId: peerId,
      punctuality: _punctuality!,
      contributions: _contributions!,
      commitment: _commitment!,
      attitude: _attitude!,
    );

    if (created != null && mounted) {
      await prCtrl.loadForActivity(activity);
      prCtrl.markFinishEvaluate(activityId, peerId);
      prCtrl.errorMessage.value = '';
      Get.back(result: created);
    }
  }

  Future<String?> _resolveGroupId(CourseActivity activity) async {
    var groupId = prCtrl.groupIdFor(activity.id);
    if (groupId != null) return groupId;

    await prCtrl.loadForActivity(activity);
    groupId = prCtrl.groupIdFor(activity.id);
    if (groupId != null) return groupId;

    try {
      final userId = prCtrl.currentUserId;
      if (userId == null) return null;
      final myMemberships = await membershipRepo.getMembershipsByUserId(userId);
      final myGroupIds = myMemberships.map((m) => m.groupId).toSet();
      final categoryGroups =
          await groupRepo.getGroupsByCategory(activity.categoryId);
      for (final g in categoryGroups) {
        if (g.courseId == activity.courseId && myGroupIds.contains(g.id)) {
          return g.id;
        }
      }
      
      for (final g in categoryGroups) {
        final isMember = await membershipRepo.isUserMemberOfGroup(userId, g.id);
        if (isMember) return g.id;
      }
    } catch (e) {
      debugPrint('[PR][EVALUATE] resolveGroupId error: $e');
    }
    return null;
  }
}
