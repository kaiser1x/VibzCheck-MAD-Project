const functions = require('firebase-functions');
const admin     = require('firebase-admin');
const axios     = require('axios');
const cors      = require('cors')({ origin: true });

admin.initializeApp();

// ── Spotify token cache ───────────────────────────────────────────────────────
let _spotifyToken  = null;
let _tokenExpiry   = 0;

async function getSpotifyToken() {
  if (_spotifyToken && Date.now() < _tokenExpiry) return _spotifyToken;

  const clientId     = functions.config().spotify.client_id;
  const clientSecret = functions.config().spotify.client_secret;
  const creds        = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

  try {
    const res = await axios.post(
      'https://accounts.spotify.com/api/token',
      'grant_type=client_credentials',
      {
        headers: {
          Authorization:  `Basic ${creds}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      }
    );
    _spotifyToken = res.data.access_token;
    // Expire 60 s early to avoid edge-case expiry mid-request
    _tokenExpiry  = Date.now() + (res.data.expires_in - 60) * 1000;
    return _spotifyToken;
  } catch (err) {
    functions.logger.error('Spotify token error', err.message);
    return null;
  }
}

// ── Mood → Spotify audio feature targets ─────────────────────────────────────
const MOOD_FEATURES = {
  chill:    { energy: 0.30, valence: 0.50, danceability: 0.40 },
  hype:     { energy: 0.90, valence: 0.80, danceability: 0.85 },
  sad:      { energy: 0.25, valence: 0.15, danceability: 0.30 },
  focus:    { energy: 0.50, valence: 0.50, danceability: 0.35 },
  party:    { energy: 0.85, valence: 0.90, danceability: 0.90 },
  romantic: { energy: 0.35, valence: 0.65, danceability: 0.45 },
};

// ── spotifySearch ─────────────────────────────────────────────────────────────
// GET ?q=<query>
exports.spotifySearch = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'GET') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    const q = req.query.q;
    if (!q) return res.status(400).json({ error: 'Missing query param: q' });

    const token = await getSpotifyToken();
    if (!token) {
      return res.status(502).json({ error: 'Could not obtain Spotify token' });
    }

    try {
      const result = await axios.get('https://api.spotify.com/v1/search', {
        headers: { Authorization: `Bearer ${token}` },
        params:  { q, type: 'track', limit: 20 },
      });
      return res.json(result.data);
    } catch (err) {
      functions.logger.error('spotifySearch error', err.message);
      return res.status(502).json({ error: 'Spotify search failed' });
    }
  });
});

// ── spotifyRecommend ──────────────────────────────────────────────────────────
// GET ?mood=<mood>[&seed_tracks=id1,id2][&seed_artists=id1,id2]
exports.spotifyRecommend = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'GET') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    const { mood, seed_tracks, seed_artists } = req.query;
    if (!mood) {
      return res.status(400).json({ error: 'Missing query param: mood' });
    }

    const features = MOOD_FEATURES[mood.toLowerCase()];
    if (!features) {
      return res.status(400).json({
        error: `Unknown mood. Valid values: ${Object.keys(MOOD_FEATURES).join(', ')}`,
      });
    }

    const token = await getSpotifyToken();
    if (!token) {
      return res.status(502).json({ error: 'Could not obtain Spotify token' });
    }

    try {
      const params = {
        limit:               20,
        target_energy:       features.energy,
        target_valence:      features.valence,
        target_danceability: features.danceability,
      };

      if (seed_tracks)  params.seed_tracks  = seed_tracks;
      if (seed_artists) params.seed_artists = seed_artists;
      // Spotify requires at least one seed
      if (!seed_tracks && !seed_artists) params.seed_genres = 'pop';

      const result = await axios.get(
        'https://api.spotify.com/v1/recommendations',
        { headers: { Authorization: `Bearer ${token}` }, params }
      );
      return res.json(result.data);
    } catch (err) {
      functions.logger.error('spotifyRecommend error', err.message);
      return res.status(502).json({ error: 'Spotify recommendations failed' });
    }
  });
});
