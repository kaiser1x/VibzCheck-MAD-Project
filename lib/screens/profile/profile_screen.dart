import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Display Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<AuthProvider>().updateDisplayName(name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final themeProv = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: themeProv.accent,
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: themeProv.accent.computeLuminance() > 0.179
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () =>
                            _showEditNameDialog(context, user.displayName),
                        child: const Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.onSurfaceMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                        color: AppColors.onSurfaceMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${user.listeningHistory.length} tracks in history',
                    style: const TextStyle(
                        color: AppColors.onSurfaceMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'App Color',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ThemeProvider.accents.map((a) {
                      final selected = themeProv.accent == a.color;
                      return GestureDetector(
                        onTap: () => themeProv.setAccent(a.color),
                        child: Tooltip(
                          message: a.name,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: a.color,
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(
                                      color: Colors.white, width: 3)
                                  : null,
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: a.color.withAlpha(120),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: selected
                                ? Icon(Icons.check,
                                    size: 20,
                                    color: a.color.computeLuminance() > 0.179
                                        ? Colors.black
                                        : Colors.white)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout_outlined,
                        color: AppColors.error),
                    title: const Text('Sign Out',
                        style: TextStyle(color: AppColors.error)),
                    onTap: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/');
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
