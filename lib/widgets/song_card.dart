import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_colors.dart';
import '../models/song_model.dart';
import '../models/vote_model.dart';
import '../providers/auth_provider.dart';
import '../providers/song_provider.dart';
import 'mood_chip.dart';

class SongCard extends StatelessWidget {
  final SongModel song;
  final String sessionId;

  const SongCard({super.key, required this.song, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final songProv = context.watch<SongProvider>();
    final myVote = songProv.userVotes[song.songId];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _AlbumArt(url: song.albumImageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: const TextStyle(
                        color: AppColors.onSurfaceMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (song.moodTags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: song.moodTags
                          .map((t) => MoodChip(mood: t, small: true))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 4),
                  // Opens preview if available, otherwise opens full track on Spotify.
                  _SpotifyLink(
                    previewUrl: song.previewUrl,
                    trackId: song.spotifyTrackId,
                  ),
                ],
              ),
            ),
            _VoteButtons(
              song: song,
              sessionId: sessionId,
              userId: auth.user?.uid ?? '',
              myVote: myVote,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  final String? url;
  const _AlbumArt({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note, color: AppColors.onSurfaceMuted),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 52,
          height: 52,
          color: AppColors.surfaceVariant,
        ),
        errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
      ),
    );
  }
}

class _VoteButtons extends StatelessWidget {
  final SongModel song;
  final String sessionId;
  final String userId;
  final VoteModel? myVote;

  const _VoteButtons({
    required this.song,
    required this.sessionId,
    required this.userId,
    required this.myVote,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.read<SongProvider>();
    final upActive = myVote?.voteValue == 1;
    final downActive = myVote?.voteValue == -1;

    return Column(
      children: [
        IconButton(
          onPressed: () => prov.vote(
            sessionId: sessionId,
            songId: song.songId,
            userId: userId,
            value: 1,
          ),
          icon: Icon(
            Icons.arrow_upward_rounded,
            color: upActive ? AppColors.upvote : AppColors.onSurfaceMuted,
          ),
          visualDensity: VisualDensity.compact,
        ),
        Text(
          '${song.voteCount}',
          style: TextStyle(
            color: song.voteCount > 0
                ? AppColors.upvote
                : song.voteCount < 0
                    ? AppColors.downvote
                    : AppColors.onSurfaceMuted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        IconButton(
          onPressed: () => prov.vote(
            sessionId: sessionId,
            songId: song.songId,
            userId: userId,
            value: -1,
          ),
          icon: Icon(
            Icons.arrow_downward_rounded,
            color: downActive ? AppColors.downvote : AppColors.onSurfaceMuted,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _SpotifyLink extends StatelessWidget {
  final String? previewUrl;
  final String trackId;

  const _SpotifyLink({this.previewUrl, required this.trackId});

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
