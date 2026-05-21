import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../themes/app_theme.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final int index; // Added index for staggered animation

  const ExpenseCard({
    Key? key,
    required this.expense,
    this.onTap,
    this.onDelete,
    this.index = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    // Scale icon box and fonts relative to screen width
    final iconSize = sw * 0.13;
    final titleFontSize = sw * 0.038;
    final subFontSize = sw * 0.030;
    final amountFontSize = sw * 0.036;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 400)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(
              horizontal: sw * 0.04, vertical: sw * 0.018),
          padding: EdgeInsets.all(sw * 0.035),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon box
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: AppTheme.getCategoryColor(expense.category)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    expense.icon ?? Expense.getCategoryIcon(expense.category),
                    style: TextStyle(fontSize: iconSize * 0.48),
                  ),
                ),
              ),
              SizedBox(width: sw * 0.03),

              // Title + category + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: sw * 0.01),
                    // Category chip + date — use Flexible so they never overflow
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: sw * 0.02,
                              vertical: sw * 0.008,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.getCategoryColor(expense.category)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              expense.category,
                              style: TextStyle(
                                color: AppTheme.getCategoryColor(
                                    expense.category),
                                fontSize: subFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(width: sw * 0.02),
                        Text(
                          expense.formattedDate,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: subFontSize,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: sw * 0.02),

              // Amount + delete
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    expense.formattedAmount,
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: amountFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                  if (onDelete != null)
                    Padding(
                      padding: EdgeInsets.only(top: sw * 0.01),
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          Icons.close,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                          size: sw * 0.045,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
