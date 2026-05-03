import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/recommendation_model.dart';
import '../../models/session_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/song_provider.dart';
import '../../services/spotify_service.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/recommendation_card.dart';

class RecommendationsScreen extends StatefulWidget {
  final String sessionId;
  const RecommendationsScreen({super.key, required this.sessionId});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RecommendationProvider>().listenToRecommendations(
          widget.sessionId,
        );
  }

  Future<void> _refresh() async {
    final session = context.read<SessionProvider>().current;
    if (session == null) return;

    final songs = context.read<SongProvider>().songs;
    // Use songs already in the session as a proxy for group listening history.
    final history = songs.map((s) => s.spotifyTrackId).toList();

    await context.read<RecommendationProvider>().refresh(
          sessionId: widget.sessionId,
          currentMood: session.currentMood,
          sessionSongs: songs,
          groupHistory: history,
        );
  }

  SpotifyTrack _recToTrack(RecommendationModel rec) => SpotifyTrack(
        trackId: rec.spotifyTrackId,
        title: rec.title,
        artist: rec.artist,
        albumImageUrl: rec.albumImageUrl,
      );

  @override
  Widget build(BuildContext context) {
    final recProv = context.watch<RecommendationProvider>();
    final session = context.watch<SessionProvider>().current;
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('For You'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: recProv.loading ? null : _refresh,
            tooltip: 'Refresh recommendations',
          ),
        ],
      ),
      body: Column(
        children: [
          if (session != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.moodColor(session.currentMood.name)
                    .withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.moodColor(session.currentMood.name)
                      .withAlpha(80),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 16,
                      color: AppColors.moodColor(session.currentMood.name)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recommending for ${session.currentMood.label} mood · '
                      '${context.read<SongProvider>().songs.length} session songs',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.moodColor(session.currentMood.name),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: recProv.loading
                ? const AppLoading()
                : recProv.error != null
                    ? AppErrorWidget(
                        message: recProv.error!,
                        onRetry: _refresh,
                      )
                    : recProv.recommendations.isEmpty
                    ? AppEmptyState(
                        message:
                            'No recommendations yet.\nTap refresh to generate some!',
                        icon: Icons.auto_awesome_outlined,
                        actionLabel: 'Generate',
                        onAction: _refresh,
                      )
                    : ListView.builder(
                        itemCount: recProv.recommendations.length,
                        itemBuilder: (_, i) {
                          final rec = recProv.recommendations[i];
                          return RecommendationCard(
                            rec: rec,
                            onAdd: () {
                              context.read<SongProvider>().addSong(
                                    sessionId: widget.sessionId,
                                    track: _recToTrack(rec),
                                    addedBy: uid,
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Added "${rec.title}" to playlist'),
                                  backgroundColor:
                                      AppColors.primary.withAlpha(200),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
