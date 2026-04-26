import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/session_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SessionProvider>().listenToSessions();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sessions = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('VibzCheck 🎵'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting banner
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Hey, ${auth.user?.displayName ?? 'Listener'} 👋',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Join a session or create your own',
              style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          // Join by code
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              icon: const Icon(Icons.qr_code_scanner_outlined),
              label: const Text('Join by Session ID'),
              onPressed: () => _showJoinDialog(context),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Active Sessions',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: sessions.loading
                ? const AppLoading()
                : sessions.sessions.isEmpty
                    ? AppEmptyState(
                        message: 'No sessions yet.\nBe the first to start one!',
                        icon: Icons.headphones_outlined,
                        actionLabel: 'Create Session',
                        onAction: () => context.push('/create-session'),
                      )
                    : ListView.builder(
                        itemCount: sessions.sessions.length,
                        itemBuilder: (_, i) {
                          final s = sessions.sessions[i];
                          return SessionCard(
                            session: s,
                            onTap: () {
                              context
                                  .read<SessionProvider>()
                                  .setCurrentSession(s);
                              context.push('/session/${s.sessionId}');
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-session'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Session',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Join Session'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Paste Session ID'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = ctrl.text.trim();
              Navigator.pop(context);
              if (id.isEmpty) return;
              final uid = context.read<AuthProvider>().user?.uid ?? '';
              final ok = await context
                  .read<SessionProvider>()
                  .joinSession(id, uid);
              if (context.mounted && ok) {
                context.push('/session/$id');
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.read<SessionProvider>().error ??
                        'Could not join session'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
