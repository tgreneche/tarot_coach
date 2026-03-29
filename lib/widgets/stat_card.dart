import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget carte de statistique -- compact pour \u00e9viter l'overflow.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final cardColor = color ?? t.gold;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: cardColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: t.bodyFont(
                      fontSize: 12,
                      color: t.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: t.titleFont(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: cardColor,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: t.bodyFont(
                  fontSize: 12,
                  color: t.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
