# Cineva v1.2.2 — Release Notes 🎬

**Cineva v1.2.2 (Build 23)** delivers a major overhaul to the **Live TV & Real-Time Football Broadcast** experience, universal playback reliability across all national and international live channels, and a suite of new cinematic and data-resilience features. Key highlights include the **Real-Time EPG + Live Scoreboard Football Detection Engine** paired with a **Tournament-Styled Live Football Modal**, an in-app **Local Loopback DASH-to-HLS fMP4 Bridge** for crash-free dynamic MPD streaming, **Account-Free Local Auto Backup** directly to `Documents/Cineva`, **Scene Bookmarks & Cinematic Quote Card Studio**, **Two-Row Rich Media Sharing with Instant `0ms` Deep Links**, **Watch Party `1.05x` Smooth Micro-Speed Catch-Up**, a **3-Missed-Updates Mandatory Update Guard**, and a **Trilingual Release Notes Timeline**.

---

## Key Features & Enhancements (v1.2.2)

### 1. Real-Time EPG Football Match Detection & Tournament Modal
* **Real-Time XMLTV EPG & Live Scoreboard Cross-Verification**:
  * The live football detection engine now cross-references currently airing TV programmes (`start <= now < stop`) from the real-time XMLTV Electronic Program Guide across Cineva's sports and national channels (*SCTV HD, Indosiar HD, RCTI HD, MNCTV HD, GTV HD, iNews HD, Moji, TVRI Sport HD, TVRI Nasional, beIN Sports 1 HD, beIN Sports 2 HD, beIN Sports 3 HD, Soccer Channel HD, Sportstars HD, SPOTV 2 HD, A Spor HD*) against live match feeds from the ESPN Soccer Scoreboard.
  * The **"Broadcasting on"** section is now **100% real-time and verified**: it strictly displays only the channel(s) genuinely airing the selected match right now, complete with each channel's live EPG programme title and broadcast time window (e.g., `UEL 2026/27: OLY Vs MIL (L) • 00:40–02:55 WIB`).
  * When multiple matches kick off simultaneously across different channels (e.g., Match A on *beIN Sports 1 HD*, Match B on *beIN Sports 2 HD*, and Match C on *SCTV HD & beIN Sports 3 HD*), each fixture is cleanly separated and mapped to its exact broadcasting channel(s).
  * Automatically filters out unbroadcast foreign fixtures as well as non-football sports and magazine fillers (*Premier Padel, V-League Volleyball, Highlights, Mini Matches*).
* **Redesigned Tournament Matchday Arena Modal**:
  * Re-engineered the **`LIVE FOOTBALL MATCH`** modal with an authentic football tournament broadcast aesthetic free of badge clutter: a clean competition header with a live indicator dot, a matchday scoreboard arena with circular team crest rings, official broadcaster cards with verified channel logos and live schedule slots, and a pinned **"Watch Now"** action bar that immediately launches the selected live channel.

### 2. Live TV Player Engine Overhaul & 75 Verified Channels with Official Logos
* **In-App Local Loopback DASH-to-HLS fMP4 Bridge (`127.0.0.1`)**:
  * Built an internal loopback proxy that dynamically translates live DASH MPD manifests (`index.mpd` with `<SegmentTimeline>` on *SCTV HD, Indosiar HD, Moji, Metro TV, ANTV, tvOne, MDTV, RTV, BTV, TVRI*) into standard fMP4 HLS live playlists (`#EXT-X-MAP`) on the fly, eliminating `dashdec` segmentation faults and infinite buffering in FFmpeg / `libmpv`.
* **Smart Dynamic Master Playlist & Cross-Domain Redirect Resolver**:
  * Automatically resolves dynamic Wurl/Xumo master playlists (*FIFA+ Live HD, NBC News NOW, ABC News Live*) directly to their 720p/1080p video child playlists and pre-resolves cross-domain `302` redirects (*RCTI HD, GTV HD, MNCTV HD, iNews HD*) while injecting native `libmpv` `Referer` and `User-Agent` headers and disabling empty WebVTT subtitle tracks (`sid=no`).
* **75 Curated Live Channels & Verified Full-Resolution Logos**:
  * Audited and upgraded all 75 Live TV channels across every category (*Sports, Indonesian National, News, Movies, Kids, Music, Documentary*) with multi-URL automatic failover (`fallbackStreamUrls`) and verified official high-resolution channel logos (including updated official logos for *Trans TV* and *iNews HD*).

### 3. Account-Free Local Auto Backup (`Documents/Cineva`)
* **Automated On-Device Data Protection**:
  * Added an **Auto Backup** management screen in Settings that automatically backs up watch history, watchlist items, user profile data, and app preferences directly to the local `Documents/Cineva` directory without requiring a cloud account.
  * Supports **Weekly (7-day)**, **Monthly (30-day)**, or **Off** schedules, alongside an instant **Back Up Now** trigger and a saved backups manager for one-tap restoration or cleanup.

### 4. Scene Bookmarks & Cinematic Quote Card Studio
* **In-Player Scene Bookmarking**:
  * Users can bookmark memorable scenes at the exact timestamp directly inside the video player, automatically capturing the active subtitle line or custom notes.
* **Cinematic Quote Card Generator**:
  * Transform bookmarked scenes and dialogue lines into high-resolution, cinema-styled quote cards ready to save or share across social platforms.

### 5. Two-Row Rich Media Sharing & Instant `0ms` Root Deep Links
* **Ergonomic Two-Row Detail Action Bar & Poster Sharing**:
  * Movie and TV Series detail screens now feature a balanced two-row action layout with a **Share** button that automatically attaches the official title poster alongside a direct deep link (`https://cineva-stream.github.io/movie/:id` and `/tv/:id`).
* **Instant `0ms` Native App Launch**:
  * Root web deep-link pages for Movies, TV Series, and Watch Party rooms (`/party/:code`) immediately trigger native app opening at `0ms`, backed by a responsive English fallback landing page when the app is not yet installed.

### 6. Watch Party `1.05x` Smooth Micro-Speed Catch-Up
* **Buffer-Free Playback Synchronization**:
  * When a Watch Party participant drifts slightly behind the host (`0.8 – 3.5 seconds`), the video player automatically applies a imperceptible **`1.05x`** micro-speed boost until synchronized—eliminating jarring hard seeks and re-buffering interruptions.

### 7. Mandatory Update Guard, Trilingual Release Notes Timeline & Automated Feedback Replies
* **3-Missed-Updates Mandatory Update Screen**:
  * Presents a full-screen *Cinema Amber* mandatory update gate whenever the installed application falls 3 or more versions behind the latest release.
* **Trilingual Release Notes Timeline & Dedicated App Language Screen**:
  * Added an interactive vertical **Release Notes** timeline summarizing core version highlights across all 3 supported languages (**Indonesian, English, and Hindi**), plus a dedicated **App Language** selection screen.
* **Plain-Text SMTP Auto-Reply for User Feedback**:
  * Submitting in-app feedback or bug reports now dispatches an automated confirmation email formatted with `Asia/Jakarta (WIB)` timestamps.

---

## Previous Releases

### Cineva v1.2.1
* **Full Trilingual Localization (`id`, `en`, `hi`)**: Complete user interface localization across Indonesian, English, and Hindi (हिन्दी), paired with automatic `en-US` episode metadata enrichment.
* **Personalized *"Because You Watched..."* Recommendations**: Dynamic home screen rails curated from your most recently watched movies and TV series.
* **Cineva Insights & Member Card Studio**: Visual watch-time analytics, genre distribution, and milestone tracking in the Profile tab, complete with shareable ID-style and ATM-style Cineva Member Cards.
* **High-Speed Background Isolate Download Engine**: Offloaded HLS segment fetching, 16-worker parallel `AES-128-CBC` decryption, and MPEG-TS packet alignment to a dedicated background `Isolate` with instant (`< 0.5s`) progressive finalization and a Smart Concurrent Download Queue.
* **5 New Regional Catalogs & Unified Smart Filter Bar**: Added **Anime, K-Drama, Indonesian, Hollywood, and Bollywood** home sections with full infinite-scroll *See All* pages, smart *"Coming Soon"* release guards, newest-first search sorting, and official Telegram channel integration (`https://t.me/cineva_platform`).

### Cineva v1.2.0
* **Dynamic Island Watch Party Chat Notifications**: Floating glassmorphic chat preview capsules when the Watch Party side panel is collapsed.
* **16:9 Seekbar Mini Preview & Floating Timecode Delta**: Live video frame previews with precise digital timecodes and seek delta indicators on desktop hover and mobile touch scrubbing.
* **Real-Time Floating Emoji Reaction Particles**: TikTok Live-inspired synchronized emoji streams across all Watch Party participants.
* **4-Digit Watch Party Room PIN & Deep Linking**: Optional 4-digit room security PINs and direct room invitation deep links.
* **Redesigned App Info Screen & Official Package Identity**: Borderless poster mosaic header on the App Info page and package migration to `com.cinevagroup.cinevastream`.

### Cineva v1.1.9
* **Seamless Cross-Device Hand-Off**: Cloud-tracked playback sessions with instant resume notifications at the exact timestamp across devices.
* **Remote Watch Party & Sync Play Engine**: 8-digit room codes, dual-engine cloud relay (Firebase & Cloud Relay), side-panel live chat, and latency-compensated playback sync.
* **Natural Acronym Normalization & Cinematic NLP Subtitle Engine**: Improved period-boundary tokenization (`L.A.P.D.`, `U.S.A.`) and local natural-dialogue post-processing for cinema-grade subtitle translations.
* **Real-Time Cloud Synchronization**: Automatic background cloud sync for Watchlist, Watch History, and user profiles.

### Cineva v1.1.8
* **Responsive Multi-Device Layouts**: Adaptive grids and Side Navigation Rail support for Tablets, Windows Desktop, and Android TV.
* **Complete Android TV D-Pad Remote Navigation**: Dedicated `TvFocusable` focus engine across Search, Detail, Watchlist, History, Downloads, and Video Player controls.
* **Standalone Offline HLS Downloader**: HLS `.m3u8` parser, `AES-128` segment decryption, and standalone MP4 container assembly via `OfflineMp4Builder`.
* **Video Player & Native Android PiP Refinements**: Ergonomic top control bar, clean Back navigation separated from Picture-in-Picture activation, and automatic 1080p/4K subtitle scaling for TV screens.

---

## Release Information

* **App Version**: 1.2.2
* **Build Number**: 23
* **Supported Platforms**: Android 5.0 (API 21)+ (Smartphones, Tablets & Android TV / Google TV), Windows 10/11 (64-bit)
* **Release Assets**:
  * `Cineva_setup_v1.2.2.exe` (Official Windows Desktop Installer)
  * `Cineva_v1.2.2-android-tv.apk` (Dedicated Android TV & Smart TV Build — **Recommended for TV**)
  * `Cineva_v1.2.2-arm64-v8a.apk` (Modern 64-bit Android Phones & Tablets)
  * `Cineva_v1.2.2-armeabi-v7a.apk` (Legacy 32-bit Android Devices)
  * `Cineva_v1.2.2-x86_64.apk` (PC Emulators & x86_64 Android Devices)
  * `Cineva_v1.2.2.apk` (Universal APK — All CPU Architectures)
