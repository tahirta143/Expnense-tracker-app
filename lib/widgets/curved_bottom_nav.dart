import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class CurvedBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const CurvedBottomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final itemCount = items.length;

    // ── all sizing derived from sw ──────────────────────────────
    final barH        = sw * 0.175;
    final barPadH     = sw * 0.04;
    final barPadB     = sw * 0.03;
    final itemMargin  = sw * 0.018;
    final radius      = sw * 0.09;
    final iconSize    = sw * 0.050;
    final fontSize    = sw * 0.028;
    final gap         = sw * 0.010;

    // pill width = equal share of bar minus outer padding and inner margins
    final barWidth    = sw - barPadH * 2;
    final pillW       = (barWidth / itemCount) - itemMargin * 2;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(barPadH, 0, barPadH, barPadB),
        child: Container(
          height: barH,
          decoration: BoxDecoration(
            color: theme.appBarTheme.backgroundColor,
            borderRadius: BorderRadius.circular(sw * 0.1),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(itemCount, (i) {
              final selected = i == selectedIndex;
              final icon     = (items[i].icon as Icon).icon!;
              final label    = items[i].label ?? '';

              return Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    width: pillW,
                    margin: EdgeInsets.all(itemMargin),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primaryColor.withValues(alpha: 0.18)
                          : (isDark ? theme.cardColor.withValues(alpha: 0.6) : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(radius),
                      border: selected
                          ? Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        width: 1.5,
                      )
                          : null,
                    ),
                    child: SizedBox.expand(
                      child: selected
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // ✅ don't stretch
                        children: [
                          Icon(
                            icon,
                            color: AppTheme.primaryColor,
                            size: iconSize,
                          ),
                          SizedBox(width: gap),
                          Flexible(              // ✅ text shrinks if needed
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                          : Center(
                        child: Icon(
                          icon,
                          color: isDark ? theme.textTheme.bodySmall?.color : Colors.grey[500],
                          size: iconSize,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}