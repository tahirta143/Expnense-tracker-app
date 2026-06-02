import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class AIInsightCard extends StatelessWidget {
  final String insights;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback? onClose;

  const AIInsightCard({
    super.key,
    required this.insights,
    required this.isLoading,
    required this.onRefresh,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'AI Financial Insights',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: sw * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (!isLoading)
                Row(
                  children: [
                    GestureDetector(
                      onTap: onRefresh,
                      child: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary, size: 18),
                    ),
                    if (onClose != null) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onClose,
                        child: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 18),
                      ),
                    ],
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Text(
              insights,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: sw * 0.035,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}
