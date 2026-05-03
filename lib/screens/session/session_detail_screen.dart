import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/session_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/song_provider.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/mood_chip.dart';
import '../../widgets/song_card.dart';

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  int _tab = 0; // 0=playlist, 1=chat, 2=recommendations

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    context.read<SongProvider>().listenToSongs(widget.sessionId);
    // Ensure the user is listed as active in this session.
    context.read<SessionProvider>().joinSession(widget.sessionId, uid);
  }

  @override
  void dispose() {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    context.read<SessionProvider>().leaveSession(uid);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionProv = context.watch<SessionProvider>();
    final session = sessionProv.current;

    if (session == null) return const Scaffold(body: AppLoading());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(session.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            Text(
              '${session.activeUsers.length} listener${session.activeUsers.length == 1 ? '' : 's'}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.onSurfaceMuted),
            ),
          ],
        ),
        actions: [
          // Copy session ID for sharing
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Session ID',
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: widget.sessionId));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Session ID copied to clipboard')));
            },
          ),
          // Mood picker
          IconButton(
            icon: Icon(Icons.mood,
                color: AppColors.moodColor(session.currentMood.name)),
            tooltip: 'Change Mood',
            onPressed: () => _showMoodPicker(context, session),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: AppColors.surface,
            child: Row(
              children: [
                _TabItem(
                    label: 'Playlist',
                    icon: Icons.queue_music,
                    index: 0,
                    current: _tab,
                    onTap: (i) => setState(() => _tab = i)),
                _TabItem(
                    label: 'Chat',
                    icon: Icons.chat_bubble_outline,
                    index: 1,
                    current: _tab,
                    onTap: (i) => setState(() => _tab = i)),
                _TabItem(
                    label: 'For You',
                    icon: Icons.auto_awesome,
                    index: 2,
                    current: _tab,
                    onTap: (i) => setState(() => _tab = i)),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _PlaylistTab(sessionId: widget.sessionId),
                // Chat tab — pushes chat screen; resets after pop so
                // the user can re-enter by tapping the tab again.
                _LazyScreen(
                  active: _tab == 1,
                  navigate: () =>
                      context.push('/session/${widget.sessionId}/chat'),
                  onReturn: () => setState(() => _tab = 0),
                ),
                // Recommendations tab — same re-entrant pattern.
                _LazyScreen(
                  active: _tab == 2,
                  navigate: () => context
                      .push('/session/${widget.sessionId}/recommendations'),
                  onReturn: () => setState(() => _tab = 0),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              onPressed: () =>
                  context.push('/session/${widget.sessionId}/add-song'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showMoodPicker(BuildContext context, SessionModel session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Session Mood',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 4),
            const Text('Affects song recommendations for everyone',
                style: TextStyle(
                    color: AppColors.onSurfaceMuted, fontSize: 12)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: SessionMood.values
                  .map((m) => MoodChip(
                        mood: m.name,
                        selected: session.currentMood == m,
                        onTap: () {
                          Navigator.pop(context);
                          context
                              .read<SessionProvider>()
                              .updateMood(m);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PlaylistTab extends StatelessWidget {
  final String sessionId;
  const _PlaylistTab({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final songs = context.watch<SongProvider>().songs;
    if (songs.isEmpty) {
      return AppEmptyState(
        message: 'No songs yet.\nAdd the first track!',
        icon: Icons.music_off_outlined,
        actionLabel: 'Add Song',
        onAction: () => context.push('/session/$sessionId/add-song'),
      );
    }
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (_, i) =>
          SongCard(song: songs[i], sessionId: sessionId),
    );
  }
}

// Pushes a route when the tab becomes active. Resets after the user pops
// back so tapping the tab again re-opens the screen correctly.
class _LazyScreen extends StatefulWidget {
  final bool active;
  final Future<void> Function() navigate;
  final VoidCallback onReturn;
  const _LazyScreen({
    required this.active,
    required this.navigate,
    required this.onReturn,
  });

  @override
  State<_LazyScreen> createState() => _LazyScreenState();
}

class _LazyScreenState extends State<_LazyScreen> {
  bool _triggered = false;

  @override
  void didUpdateWidget(_LazyScreen old) {
    super.didUpdateWidget(old);
    if (widget.active && !_triggered) {
      _triggered = true;
      _go();
    }
  }

  Future<void> _go() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    await widget.navigate();
    if (mounted) {
      setState(() => _triggered = false);
      widget.onReturn();
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _TabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: active
                      ? AppColors.primary
                      : AppColors.onSurfaceMuted),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.normal,
                  color: active
                      ? AppColors.primary
                      : AppColors.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
