import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';
import 'custom_button.dart';
import 'app_snack_bar.dart';

/// Rating and Review Bottom Sheet for Completed Moves.
class RatingSheet extends StatefulWidget {
  const RatingSheet({
    super.key,
    required this.moveRef,
    required this.moveTitle,
  });

  final String moveRef;
  final String moveTitle;

  static void show(
    BuildContext context, {
    required String moveRef,
    required String moveTitle,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: RatingSheet(moveRef: moveRef, moveTitle: moveTitle),
      ),
    );
  }

  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<RatingSheet> {
  int _selectedStars = 5;
  final List<String> _tags = [
    'Punctual',
    'Careful Handling',
    'Polite Crew',
    'White-Glove',
    'Quick Delivery',
    'Clean Packing',
  ];
  final Set<String> _selectedTags = {'Careful Handling', 'White-Glove'};
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.2),
          left: BorderSide(color: AppColors.border, width: 1.2),
          right: BorderSide(color: AppColors.border, width: 1.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'RATE YOUR MOVE',
            style: AppTextStyles.overline,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            widget.moveTitle,
            style: AppTextStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),
          Text(
            widget.moveRef,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Star selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: () => setState(() => _selectedStars = star),
                icon: Icon(
                  star <= _selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColors.gold,
                  size: 38,
                ),
              );
            }),
          ),
          const SizedBox(height: 18),

          // Tag chips
          Text(
            'What went great?',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
                backgroundColor: AppColors.surfaceElevated,
                selectedColor: AppColors.gold.withValues(alpha: 0.2),
                checkmarkColor: AppColors.gold,
                side: BorderSide(
                  color: isSelected ? AppColors.gold : AppColors.border,
                ),
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? AppColors.goldLight : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Comment input
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Share a note about your experience...',
              hintStyle: AppTextStyles.hint,
              fillColor: AppColors.surfaceElevated,
            ),
          ),
          const SizedBox(height: 24),

          CustomButton(
            text: 'SUBMIT FEEDBACK',
            icon: Icons.check_circle_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              AppSnackBar.showSuccess(context, 'Thank you for your review!');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
