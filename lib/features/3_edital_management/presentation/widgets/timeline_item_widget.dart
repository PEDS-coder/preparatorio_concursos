import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget que representa um item de linha do tempo
class TimelineItemWidget extends StatelessWidget {
  final String label;
  final String date;
  final bool isFirst;
  final bool isLast;

  const TimelineItemWidget({
    Key? key,
    required this.label,
    required this.date,
    this.isFirst = false,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
              ),
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: isLast ? 0 : 24),
            ],
          ),
        ),
      ],
    );
  }
}
