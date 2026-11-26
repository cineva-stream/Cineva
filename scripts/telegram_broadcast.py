#!/usr/bin/env python3
"""
Cineva Automated Telegram Channel Broadcast Engine (English Edition).
Official Channel: https://t.me/cineva_platform (@cineva_platform)

Features:
1. New Release Broadcast (--mode releases):
   - Discovers newly released & trending Movies, TV Series, Anime, and K-Drama from TMDB (en-US).
   - Verifies stream availability on VixSrc / Cineva Scraper API before posting so
     unreleased ("Coming Soon") items are never broadcasted prematurely.
   - Sends a rich English poster card to Telegram with an interactive "🎬 Watch on Cineva"
     inline button that deep-links directly into the Cineva Android app.
2. App Update / New Feature Broadcast (--mode app-update):
   - Automatically broadcasts new Cineva GitHub Releases (version, changelog, features)
     in English with direct APK download and "Watch on Cineva" action buttons.
3. Single / Test Broadcast (--mode test or --tmdb-id <ID> --media-type movie|tv):
   - Sends a test post immediately to verify Telegram Bot Token & Channel configuration.

Zero Hardcoded Secrets Policy:
All credentials are read from environment variables or local `.env` (gitignored):
  - TELEGRAM_BOT_TOKEN
  - TELEGRAM_CHAT_ID (defaults to "@cineva_platform")
  - TMDB_API_KEY or TMDB_ACCESS_TOKEN
"""

from __future__ import annotations

import argparse
import datetime as dt
import html
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

TMDB_BASE_URL = "https://api.themoviedb.org/3"
TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p/w780"
CINEVA_DEEP_LINK_BASE = "https://cineva-stream.github.io"
CINEVA_RELEASES_URL = "https://github.com/cineva-stream/Cineva/releases/latest"
DEFAULT_TELEGRAM_CHANNEL = "@cineva_platform"
DEFAULT_CACHE_PATH = Path(".telegram_posted_cache.json")

GENRE_MAP_EN: dict[int, str] = {
    28: "Action",
    12: "Adventure",
    16: "Animation",
    35: "Comedy",
    80: "Crime",
    99: "Documentary",
    18: "Drama",
    10751: "Family",
    14: "Fantasy",
    36: "History",
    27: "Horror",
    10402: "Music",
    9648: "Mystery",
    10749: "Romance",
    878: "Sci-Fi",
    10770: "TV Movie",
    53: "Thriller",
    10752: "War",
    37: "Western",
    10759: "Action & Adventure",
    10762: "Kids",
    10763: "News",
    10764: "Reality",
    10765: "Sci-Fi & Fantasy",
    10766: "Soap",
    10767: "Talk",
    10768: "War & Politics",
}


def load_local_env() -> dict[str, str]:
    """Loads key=value pairs from untracked local `.env` or `android/key.properties`."""
    props: dict[str, str] = {}
    for rel in (".env", "android/key.properties", "android/local.properties"):
        path = Path(rel)
        if not path.is_file():
            continue
        try:
            for raw_line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
                line = raw_line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                k = k.strip()
                v = v.strip().strip('"').strip("'")
                if k and v and k not in props:
                    props[k] = v
        except OSError:
            pass
    return props


def get_config(key: str, local_env: dict[str, str], default: str = "") -> str:
    val = os.environ.get(key, "").strip()
    if val:
        return val
    return local_env.get(key, default).strip()


def normalize_chat_id(raw_chat_id: str) -> str:
    """Normalizes t.me links or plain channel usernames into @username format."""
    cleaned = raw_chat_id.strip()
    if not cleaned:
        return DEFAULT_TELEGRAM_CHANNEL
    for prefix in ("https://t.me/", "http://t.me/", "t.me/"):
        if cleaned.lower().startswith(prefix):
            cleaned = cleaned[len(prefix):].strip("/")
            break
    if not cleaned.startswith("@") and not cleaned.lstrip("-").isdigit():
        cleaned = f"@{cleaned}"
    return cleaned


def http_get_json(
    url: str,
    headers: dict[str, str] | None = None,
    timeout: int = 15,
) -> dict[str, Any] | None:
    req_headers = {
        "User-Agent": "CinevaTelegramBot/1.0 (+https://github.com/cineva-stream/Cineva)",
        "Accept": "application/json",
    }
    if headers:
        req_headers.update(headers)
    req = urllib.request.Request(url, headers=req_headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            if 200 <= resp.status < 300:
                return json.loads(resp.read().decode("utf-8", errors="replace"))
    except Exception as exc:
        print(f"[WARN] GET {url} failed: {exc}", file=sys.stderr)
    return None


def is_stream_available(
    tmdb_id: int,
    media_type: str,
    details: dict[str, Any],
    scraper_base_url: str = "",
) -> bool:
    """
    Verifies that a Movie or TV episode is released and available to stream on Cineva
    (matching MediaReleaseGuard + VixSrc + /api/v2/stream-movie & /api/v2/stream-tv)
    so unreleased ("Coming Soon") items are never broadcasted prematurely.
    """
    if tmdb_id <= 0:
        return False

    unreleased_statuses = {
        "rumored",
        "planned",
        "in production",
        "post production",
        "upcoming",
    }
    status = str(details.get("status") or "").strip().lower()
    if status in unreleased_statuses:
        return False

    # 1. Check Direct VixSrc
    vix_url = (
        f"https://vixsrc.to/movie/{tmdb_id}"
        if media_type == "movie"
        else f"https://vixsrc.to/tv/{tmdb_id}/1/1"
    )
    req = urllib.request.Request(
        vix_url,
        headers={
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36"
            ),
            "Referer": "https://vixsrc.to/",
        },
        method="GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            if resp.status == 200:
                body = resp.read(32768).decode("utf-8", errors="ignore")
                if "/playlist/" in body or "masterPlaylist" in body or "video" in body.lower():
                    return True
    except Exception:
        pass

    # 2. Check Cineva Scraper Cluster (/api/v2/stream-movie or /api/v2/stream-tv)
    if scraper_base_url:
        base = scraper_base_url.rstrip("/")
        root = base if base.endswith("/api/v2") else f"{base}/api/v2"
        for provider in ("movy", "vidup"):
            if media_type == "movie":
                url = f"{root}/stream-movie?provider={provider}&tmdbId={tmdb_id}"
            else:
                url = f"{root}/stream-tv?provider={provider}&tmdbId={tmdb_id}&season=1&episode=1"
            data = http_get_json(url, timeout=10)
            if isinstance(data, dict) and data.get("success") is True:
                return True

    # 3. Fallback when running in CI without private scraper URL configured:
    # allow officially released titles whose release date is in the past and vote_count >= 5
    if not scraper_base_url:
        rel_date_str = (details.get("release_date") or details.get("first_air_date") or "").strip()
        vote_count = int(details.get("vote_count") or 0)
        if len(rel_date_str) >= 10 and vote_count >= 5:
            try:
                rel_date = dt.date.fromisoformat(rel_date_str[:10])
                if rel_date <= dt.datetime.now(dt.timezone.utc).date():
                    return True
            except ValueError:
                pass

    return False


def build_watch_on_cineva_url(
    tmdb_id: int,
    media_type: str,
    title: str = "",
    details: dict[str, Any] | None = None,
) -> str:
    """
    Constructs the HTTPS App Link URL for the Telegram inline button.
    Clicking this button in Telegram on Android opens the Cineva app directly
    to MovieDetailScreen (/movie/:id) or TvDetailScreen (/tv/:id), and passes
    lightweight metadata query params for the web fallback card if the app is not installed.
    """
    clean_type = "tv" if media_type == "tv" else "movie"
    base_url = f"{CINEVA_DEEP_LINK_BASE}/{clean_type}/{tmdb_id}"
    q: dict[str, str] = {}
    if title:
        q["title"] = title[:60]
    if details:
        rel_date = str(details.get("release_date") or details.get("first_air_date") or "").strip()
        if len(rel_date) >= 4:
            q["year"] = rel_date[:4]
        vote = float(details.get("vote_average") or 0.0)
        if vote > 0:
            q["rating"] = f"{vote:.1f}"
        poster = str(details.get("poster_path") or "").strip()
        if poster.startswith("/"):
            q["poster"] = poster
        overview = str(details.get("overview") or "").strip()
        if overview:
            if len(overview) > 210:
                overview = overview[:207].rstrip() + "..."
            q["overview"] = overview
    if q:
        return f"{base_url}?{urllib.parse.urlencode(q)}"
    return base_url


def tmdb_request(
    endpoint: str,
    params: dict[str, Any],
    api_key: str,
    access_token: str,
) -> dict[str, Any] | None:
    query_params = dict(params)
    headers: dict[str, str] = {}
    if access_token:
        headers["Authorization"] = f"Bearer {access_token}"
    elif api_key:
        query_params["api_key"] = api_key
    else:
        raise RuntimeError(
            "Missing TMDB_API_KEY or TMDB_ACCESS_TOKEN. "
            "Set it in your environment variables, GitHub Secrets, or local .env file."
        )
    qs = urllib.parse.urlencode(query_params)
    url = f"{TMDB_BASE_URL}{endpoint}?{qs}"
    return http_get_json(url, headers=headers)


def classify_category_badge(item: dict[str, Any], media_type: str) -> str:
    origin_countries = [c.upper() for c in (item.get("origin_country") or [])]
    orig_lang = (item.get("original_language") or "").lower()
    genre_ids = set(item.get("genre_ids") or [g.get("id") for g in (item.get("genres") or [])])

    if 16 in genre_ids and (orig_lang == "ja" or "JP" in origin_countries):
        return "NEW ANIME"
    if orig_lang == "ko" or "KR" in origin_countries:
        return "NEW K-DRAMA" if media_type == "tv" else "NEW KOREAN MOVIE"
    if orig_lang == "id" or "ID" in origin_countries:
        return "NEW INDONESIAN RELEASE"
    if orig_lang == "hi" or "IN" in origin_countries:
        return "NEW BOLLYWOOD RELEASE"
    return "NEW MOVIE" if media_type == "movie" else "NEW TV SERIES"


def format_media_caption(item: dict[str, Any], media_type: str) -> str:
    title = (
        item.get("title")
        or item.get("name")
        or item.get("original_title")
        or item.get("original_name")
        or "Untitled"
    )
    release_date = (item.get("release_date") or item.get("first_air_date") or "").strip()
    year = release_date[:4] if len(release_date) >= 4 else "N/A"
    vote = float(item.get("vote_average") or 0.0)
    rating_str = f"{vote:.1f}/10" if vote > 0 else "New"

    raw_genre_ids = item.get("genre_ids") or [
        g.get("id") for g in (item.get("genres") or []) if isinstance(g, dict)
    ]
    genre_names = [GENRE_MAP_EN[gid] for gid in raw_genre_ids if gid in GENRE_MAP_EN][:3]
    genre_str = ", ".join(genre_names) if genre_names else ("Movie" if media_type == "movie" else "TV Series")

    overview = (item.get("overview") or "").strip()
    if not overview:
        overview = (
            f"Stream {title} ({year}) in Full HD with multi-language subtitles, "
            f"completely free and ad-free on Cineva Stream."
        )
    if len(overview) > 340:
        overview = overview[:337].rstrip() + "..."

    badge = classify_category_badge(item, media_type)
    esc_title = html.escape(title)
    esc_genre = html.escape(genre_str)
    esc_overview = html.escape(overview)

    lines = [
        f"<b>{badge}</b>",
        "",
        f"<b>{esc_title} ({html.escape(year)})</b>",
        f"Rating: {rating_str}  •  {esc_genre}",
        "",
        f"<blockquote>{esc_overview}</blockquote>",
        "",
        "<i>Available now on Cineva Stream.</i>",
    ]
    return "\n".join(lines)


def send_telegram_post(
    bot_token: str,
    chat_id: str,
    caption_html: str,
    reply_markup: dict[str, Any],
    photo_url: str | None = None,
    dry_run: bool = False,
) -> bool:
    if dry_run:
        print("=== [DRY RUN] Telegram Post Payload ===")
        print(f"Chat ID : {chat_id}")
        print(f"Photo   : {photo_url}")
        print(f"Caption :\n{caption_html}\n")
        print(f"Buttons : {json.dumps(reply_markup, ensure_ascii=False, indent=2)}")
        return True

    if photo_url:
        endpoint = f"https://api.telegram.org/bot{bot_token}/sendPhoto"
        payload: dict[str, Any] = {
            "chat_id": chat_id,
            "photo": photo_url,
            "caption": caption_html,
            "parse_mode": "HTML",
            "reply_markup": reply_markup,
        }
    else:
        endpoint = f"https://api.telegram.org/bot{bot_token}/sendMessage"
        payload = {
            "chat_id": chat_id,
            "text": caption_html,
            "parse_mode": "HTML",
            "disable_web_page_preview": False,
            "reply_markup": reply_markup,
        }

    data_bytes = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        endpoint,
        data=data_bytes,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            resp_data = json.loads(resp.read().decode("utf-8", errors="replace"))
            if resp_data.get("ok"):
                msg_id = resp_data.get("result", {}).get("message_id")
                print(f"[OK] Broadcast sent to {chat_id} (message_id={msg_id})")
                return True
            print(f"[ERROR] Telegram API returned ok=false: {resp_data}", file=sys.stderr)
            return False
    except urllib.error.HTTPError as err:
        err_body = err.read().decode("utf-8", errors="replace")
        print(f"[ERROR] Telegram HTTP {err.code}: {err_body}", file=sys.stderr)
        return False
    except Exception as exc:
        print(f"[ERROR] Failed to send Telegram post: {exc}", file=sys.stderr)
        return False


def build_media_inline_keyboard(
    tmdb_id: int,
    media_type: str,
    title: str,
    details: dict[str, Any] | None = None,
) -> dict[str, Any]:
    watch_url = build_watch_on_cineva_url(tmdb_id, media_type, title, details)
    return {
        "inline_keyboard": [
            [
                {
                    "text": "Watch on Cineva",
                    "url": watch_url,
                }
            ],
            [
                {
                    "text": "Download App",
                    "url": CINEVA_RELEASES_URL,
                },
                {
                    "text": "Watch Party",
                    "url": f"{CINEVA_DEEP_LINK_BASE}/",
                },
            ],
        ]
    }


def load_posted_cache(cache_path: Path) -> set[str]:
    if not cache_path.is_file():
        return set()
    try:
        raw = json.loads(cache_path.read_text(encoding="utf-8"))
        if isinstance(raw, dict) and isinstance(raw.get("posted"), list):
            return {str(x) for x in raw["posted"]}
    except Exception:
        pass
    return set()


def save_posted_cache(cache_path: Path, posted: set[str]) -> None:
    recent = sorted(posted)[-1500:]
    payload = {
        "updated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "posted": recent,
    }
    cache_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def enrich_item_details(
    tmdb_id: int,
    media_type: str,
    api_key: str,
    access_token: str,
) -> dict[str, Any] | None:
    """Fetches full item details in English (`en-US`)."""
    endpoint = f"/{media_type}/{tmdb_id}"
    return tmdb_request(endpoint, {"language": "en-US"}, api_key, access_token)


def fetch_candidate_releases(
    api_key: str,
    access_token: str,
) -> list[tuple[str, dict[str, Any]]]:
    """
    Collects fresh candidate releases across Movies, TV Series, Anime, and K-Drama in English.
    Interleaves categories so the Telegram channel gets a balanced mix of content.
    """
    today_iso = dt.datetime.now(dt.timezone.utc).date().isoformat()
    forty_five_days_ago = (dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=45)).isoformat()

    buckets: list[list[tuple[str, dict[str, Any]]]] = []

    # 1. Trending Movies (Day)
    res_movies = tmdb_request("/trending/movie/day", {"language": "en-US"}, api_key, access_token)
    if res_movies and isinstance(res_movies.get("results"), list):
        buckets.append([("movie", m) for m in res_movies["results"][:10]])

    # 2. Trending TV Series (Day)
    res_tv = tmdb_request("/trending/tv/day", {"language": "en-US"}, api_key, access_token)
    if res_tv and isinstance(res_tv.get("results"), list):
        buckets.append([("tv", t) for t in res_tv["results"][:10]])

    # 3. Latest K-Drama
    res_kdrama = tmdb_request(
        "/discover/tv",
        {
            "language": "en-US",
            "with_origin_country": "KR",
            "sort_by": "first_air_date.desc",
            "first_air_date.lte": today_iso,
            "first_air_date.gte": forty_five_days_ago,
            "vote_count.gte": 2,
        },
        api_key,
        access_token,
    )
    if res_kdrama and isinstance(res_kdrama.get("results"), list):
        buckets.append([("tv", t) for t in res_kdrama["results"][:8]])

    # 4. Latest Anime
    res_anime = tmdb_request(
        "/discover/tv",
        {
            "language": "en-US",
            "with_genres": "16",
            "with_origin_country": "JP",
            "sort_by": "first_air_date.desc",
            "first_air_date.lte": today_iso,
            "first_air_date.gte": forty_five_days_ago,
            "vote_count.gte": 2,
        },
        api_key,
        access_token,
    )
    if res_anime and isinstance(res_anime.get("results"), list):
        buckets.append([("tv", t) for t in res_anime["results"][:8]])

    interleaved: list[tuple[str, dict[str, Any]]] = []
    max_len = max((len(b) for b in buckets), default=0)
    for idx in range(max_len):
        for bucket in buckets:
            if idx < len(bucket):
                interleaved.append(bucket[idx])
    return interleaved


def run_releases_broadcast(
    bot_token: str,
    chat_id: str,
    api_key: str,
    access_token: str,
    scraper_url: str,
    cache_path: Path,
    max_posts: int,
    dry_run: bool,
    specific_tmdb_id: int | None = None,
    specific_media_type: str = "movie",
) -> int:
    posted_cache = load_posted_cache(cache_path)
    sent_count = 0

    if specific_tmdb_id:
        candidates = [(specific_media_type, {"id": specific_tmdb_id})]
    else:
        candidates = fetch_candidate_releases(api_key, access_token)

    for media_type, summary in candidates:
        if sent_count >= max_posts:
            break
        tmdb_id = int(summary.get("id") or 0)
        if tmdb_id <= 0:
            continue
        cache_key = f"{media_type}:{tmdb_id}"
        if not specific_tmdb_id and cache_key in posted_cache:
            continue

        details = enrich_item_details(tmdb_id, media_type, api_key, access_token)
        if not details:
            continue

        poster_path = details.get("poster_path") or summary.get("poster_path")
        if not poster_path:
            continue

        # Check release date <= today + 1 day grace
        rel_date_str = (details.get("release_date") or details.get("first_air_date") or "").strip()
        if len(rel_date_str) >= 10:
            try:
                rel_date = dt.date.fromisoformat(rel_date_str[:10])
                if rel_date > (dt.datetime.now(dt.timezone.utc).date() + dt.timedelta(days=1)):
                    continue
            except ValueError:
                pass

        # Verify stream availability so we never post unwatchable items
        if not is_stream_available(tmdb_id, media_type, details, scraper_url):
            print(f"[SKIP] {media_type}:{tmdb_id} not yet available on stream servers.")
            continue

        title = (
            details.get("title")
            or details.get("name")
            or details.get("original_title")
            or details.get("original_name")
            or "Cineva Title"
        )
        caption = format_media_caption(details, media_type)
        reply_markup = build_media_inline_keyboard(tmdb_id, media_type, title, details)
        photo_url = f"{TMDB_IMAGE_BASE}{poster_path}"

        ok = send_telegram_post(
            bot_token=bot_token,
            chat_id=chat_id,
            caption_html=caption,
            reply_markup=reply_markup,
            photo_url=photo_url,
            dry_run=dry_run,
        )
        if ok:
            sent_count += 1
            posted_cache.add(cache_key)
            if not dry_run:
                save_posted_cache(cache_path, posted_cache)
                if sent_count < max_posts:
                    time.sleep(3)

    print(f"[DONE] Broadcasted {sent_count} release post(s).")
    return 0


def translate_to_english(text: str) -> str:
    """
    Automatically translates Indonesian/non-English release note lines into natural English
    so Telegram broadcasts on @cineva_platform are always 100% English.
    """
    cleaned = text.strip()
    if not cleaned:
        return cleaned
    qs = urllib.parse.urlencode(
        {
            "client": "gtx",
            "sl": "auto",
            "tl": "en",
            "dt": "t",
            "q": cleaned,
        }
    )
    url = f"https://translate.googleapis.com/translate_a/single?{qs}"
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"},
        method="GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            if resp.status == 200:
                data = json.loads(resp.read().decode("utf-8", errors="replace"))
                if isinstance(data, list) and data and isinstance(data[0], list):
                    parts = [
                        str(seg[0])
                        for seg in data[0]
                        if isinstance(seg, list) and seg and seg[0] is not None
                    ]
                    translated = "".join(parts).strip()
                    if translated:
                        return translated
    except Exception:
        pass
    return cleaned


def _clean_markdown_line(text: str) -> str:
    """Strips Markdown formatting tokens (#, **, *, `, links) from a single line."""
    s = text.strip()
    # Convert markdown links [label](url) -> label
    s = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", s)
    # Remove heading hashes and numbered prefix like "### 1. "
    s = re.sub(r"^#{1,6}\s*(?:\d+\.\s*)?", "", s)
    # Remove leading bullet symbols
    s = re.sub(r"^[-*•+]\s+", "", s)
    # Strip bold/italic/code markers
    s = s.replace("**", "").replace("__", "").replace("`", "")
    s = re.sub(r"\s+", " ", s).strip(" :-–—")
    return s


def extract_core_release_highlights(raw_notes: str, max_items: int = 6) -> list[str]:
    """
    Extracts only the core feature highlights from a full Markdown release body,
    stripping raw Markdown symbols and verbose sub-bullets.
    """
    if not raw_notes or not raw_notes.strip():
        return [
            "Full Hindi (India) language support alongside Indonesian and English",
            "Personalized 'Because You Watched' recommendations on Home",
            "Cineva Insights & Watch Stats page in Profile",
            "Optimized background download engine with instant finalizing",
            "Added Anime, K-Drama, Indonesia, Hollywood & Bollywood sections",
            "Search results now default to newest releases first",
        ]

    lines = raw_notes.splitlines()
    heading_highlights: list[str] = []
    bullet_highlights: list[str] = []

    for raw_line in lines:
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("---"):
            continue
        # Stop before older version history or build file lists
        if re.match(r"^#{1,3}\s*(?:Riwayat Versi|Previous Versions|Informasi Versi|Version Info)", stripped, re.I):
            break

        # 1. Capture numbered feature headings like "### 1. Feature Name (*English Subtitle*)"
        m_head = re.match(r"^###\s+(?:\d+\.\s*)?(.+)$", stripped)
        if m_head:
            raw_heading = m_head.group(1).strip()
            # If there is an English parenthetical (*...*), prefer the English title for the English Telegram channel
            paren_match = re.search(r"\(\*([^*]+)\*\)", raw_heading)
            if paren_match:
                cleaned = _clean_markdown_line(paren_match.group(1))
            else:
                cleaned = _clean_markdown_line(raw_heading)
            if cleaned and len(cleaned) >= 4:
                heading_highlights.append(cleaned)
            continue

        # 2. Capture top-level bullets (not deeply indented sub-bullets)
        indent = len(raw_line) - len(raw_line.lstrip(" "))
        if indent <= 2 and re.match(r"^[-*•]\s+", stripped):
            cleaned = _clean_markdown_line(stripped)
            # Keep only concise summary part before a colon if the line is very long
            if ":" in cleaned and len(cleaned) > 95:
                head_part, tail_part = cleaned.split(":", 1)
                if 10 <= len(head_part.strip()) <= 75:
                    cleaned = head_part.strip()
                else:
                    cleaned = f"{head_part.strip()}: {tail_part.strip()[:70].rstrip()}..."
            elif len(cleaned) > 105:
                cleaned = cleaned[:102].rstrip() + "..."
            if cleaned and not cleaned.lower().startswith("cineva_"):
                bullet_highlights.append(cleaned)

    chosen = heading_highlights if len(heading_highlights) >= 2 else bullet_highlights
    if not chosen:
        for raw_line in lines:
            cleaned = _clean_markdown_line(raw_line)
            if len(cleaned) >= 8:
                chosen.append(cleaned[:100])
            if len(chosen) >= max_items:
                break

    # Ensure every extracted highlight is in English
    english_highlights: list[str] = []
    for item in chosen[:max_items]:
        en_item = _clean_markdown_line(translate_to_english(item))
        if en_item:
            english_highlights.append(en_item)
    return english_highlights


def run_app_update_broadcast(
    bot_token: str,
    chat_id: str,
    version_tag: str,
    release_title: str,
    release_notes: str,
    release_url: str,
    dry_run: bool,
) -> int:
    clean_tag = html.escape(version_tag or "Latest")
    raw_title = (release_title or f"Cineva Stream {version_tag}").strip()
    # Remove trailing emojis/clutter from title
    raw_title = re.sub(r"[\U0001F300-\U0001FAFF]+", "", raw_title).strip(" -–—")
    clean_title = html.escape(raw_title or f"Cineva Stream {version_tag}")

    highlights = extract_core_release_highlights(release_notes, max_items=6)
    bullet_lines = [f"• {html.escape(item)}" for item in highlights]

    caption = "\n".join(
        [
            f"<b>{clean_title}</b> (<code>{clean_tag}</code>)",
            "<i>New App Update Available</i>",
            "",
            "<b>Key Updates</b>",
            *bullet_lines,
            "",
            "<i>Update your Cineva app to get the latest features and performance improvements.</i>",
        ]
    )

    target_download_url = release_url.strip() or CINEVA_RELEASES_URL
    reply_markup = {
        "inline_keyboard": [
            [
                {
                    "text": f"Download Update ({version_tag or 'Latest'})",
                    "url": target_download_url,
                }
            ],
            [
                {
                    "text": "Open Cineva",
                    "url": f"{CINEVA_DEEP_LINK_BASE}/",
                }
            ],
        ]
    }

    ok = send_telegram_post(
        bot_token=bot_token,
        chat_id=chat_id,
        caption_html=caption,
        reply_markup=reply_markup,
        photo_url=None,
        dry_run=dry_run,
    )
    return 0 if ok else 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Cineva Automated Telegram Channel Broadcaster")
    parser.add_argument(
        "--mode",
        choices=["releases", "app-update", "test"],
        default="releases",
        help="Broadcast mode: 'releases' (new movies/series), 'app-update' (new APK release), or 'test'.",
    )
    parser.add_argument(
        "--max-posts",
        type=int,
        default=2,
        help="Maximum number of release posts to send in one run (default: 2).",
    )
    parser.add_argument(
        "--tmdb-id",
        type=int,
        default=None,
        help="Optional specific TMDB ID to broadcast immediately.",
    )
    parser.add_argument(
        "--media-type",
        choices=["movie", "tv"],
        default="movie",
        help="Media type when --tmdb-id is specified (movie or tv).",
    )
    parser.add_argument(
        "--cache-file",
        type=str,
        default=str(DEFAULT_CACHE_PATH),
        help="Path to JSON file tracking already-broadcasted TMDB IDs.",
    )
    parser.add_argument("--version-tag", type=str, default="", help="Release tag for --mode app-update.")
    parser.add_argument("--release-title", type=str, default="", help="Release title for --mode app-update.")
    parser.add_argument("--release-notes", type=str, default="", help="Release notes for --mode app-update.")
    parser.add_argument("--release-url", type=str, default="", help="Release URL for --mode app-update.")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview the Telegram message and inline keyboard buttons without sending.",
    )

    args = parser.parse_args()
    local_env = load_local_env()

    bot_token = get_config("TELEGRAM_BOT_TOKEN", local_env)
    raw_chat_id = get_config("TELEGRAM_CHAT_ID", local_env, default=DEFAULT_TELEGRAM_CHANNEL)
    chat_id = normalize_chat_id(raw_chat_id)
    api_key = get_config("TMDB_API_KEY", local_env)
    access_token = get_config("TMDB_ACCESS_TOKEN", local_env)
    scraper_url = get_config("CINEVA_SCRAPER_API_URL", local_env)

    if not args.dry_run and not bot_token:
        print(
            "[ERROR] Missing TELEGRAM_BOT_TOKEN.\n"
            "Set it in your local .env file or GitHub Actions Secrets:\n"
            "  TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz\n"
            f"  TELEGRAM_CHAT_ID={DEFAULT_TELEGRAM_CHANNEL}",
            file=sys.stderr,
        )
        return 1

    if args.mode == "app-update":
        return run_app_update_broadcast(
            bot_token=bot_token,
            chat_id=chat_id,
            version_tag=args.version_tag or os.environ.get("RELEASE_TAG", "vLatest"),
            release_title=args.release_title or os.environ.get("RELEASE_TITLE", ""),
            release_notes=args.release_notes or os.environ.get("RELEASE_NOTES", ""),
            release_url=args.release_url or os.environ.get("RELEASE_URL", CINEVA_RELEASES_URL),
            dry_run=args.dry_run,
        )

    max_posts = 1 if args.mode == "test" else max(1, args.max_posts)
    return run_releases_broadcast(
        bot_token=bot_token,
        chat_id=chat_id,
        api_key=api_key,
        access_token=access_token,
        scraper_url=scraper_url,
        cache_path=Path(args.cache_file),
        max_posts=max_posts,
        dry_run=args.dry_run,
        specific_tmdb_id=args.tmdb_id,
        specific_media_type=args.media_type,
    )


if __name__ == "__main__":
    sys.exit(main())
