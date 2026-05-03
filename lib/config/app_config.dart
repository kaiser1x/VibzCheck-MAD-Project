/// Central runtime configuration for VibzCheck.
///
/// Spotify credentials live in Firebase Functions config (server-side only).
/// After deploying Cloud Functions, replace TODO_PROJECT_ID with your real
/// Firebase project ID (the string ID, not the numeric project number).
///
/// Deploy command:
///   firebase deploy --only functions
/// Then update [cloudFunctionsBaseUrl] and commit.
class AppConfig {
  AppConfig._();

  // Replace TODO_PROJECT_ID with your Firebase project ID,
  // e.g. 'vibzcheck-ab12c'
  static const String cloudFunctionsBaseUrl =
      'https://us-central1-TODO_PROJECT_ID.cloudfunctions.net';

  static const String spotifySearchEndpoint =
      '$cloudFunctionsBaseUrl/spotifySearch';

  static const String spotifyRecommendEndpoint =
      '$cloudFunctionsBaseUrl/spotifyRecommend';
}
