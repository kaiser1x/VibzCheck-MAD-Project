import json
import os
import time
import base64

import requests
from firebase_admin import initialize_app
from firebase_functions import https_fn
from firebase_functions.options import set_global_options

set_global_options(max_instances=10)
initialize_app()

_MOOD_PARAMS: dict[str, dict] = {
    "chill":    {"target_valence": 0.5, "target_energy": 0.3, "target_acousticness": 0.6},
    "hype":     {"target_valence": 0.7, "target_energy": 0.95, "target_danceability": 0.8},
    "sad":      {"target_valence": 0.2, "target_energy": 0.3, "target_acousticness": 0.7},
    "focus":    {"target_valence": 0.4, "target_energy": 0.4, "target_instrumentalness": 0.5},
    "party":    {"target_valence": 0.9, "target_energy": 0.9, "target_danceability": 0.9},
    "romantic": {"target_valence": 0.7, "target_energy": 0.4, "target_acousticness": 0.5},
}

_token_cache: dict = {}


def _get_access_token() -> str:
    """Returns a cached Spotify client-credentials token, refreshing when expired."""
    now = time.time()
    if _token_cache.get("expires_at", 0) > now + 60:
        return _token_cache["access_token"]

    client_id = os.environ["SPOTIFY_CLIENT_ID"]
    client_secret = os.environ["SPOTIFY_CLIENT_SECRET"]
    b64 = base64.b64encode(f"{client_id}:{client_secret}".encode()).decode()

    resp = requests.post(
        "https://accounts.spotify.com/api/token",
        data={"grant_type": "client_credentials"},
        headers={"Authorization": f"Basic {b64}"},
        timeout=10,
    )
    resp.raise_for_status()
    data = resp.json()
    _token_cache["access_token"] = data["access_token"]
    _token_cache["expires_at"] = now + data["expires_in"]
    return _token_cache["access_token"]


def _json_response(payload: dict, status: int = 200) -> https_fn.Response:
    return https_fn.Response(
        json.dumps(payload),
        status=status,
        headers={
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
    )


@https_fn.on_request()
def spotifySearch(req: https_fn.Request) -> https_fn.Response:
    if req.method == "OPTIONS":
        return https_fn.Response(
            "", status=204,
            headers={"Access-Control-Allow-Origin": "*",
                     "Access-Control-Allow-Methods": "GET",
                     "Access-Control-Allow-Headers": "Content-Type"},
        )

    query = req.args.get("q", "").strip()
    if not query:
        return _json_response({"error": "missing q parameter"}, 400)

    try:
        token = _get_access_token()
        resp = requests.get(
            "https://api.spotify.com/v1/search",
            params={"q": query, "type": "track"},
            headers={"Authorization": f"Bearer {token}"},
            timeout=10,
        )
        if resp.status_code != 200:
            return _json_response({"error": resp.status_code, "details": resp.text, "token_len": len(token)}, 500)
        return _json_response(resp.json())
    except Exception as e:
        return _json_response({"error": str(e)}, 500)


@https_fn.on_request()
def spotifyRecommend(req: https_fn.Request) -> https_fn.Response:
    if req.method == "OPTIONS":
        return https_fn.Response(
            "", status=204,
            headers={"Access-Control-Allow-Origin": "*",
                     "Access-Control-Allow-Methods": "GET",
                     "Access-Control-Allow-Headers": "Content-Type"},
        )

    mood = req.args.get("mood", "chill").lower()
    seed_tracks = req.args.get("seed_tracks", "")

    query = _mood_to_search_query(mood)

    # If the session has real tracks, pull the first seed artist name and mix it in.
    if seed_tracks:
        track_ids = [t for t in seed_tracks.split(",") if t][:2]
        try:
            token = _get_access_token()
            tr = requests.get(
                "https://api.spotify.com/v1/tracks",
                params={"ids": ",".join(track_ids)},
                headers={"Authorization": f"Bearer {token}"},
                timeout=10,
            )
            if tr.status_code == 200:
                artists = [
                    t["artists"][0]["name"]
                    for t in tr.json().get("tracks", [])
                    if t and t.get("artists")
                ]
                if artists:
                    query = f"{artists[0]} {query}"
        except Exception:
            pass

    try:
        token = _get_access_token()
        resp = requests.get(
            "https://api.spotify.com/v1/search",
            params={"q": query, "type": "track"},
            headers={"Authorization": f"Bearer {token}"},
            timeout=10,
        )
        if resp.status_code != 200:
            return _json_response({"error": f"Spotify {resp.status_code}: {resp.text}"}, 500)
        # Normalise to {"tracks": [...]} so the Flutter client stays unchanged.
        items = resp.json().get("tracks", {}).get("items", [])
        return _json_response({"tracks": items})
    except Exception as e:
        return _json_response({"error": str(e)}, 500)


def _mood_to_search_query(mood: str) -> str:
    mapping = {
        "chill":    "lofi chill beats",
        "hype":     "hip hop bangers",
        "sad":      "sad songs acoustic",
        "focus":    "lofi study music",
        "party":    "top dance hits",
        "romantic": "love songs soul",
    }
    return mapping.get(mood, "top hits")
