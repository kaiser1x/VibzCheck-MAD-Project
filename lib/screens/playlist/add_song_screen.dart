import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/song_provider.dart';
import '../../services/spotify_service.dart';
import '../../widgets/app_loading.dart';

class AddSongScreen extends StatefulWidget {
  final String sessionId;
  const AddSongScreen({super.key, required this.sessionId});

  @override
  State<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addTrack(SpotifyTrack track) async {
    final uid = context.read<AuthProvider>().user!.uid;
    await context.read<SongProvider>().addSong(
          sessionId: widget.sessionId,
          track: track,
          addedBy: uid,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${track.title}" to the playlist'),
        backgroundColor: AppColors.primary.withAlpha(200),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SongProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add a Song')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search for a song or artist…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<SongProvider>().clearSearch();
                        },
                      )
                    : null,
              ),
              onChanged: (q) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 800), () {
                  context.read<SongProvider>().searchSpotify(q);
                });
              },
            ),
          ),
          Expanded(
            child: prov.searching
                ? const AppLoading()
                : prov.searchResults.isEmpty
                    ? AppEmptyState(
                        message: _searchCtrl.text.isEmpty
                            ? 'Search for a song above'
                            : prov.error != null
                                ? 'Search failed — check your connection'
                                : 'No results found',
                        icon: _searchCtrl.text.isEmpty
                            ? Icons.search
                            : Icons.music_off_outlined,
                      )
                    : ListView.builder(
                        itemCount: prov.searchResults.length,
                        itemBuilder: (_, i) {
                          final t = prov.searchResults[i];
                          return _TrackTile(
                            track: t,
                            onAdd: prov.loading ? null : () => _addTrack(t),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final SpotifyTrack track;
  final VoidCallback? onAdd;

  const _TrackTile({required this.track, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: track.albumImageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                track.albumImageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image),
              ),
            )
          : Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.music_note,
                  color: AppColors.onSurfaceMuted),
            ),
      title: Text(track.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(track.artist,
          style:
              const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
        onPressed: onAdd,
      ),
    );
  }
}
