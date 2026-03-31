import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_constants.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final key = categories[i];
          final isSelected = selected == key;
          final display = key == 'all'
              ? 'Tất cả'
              : AppConstants.getCategoryName(key);
          return ChoiceChip(
            label: Text(
              display,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(key),
            backgroundColor: AppColors.surfaceVariant,
            selectedColor: AppColors.primary,
            shape: const StadiumBorder(),
            elevation: isSelected ? 2 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}
