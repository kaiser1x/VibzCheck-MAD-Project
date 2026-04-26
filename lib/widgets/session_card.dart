import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/session_model.dart';
import 'mood_chip.dart';

class SessionCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onTap;

  const SessionCard({super.key, required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.moodColor(session.currentMood.name)
                      .withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.headphones_rounded,
                  color: AppColors.moodColor(session.currentMood.name),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people_outline,
                            size: 14, color: AppColors.onSurfaceMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${session.activeUsers.length} listener${session.activeUsers.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.onSurfaceMuted),
                        ),
                        const SizedBox(width: 12),
                        MoodChip(mood: session.currentMood.name, small: true),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
            ],
          ),
        ),
      ),
    );
  }
}
