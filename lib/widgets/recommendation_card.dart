import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_colors.dart';
import '../models/recommendation_model.dart';

class RecommendationCard extends StatelessWidget {
  final RecommendationModel rec;
  final VoidCallback? onAdd;

  const RecommendationCard({super.key, required this.rec, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final b = rec.scoreBreakdown;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _art(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(rec.artist,
                          style: const TextStyle(
                              color: AppColors.onSurfaceMuted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      if (rec.spotifyTrackId.isNotEmpty)
                        _SpotifyLink(trackId: rec.spotifyTrackId),
                      const SizedBox(height: 4),
                      _ScoreBar(
                          label: 'Votes',
                          value: b.voteScore,
                          color: AppColors.upvote),
                      _ScoreBar(
                          label: 'History',
                          value: b.listeningScore,
                          color: AppColors.primary),
                      _ScoreBar(
                          label: 'Mood',
                          value: b.moodScore,
                          color: const Color(0xFFFFD54F)),
                    ],
                  ),
                ),
                if (onAdd != null)
                  IconButton(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.primary),
                    tooltip: 'Add to playlist',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rec.reason,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _art() {
    if (rec.albumImageUrl == null) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.music_note, color: AppColors.onSurfaceMuted),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: rec.albumImageUrl!,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) =>
            const Icon(Icons.broken_image, color: AppColors.onSurfaceMuted),
      ),
    );
  }
}

class _SpotifyLink extends StatelessWidget {
  final String trackId;
  const _SpotifyLink({required this.trackId});

  Future<void> _open() async {
    final uri = Uri.parse('https://open.spotify.com/track/$trackId');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_in_new, size: 12, color: AppColors.onSurfaceMuted),
          SizedBox(width: 4),
          Text(
            'Open in Spotify',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.onSurfaceMuted,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ScoreBar(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.onSurfaceMuted)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${(value * 100).toInt()}%',
            style: const TextStyle(fontSize: 9, color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}
