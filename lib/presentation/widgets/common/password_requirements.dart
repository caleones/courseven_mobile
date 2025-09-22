import 'package:flutter/material.dart';
import '../../../presentation/theme/app_theme.dart';

class PasswordRequirements extends StatelessWidget {
  final String password;
  final EdgeInsetsGeometry padding;

  const PasswordRequirements({
    super.key,
    required this.password,
    this.padding = const EdgeInsets.only(top: 8),
  });

  bool get hasUpper => RegExp(r'[A-Z]').hasMatch(password);
  bool get hasLower => RegExp(r'[a-z]').hasMatch(password);
  bool get hasDigit => RegExp(r'\d').hasMatch(password);
  bool get hasSpecial => RegExp(r'[^A-Za-z0-9]').hasMatch(password);

  @override
  Widget build(BuildContext context) {
    final items = [
      _ReqItem('Una mayúscula (A-Z)', hasUpper),
      _ReqItem('Una minúscula (a-z)', hasLower),
      _ReqItem('Un número (0-9)', hasDigit),
      _ReqItem('Un símbolo (!@#...)', hasSpecial),
    ];

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((e) => _buildRow(context, e.label, e.met))
            .toList(growable: false),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, bool met) {
    final color = met
        ? Colors.green
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    final icon = met ? Icons.check_circle : Icons.radio_button_unchecked;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: met ? Colors.green : AppTheme.goldAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReqItem {
  final String label;
  final bool met;
  _ReqItem(this.label, this.met);
}
