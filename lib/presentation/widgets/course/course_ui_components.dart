import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import 'dart:math' as math;
import '../bottom_navigation_dock.dart';




class CoursePageScaffold extends StatelessWidget {
  final Widget header;
  final List<Widget> sections;
  final EdgeInsets padding;
  final bool showDock;
  final int dockIndex;
  final bool hasNotifications; 
  final Future<void> Function()? onRefresh;
  const CoursePageScaffold({
    super.key,
    required this.header,
    required this.sections,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
    this.showDock = true,
    this.dockIndex = -1,
    this.hasNotifications = true,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 20),
          ..._intersperse(sections, const SizedBox(height: 20)),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: onRefresh != null
            ? RefreshIndicator(
                onRefresh: onRefresh!,
                color: AppTheme.goldAccent,
                backgroundColor: Theme.of(context).cardColor,
                child: content,
              )
            : content,
      ),
      bottomNavigationBar:
          showDock ? BottomNavigationDock(currentIndex: dockIndex) : null,
    );
  }
}

class CourseHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showEdit;
  final VoidCallback? onEdit;
  final bool inactive;
  final List<Widget>? trailingExtras; 
  final EdgeInsets margin;
  const CourseHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showEdit = false,
    this.onEdit,
    this.inactive = false,
    this.trailingExtras,
    this.margin = EdgeInsets.zero,
  });
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: margin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppTheme.goldAccent, size: 20),
            onPressed: () => Get.back(),
            tooltip: 'Atrás',
            padding: const EdgeInsets.only(right: 8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: onSurface.withOpacity(.75))),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 4,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                fontWeight: FontWeight.w800, height: 1.15)),
                    
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (showEdit)
            ElevatedButton.icon(
              onPressed: onEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldAccent,
                foregroundColor: AppTheme.premiumBlack,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('EDITAR'),
            ),
          if (trailingExtras != null) ...trailingExtras!,
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final int? count; 
  final Widget child;
  final IconData? leadingIcon;
  final bool outlined;
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.count,
    this.leadingIcon,
    this.outlined = true,
  });
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.goldAccent.withOpacity(outlined ? 0.5 : 0.15),
            width: outlined ? 1.2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 20, color: AppTheme.goldAccent),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: onSurface)),
              ),
              if (count != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text('$count en total',
                      style: const TextStyle(
                          color: AppTheme.premiumBlack,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}


class SectionHeaderSlim extends StatelessWidget {
  final String title;
  final int? count;
  final IconData? icon;
  const SectionHeaderSlim(
      {super.key, required this.title, this.count, this.icon});
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppTheme.goldAccent),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(title.toUpperCase(),
                style: TextStyle(
                    fontSize: 15.5,
                    letterSpacing: .5,
                    fontWeight: FontWeight.w700,
                    color: onSurface)),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(.4)),
              ),
              child: Text('$count en total',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: onSurface.withOpacity(.8))),
            ),
        ],
      ),
    );
  }
}

class SolidListTile extends StatelessWidget {
  final String title;
  final String? subtitle; 
  final Widget? trailing;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final bool goldOutline;
  final Widget? bodyBelowTitle; 
  final bool dense;
  final Color? outlineColor;
  final Color? leadingIconColor;
  final double? marginBottom; 
  const SolidListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.leadingIcon,
    this.goldOutline = true,
    this.bodyBelowTitle,
    this.dense = false,
    this.outlineColor,
    this.leadingIconColor,
    this.marginBottom,
  });
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: marginBottom ?? (dense ? 8 : 12)),
        padding: EdgeInsets.symmetric(
            horizontal: dense ? 12 : 14, vertical: dense ? 10 : 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: outlineColor ??
                  (goldOutline
                      ? AppTheme.goldAccent.withOpacity(.45)
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(.12))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon,
                  size: dense ? 18 : 20,
                  color: leadingIconColor ?? AppTheme.goldAccent),
              SizedBox(width: dense ? 8 : 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: dense ? 14.5 : 15.5,
                          color: onSurface)),
                  if (subtitle != null) ...[
                    SizedBox(height: dense ? 2 : 4),
                    Text(subtitle!,
                        style: TextStyle(
                            fontSize: dense ? 11.5 : 12.5,
                            color: onSurface.withOpacity(.65))),
                  ] else if (bodyBelowTitle != null) ...[
                    SizedBox(height: dense ? 2 : 4),
                    bodyBelowTitle!,
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: dense ? 8 : 12),
              trailing!,
            ]
          ],
        ),
      ),
    );
  }
}

class DualActionButtons extends StatelessWidget {
  final String primaryLabel;
  final String secondaryLabel;
  final IconData? primaryIcon;
  final IconData? secondaryIcon;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final bool primaryEnabled;
  final bool secondaryEnabled;
  final bool secondarySolid;
  const DualActionButtons({
    super.key,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.primaryIcon,
    this.secondaryIcon,
    this.onPrimary,
    this.onSecondary,
    this.primaryEnabled = true,
    this.secondaryEnabled = true,
    this.secondarySolid = true,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const textStyle = TextStyle(fontWeight: FontWeight.w600);
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(primaryIcon ?? Icons.add),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryEnabled
                  ? AppTheme.goldAccent
                  : theme.disabledColor.withOpacity(0.1),
              foregroundColor: AppTheme.premiumBlack,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: textStyle,
            ),
            onPressed: primaryEnabled ? onPrimary : null,
            label: Text(primaryLabel.toUpperCase()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: secondarySolid
              ? ElevatedButton.icon(
                  icon: Icon(secondaryIcon ?? Icons.visibility),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryEnabled
                        ? AppTheme.successGreen
                        : theme.disabledColor.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: textStyle,
                  ),
                  onPressed: secondaryEnabled ? onSecondary : null,
                  label: Text(secondaryLabel.toUpperCase()),
                )
              : OutlinedButton.icon(
                  icon: Icon(secondaryIcon ?? Icons.visibility),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.successGreen,
                    side: BorderSide(color: AppTheme.successGreen),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: textStyle,
                  ),
                  onPressed: secondaryEnabled ? onSecondary : null,
                  label: Text(secondaryLabel.toUpperCase()),
                ),
        ),
      ],
    );
  }
}



class Pill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool danger;
  final bool gold;
  
  
  final double? maxWidth;
  
  
  final double screenWidthFactor;
  final double safeHorizontalPadding;
  const Pill(
      {super.key,
      required this.text,
      this.icon,
      this.danger = false,
      this.gold = true,
      this.maxWidth,
      this.screenWidthFactor = 0.5,
      this.safeHorizontalPadding = 96});

  @override
  Widget build(BuildContext context) {
    final Color borderColor = danger
        ? AppTheme.dangerRed
        : (gold
            ? AppTheme.goldAccent.withOpacity(.45)
            : Theme.of(context).dividerColor.withOpacity(.4));
    final Color bgColor = danger
        ? AppTheme.dangerRed.withOpacity(.12)
        : (gold
            ? AppTheme.goldAccent.withOpacity(.12)
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(.35));
    final Color fgColor = danger
        ? AppTheme.dangerRed
        : Theme.of(context).colorScheme.onSurface.withOpacity(.8);
    return LayoutBuilder(
      builder: (ctx, constraints) {
        
        
        final screenW = MediaQuery.of(ctx).size.width;
        final fallback = ((screenW - safeHorizontalPadding) * screenWidthFactor)
            .clamp(140.0, 520.0);
        final capFromConstraints = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final effectiveCap = maxWidth ?? math.min(capFromConstraints, fallback);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fgColor),
                const SizedBox(width: 6),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(
                    
                    
                    maxWidth: (effectiveCap - (icon != null ? 22 : 0))
                        .clamp(100.0, double.infinity)),
                child: Text(
                  text,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fgColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DatePill extends StatelessWidget {
  final DateTime? dueDate;
  const DatePill({super.key, required this.dueDate});

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final label =
        dueDate != null ? 'Vence: ${_fmtDate(dueDate!)}' : 'Sin fecha límite';
    return Pill(text: label, icon: Icons.schedule, gold: true);
  }
}



class SaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String label;
  final IconData icon;
  const SaveButton({
    super.key,
    this.onPressed,
    this.loading = false,
    this.label = 'GUARDAR',
    this.icon = Icons.save,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.goldAccent,
          foregroundColor: AppTheme.premiumBlack,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: loading ? null : onPressed,
        label: Text(loading ? '$label…' : label),
      ),
    );
  }
}


Iterable<Widget> _intersperse(List<Widget> items, Widget separator) sync* {
  for (var i = 0; i < items.length; i++) {
    yield items[i];
    if (i != items.length - 1) yield separator;
  }
}

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration duration;
  const FadeSlideIn(
      {super.key,
      required this.child,
      this.index = 0,
      this.baseDelay = const Duration(milliseconds: 40),
      this.duration = const Duration(milliseconds: 280)});
  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, .04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(widget.baseDelay * widget.index, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
