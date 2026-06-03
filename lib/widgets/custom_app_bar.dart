import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/app_theme.dart';
import '../providers/theme_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.onBackPressed,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode 
                ? Colors.black.withOpacity(0.3) 
                : Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showBackButton)
                GestureDetector(
                  onTap: onBackPressed ?? () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: () => themeProvider.toggleTheme(),
                  icon: Icon(
                    themeProvider.isDarkMode 
                        ? Icons.dark_mode_rounded 
                        : Icons.light_mode_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  tooltip: 'Toggle Theme',
                ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.appBarTheme.titleTextStyle,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actions ?? [],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
