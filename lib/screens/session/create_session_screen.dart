import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/session_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/mood_chip.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _nameCtrl = TextEditingController();
  SessionMood _mood = SessionMood.chill;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final uid = context.read<AuthProvider>().user!.uid;
    await context.read<SessionProvider>().createSession(
          name: name,
          hostId: uid,
          mood: _mood,
        );
    if (!mounted) return;
    final session = context.read<SessionProvider>().current;
    if (session != null) {
      context.go('/session/${session.sessionId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('New Session')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Session Name',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Friday Night Vibes',
                prefixIcon: Icon(Icons.music_note_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 28),
            const Text('Starting Mood',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Sets the initial vibe for song recommendations',
                style:
                    TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SessionMood.values.map((m) {
                return MoodChip(
                  mood: m.name,
                  selected: _mood == m,
                  onTap: () => setState(() => _mood = m),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: prov.loading ? null : _create,
              child: prov.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Create Session'),
            ),
          ],
        ),
      ),
    );
  }
}
