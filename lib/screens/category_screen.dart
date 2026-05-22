import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import '../themes/app_theme.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  // Emoji options for picking a category icon
  static const _emojis = [
    '🍔', '🚗', '🎬', '💡', '🛍️', '🏥', '📚', '📌',
    '✈️', '🏠', '💊', '🎮', '☕', '🐾', '💇', '🎁',
    '🏋️', '📱', '🎵', '🍕', '🚀', '💼', '🌿', '🧾',
  ];

  static const _colors = [
    0xFFFF6B6B, 0xFF4ECDC4, 0xFFFFE66D, 0xFFA8E6CF,
    0xFFFF8B94, 0xFFC7CEEA, 0xFFB5EAD7, 0xFFF7DC6F,
    0xFF00D084, 0xFFFFB84D, 0xFF90EE90, 0xFF87CEEB,
  ];

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        final categories = provider.categories;
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) =>
              Opacity(opacity: value, child: child!),
          child: Column(
            children: [
            // Add button row
            Padding(
              padding: EdgeInsets.fromLTRB(
                  sw * 0.04, sw * 0.03, sw * 0.04, sw * 0.02),
              child: SizedBox(
                width: double.infinity,
                height: sw * 0.12,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddSheet(context, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Add Category',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            // Category list
            Expanded(
              child: categories.isEmpty
                  ? const Center(
                      child: Text('No categories yet',
                          style: TextStyle(color: AppTheme.textPrimary)),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                          sw * 0.04, 0, sw * 0.04, 110),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 400 + (index * 50)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(sw * 0.1 * (1 - value), 0),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: sw * 0.025),
                            padding: EdgeInsets.symmetric(
                                horizontal: sw * 0.035,
                                vertical: sw * 0.03),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: AppTheme.borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: sw * 0.11,
                                  height: sw * 0.11,
                                  decoration: BoxDecoration(
                                    color: Color(cat.color)
                                        .withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(cat.icon,
                                        style: TextStyle(
                                            fontSize: sw * 0.05)),
                                  ),
                                ),
                                SizedBox(width: sw * 0.035),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: sw * 0.038,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _confirmDelete(
                                      context, provider, cat.name),
                                  child: Icon(Icons.delete_outline,
                                      color: AppTheme.errorColor,
                                      size: sw * 0.05),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, CategoryProvider provider, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Category',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Delete "$name"?',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteCategory(name);
              Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, CategoryProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCategorySheet(provider: provider),
    );
  }
}

// ─── Add Category Sheet ───────────────────────────────────────────────────────

class _AddCategorySheet extends StatefulWidget {
  final CategoryProvider provider;
  const _AddCategorySheet({required this.provider});

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _nameController = TextEditingController();
  String _selectedEmoji = CategoryScreen._emojis.first;
  int _selectedColor = CategoryScreen._colors.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a category name'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    if (widget.provider.exists(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category already exists'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    widget.provider.addCategory(ExpenseCategory(
      name: name,
      icon: _selectedEmoji,
      color: _selectedColor,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Category',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.borderColor, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name field
                    const Text('Category Name *',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g., Gym, Rent',
                        hintStyle:
                            const TextStyle(color: AppTheme.textSecondary),
                        prefixIcon: const Icon(Icons.label_outline,
                            color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Emoji picker
                    const Text('Icon',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CategoryScreen._emojis.map((emoji) {
                        final selected = emoji == _selectedEmoji;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedEmoji = emoji),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                  : AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.primaryColor
                                    : AppTheme.borderColor,
                              ),
                            ),
                            child: Center(
                                child: Text(emoji,
                                    style: const TextStyle(fontSize: 18))),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Color picker
                    const Text('Color',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CategoryScreen._colors.map((colorVal) {
                        final selected = colorVal == _selectedColor;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedColor = colorVal),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(colorVal),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Add Category',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
