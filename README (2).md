# VibzCheck

A collaborative mood-based music session app — listen together, vote on tracks, chat in real time, and get AI-powered recommendations based on your group's vibe.

**Team**

| Name | Student ID |
|---|---|
| Quang Tran | 002853359 |
| Tu Nguyen | 002694789 |

---

## Features

| Feature | Description |
|---|---|
| **Mood Sessions** | Create or join a listening session tagged with a mood (chill / hype / sad / focus / party / romantic) |
| **Song Queue** | Search Spotify and add tracks to the session queue |
| **Live Voting** | Upvote / downvote songs; one vote per user per song enforced by Firestore doc IDs |
| **Group Chat** | Real-time in-session messaging streamed via Firestore |
| **Smart Recommendations** | Scored recommendations using vote weight, listening history, and mood-mapped Spotify audio features |
| **User Profiles** | Display name, avatar, listening history |
| **Share by ID** | Copy a session ID and share it so friends can join instantly |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter 3 (Dart) |
| Auth | Firebase Authentication — email / password |
| Database | Cloud Firestore |
| Storage | Firebase Storage (profile photos) |
| Backend | Firebase Cloud Functions (Node 18) |
| Music API | Spotify Web API — via Cloud Functions proxy |
| State | Provider + ChangeNotifier |
| Navigation | GoRouter with auth-aware redirect |

---

## Setup

### Prerequisites

- Flutter SDK ≥ 3.x (`flutter --version`)
- Node.js 18+ (`node --version`)
- Firebase CLI (`npm install -g firebase-tools`)
- A Firebase project (project number: `781738479375`)
- A Spotify Developer app — [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard)

### 1 — Clone & install Flutter deps

```bash
git clone <repo-url>
cd TeamVibzCheck
flutter pub get
```

### 2 — Connect to Firebase

```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

This generates `lib/config/firebase_options.dart` with your real API keys.

Also download `google-services.json` from Firebase Console → Project Settings → Your Android app and place it at `android/app/google-services.json`.

### 3 — Set Spotify credentials (server-side only)

```bash
firebase functions:config:set \
  spotify.client_id="YOUR_CLIENT_ID" \
  spotify.client_secret="YOUR_CLIENT_SECRET"
```

### 4 — Update Cloud Functions URL in the app

After deploying (step 5), update `lib/config/app_config.dart`:

```dart
static const String cloudFunctionsBaseUrl =
    'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net';
```

### 5 — Deploy Firebase

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

### 6 — Run the app

```bash
flutter run
```

---

## How to Demo Each Feature

| Feature | Steps |
|---|---|
| **Register** | Launch → tap "Sign Up" → fill name / email / password → auto-redirects to Home |
| **Login** | Launch → enter credentials → tap "Sign In" |
| **Create Session** | Home → ＋ New Session → enter name, pick mood → Create → lands on Session Detail |
| **Join by ID** | Home → "Join by Session ID" → paste session ID → Join |
| **Add Song** | Session Detail → Playlist tab → ＋ FAB → search for a song → tap ＋ |
| **Vote** | Session Detail → Playlist tab → tap ▲ / ▼ on any song card |
| **Change Mood** | Session Detail → mood icon in app bar → pick new mood |
| **Chat** | Session Detail → Chat tab → type message → send |
| **Recommendations** | Session Detail → For You tab → tap Refresh → scored cards appear |
| **Add Recommendation** | Tap ＋ on any recommendation card to add it to the session playlist |
| **Profile** | Home → person icon → view name, email, track count |
| **Sign Out** | Profile → Sign Out |

---

## Firestore Data Structure

```
users/{userId}
  displayName      : string
  email            : string
  photoUrl         : string?
  createdAt        : timestamp
  listeningHistory : string[]   // Spotify track IDs

sessions/{sessionId}
  name        : string
  hostId      : string
  currentMood : string          // chill | hype | sad | focus | party | romantic
  createdAt   : timestamp
  activeUsers : string[]        // uids of currently connected users

  songs/{songId}
    spotifyTrackId      : string
    title               : string
    artist              : string
    albumImageUrl       : string?
    previewUrl          : string?
    addedBy             : string   // uid
    voteCount           : number
    moodTags            : string[]
    createdAt           : timestamp
    recommendationScore : number

  votes/{userId}_{songId}        ← composite ID enforces one vote per user per song
    userId    : string
    songId    : string
    voteValue : number            // +1 or -1
    createdAt : timestamp

  messages/{messageId}
    userId      : string
    displayName : string
    photoUrl    : string?
    text        : string
    createdAt   : timestamp

recommendations/{recId}           ← top-level, written by RecommendationService
  sessionId      : string
  spotifyTrackId : string
  title          : string
  artist         : string
  albumImageUrl  : string?
  scoreBreakdown : { voteScore, listeningScore, moodScore, total }
  reason         : string
  createdAt      : timestamp
```

---

## Recommendation Scoring Formula

Recommendations are scored using three weighted signals:

```
total = (voteScore × 0.45) + (listeningScore × 0.35) + (moodScore × 0.20)
```

| Signal | Weight | Source |
|---|---|---|
| `voteScore` | 45 % | Normalised vote count relative to top song in session |
| `listeningScore` | 35 % | Whether the track / artist appears in the group's listening history |
| `moodScore` | 20 % | Whether the track's mood tags match the current session mood |

Spotify recommendations are fetched using mood-mapped audio feature targets:

| Mood | Energy | Valence | Danceability |
|---|---|---|---|
| chill | 0.30 | 0.50 | 0.40 |
| hype | 0.90 | 0.80 | 0.85 |
| sad | 0.25 | 0.15 | 0.30 |
| focus | 0.50 | 0.50 | 0.35 |
| party | 0.85 | 0.90 | 0.90 |
| romantic | 0.35 | 0.65 | 0.45 |

The top 10 scored recommendations are persisted to Firestore and displayed on the **For You** tab.
