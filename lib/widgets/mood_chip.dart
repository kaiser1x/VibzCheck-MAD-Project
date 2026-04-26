import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class MoodChip extends StatelessWidget {
  final String mood;
  final bool selected;
  final bool small;
  final VoidCallback? onTap;

  const MoodChip({
    super.key,
    required this.mood,
    this.selected = false,
    this.small = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.moodColor(mood);
    final label = mood[0].toUpperCase() + mood.substring(1);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 12,
          vertical: small ? 3 : 6,
        ),
        decoration: BoxDecoration(
          color: selected ? color : color.withAlpha(40),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withAlpha(100),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontSize: small ? 11 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
