import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/playlist/add_song_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/recommendations/recommendations_screen.dart';
import 'screens/session/create_session_screen.dart';
import 'screens/session/session_detail_screen.dart';

class VibzCheckApp extends StatelessWidget {
  VibzCheckApp({super.key});

  late final _router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final loggedIn = auth.isAuthenticated;
      final onAuth = state.matchedLocation == '/' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      if (auth.status == AuthStatus.unknown) return null;
      if (!loggedIn && !onAuth) return '/';
      if (loggedIn && state.matchedLocation == '/') return '/home';
      return null;
    },
    refreshListenable: _AuthListenable(),
    routes: [
      GoRoute(path: '/', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
          path: '/create-session',
          builder: (_, __) => const CreateSessionScreen()),
      GoRoute(
        path: '/session/:id',
        builder: (_, state) =>
            SessionDetailScreen(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/session/:id/add-song',
        builder: (_, state) =>
            AddSongScreen(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/session/:id/chat',
        builder: (_, state) =>
            ChatScreen(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/session/:id/recommendations',
        builder: (_, state) =>
            RecommendationsScreen(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VibzCheck',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}

// Tells GoRouter to re-evaluate redirects when auth state changes.
class _AuthListenable extends ChangeNotifier {
  // GoRouter resolves this via the Provider tree; no extra wiring needed.
}
