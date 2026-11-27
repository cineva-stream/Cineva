import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/live_football_match.dart';
import '../../domain/entities/live_tv_channel.dart';
import '../datasources/live_tv_channels_data.dart';

/// Represents a currently-airing football broadcast parsed from the real-time
/// XMLTV Electronic Program Guide (`epg.xml`).
class EpgFootballProgramme {
  final String epgChannelId;
  final List<LiveTvChannel> cinevaChannels;
  final DateTime startUtc;
  final DateTime stopUtc;
  final String rawTitle;
  final String competitionName;
  final String? homeToken;
  final String? awayToken;
  final bool hasExplicitLiveTag;

  const EpgFootballProgramme({
    required this.epgChannelId,
    required this.cinevaChannels,
    required this.startUtc,
    required this.stopUtc,
    required this.rawTitle,
    required this.competitionName,
    this.homeToken,
    this.awayToken,
    required this.hasExplicitLiveTag,
  });

  bool get hasTeams =>
      homeToken != null &&
      homeToken!.trim().isNotEmpty &&
      awayToken != null &&
      awayToken!.trim().isNotEmpty;

  /// Formats the programme's broadcast window in WIB (`UTC+7`), e.g. `'00:40–02:55 WIB'`.
  String get wibTimeWindow {
    final startWib = startUtc.toUtc().add(const Duration(hours: 7));
    final stopWib = stopUtc.toUtc().add(const Duration(hours: 7));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(startWib.hour)}:${two(startWib.minute)}–${two(stopWib.hour)}:${two(stopWib.minute)} WIB';
  }

  /// Formatted EPG program label with its WIB broadcast window.
  String get formattedProgramInfo => '$rawTitle • $wibTimeWindow';
}

/// Internal parsed model for an in-progress (`state == 'in'`) ESPN soccer match.
class EspnLiveSoccerEvent {
  final String id;
  final String competitionName;
  final String homeName;
  final String homeAbbreviation;
  final String? homeLogo;
  final String homeScore;
  final String awayName;
  final String awayAbbreviation;
  final String? awayLogo;
  final String awayScore;
  final String statusDetail;

  const EspnLiveSoccerEvent({
    required this.id,
    required this.competitionName,
    required this.homeName,
    required this.homeAbbreviation,
    this.homeLogo,
    required this.homeScore,
    required this.awayName,
    required this.awayAbbreviation,
    this.awayLogo,
    required this.awayScore,
    required this.statusDetail,
  });
}

/// Service that detects currently in-progress (live) football matches by
/// cross-verifying real-time TV channel EPG schedules (`epg.xml`) with
/// live ESPN Soccer Scoreboard data.
///
/// Only matches that are genuinely being broadcast right now on a Cineva
/// [LiveTvChannel] are returned in [fetchLiveMatches].
class LiveFootballMatchService {
  LiveFootballMatchService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Accept': 'application/json, application/xml, text/xml, */*'},
            ),
          );

  final Dio _dio;

  static const String _epgXmlUrl =
      'https://raw.githubusercontent.com/dhasap/dhanytv/main/epg.xml';

  static const List<String> _scoreboardUrls = [
    'https://site.api.espn.com/apis/site/v2/sports/soccer/idn.1/scoreboard',
    'https://site.api.espn.com/apis/site/v2/sports/soccer/uefa.champions/scoreboard',
    'https://site.api.espn.com/apis/site/v2/sports/soccer/uefa.europa/scoreboard',
    'https://site.api.espn.com/apis/site/v2/sports/soccer/uefa.europa.conf/scoreboard',
    'https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/scoreboard',
    'https://site.api.espn.com/apis/site/v2/sports/soccer/esp.1/scoreboard',
    'https://site.api.espn.com/apis/site/v2/sports/soccer/ita.1/scoreboard',
    'https://site.api.espn.com/apis/site/v2/sports/soccer/ger.1/scoreboard',
    'https://site.api.espn.com/apis/site/v2/sports/soccer/afc.champions/scoreboard',
    'https://site.api.espn.com/apis/site/v2/sports/soccer/all/scoreboard',
  ];

  /// Exact mapping from XMLTV EPG channel IDs in `epg.xml` to Cineva channel IDs.
  static const Map<String, List<String>> _epgToCinevaChannelIds = {
    'SCTV.id': ['id_sctv'],
    'Indosiar.id': ['id_indosiar'],
    'RCTI.id': ['id_rcti'],
    'MNCTV.id': ['id_mnctv'],
    'GTV.id': ['id_gtv'],
    'iNews.id': ['id_inews'],
    'Moji.id': ['id_moji'],
    'TVRI.id': ['id_tvri_sport', 'id_tvri_nasional'],
    'beInSports1.id': ['ch_bein_sports_1'],
    'beInSports2.id': ['ch_bein_sports_2'],
    'beInSports3.id': ['ch_bein_sports_3'],
    'SoccerChannel.id': ['ch_soccer_channel'],
    'Sportstars.id': ['ch_sportstars'],
    'Sportstars2.id': ['ch_sportstars'],
    'SPOTV2.id': ['ch_spotv_2'],
    'ASpor.tr@SD': ['ch_aspor'],
  };

  /// Common 3-letter EPG team code dictionary to human-readable club/country names
  /// and canonical matching aliases.
  static const Map<String, String> _teamCodeDictionary = {
    // European Clubs (UCL / UEL / UECL / LaLiga / EPL / Serie A / Bundesliga)
    'CEL': 'Celta Vigo',
    'BOU': 'Bournemouth',
    'CRY': 'Crystal Palace',
    'RSO': 'Real Sociedad',
    'BHA': 'Brighton',
    'UCR': 'U Craiova',
    'JUV': 'Juventus',
    'OMO': 'Omonia Nicosia',
    'OLY': 'Olympiacos',
    'MIL': 'AC Milan',
    'ACM': 'AC Milan',
    'INT': 'Inter Milan',
    'SUN': 'Sunderland',
    'JAG': 'Jagiellonia',
    'RMA': 'Real Madrid',
    'BAR': 'Barcelona',
    'FCB': 'Barcelona',
    'ATM': 'Atlético Madrid',
    'ATH': 'Athletic Club',
    'ESP': 'Espanyol',
    'VIL': 'Villarreal',
    'LEV': 'Levante',
    'RAC': 'Racing Santander',
    'LEG': 'Leganés',
    'SAB': 'Sabadell',
    'BET': 'Real Betis',
    'RAY': 'Rayo Vallecano',
    'MAL': 'Mallorca',
    'SEV': 'Sevilla',
    'VAL': 'Valencia',
    'GIR': 'Girona',
    'ALA': 'Alanyaspor',
    'KON': 'Konyaspor',
    'GAL': 'Galatasaray',
    'FEN': 'Fenerbahçe',
    'BJK': 'Beşiktaş',
    'HBS': 'Hapoel Be\'er Sheva',
    'SVW': 'Werder Bremen',
    'BMG': 'Mönchengladbach',
    'S04': 'Schalke 04',
    'VFB': 'VfB Stuttgart',
    'BAY': 'Bayern Munich',
    'BVB': 'Borussia Dortmund',
    'RBL': 'RB Leipzig',
    'B04': 'Bayer Leverkusen',
    'ARS': 'Arsenal',
    'MCI': 'Man City',
    'MUN': 'Man United',
    'LIV': 'Liverpool',
    'CHE': 'Chelsea',
    'TOT': 'Tottenham',
    'NEW': 'Newcastle',
    'AVL': 'Aston Villa',
    'WHU': 'West Ham',
    'PSG': 'Paris Saint-Germain',
    'LYO': 'Lyon',
    'LIL': 'Lille',
    'MAR': 'Marseille',
    'ASM': 'AS Monaco',
    'REN': 'Rennes',
    'NAP': 'Napoli',
    'ROM': 'AS Roma',
    'LAZ': 'Lazio',
    'ATA': 'Atalanta',
    'TOR': 'Torino',
    'AJX': 'Ajax',
    'PSV': 'PSV Eindhoven',
    'FEY': 'Feyenoord',
    'POR': 'FC Porto',
    'BEN': 'Benfica',
    'SCP': 'Sporting CP',
    'DIN': 'Dinamo Zagreb',
    // Asian / AFC / Indonesian Clubs
    'BGP': 'BG Pathum United',
    'LCS': 'Lion City Sailors',
    'TPO': 'Tai Po',
    'ADL': 'Adelaide United',
    'KAS': 'Kashima Antlers',
    'JEO': 'Jeonbuk Motors',
    'GAM': 'Gamba Osaka',
    'KYO': 'Kyoto Sanga',
    'POH': 'Pohang Steelers',
    'DJO': 'Johor Darul Ta\'zim',
    'JDT': 'Johor Darul Ta\'zim',
    'BJG': 'Beijing Guoan',
    'GWN': 'Gangwon FC',
    'KIT': 'Kitchee SC',
    'KUC': 'Kuching City',
    'PPC': 'Phnom Penh Crown',
    'NSR': 'Al Nassr',
    'HIL': 'Al Hilal',
    'AHL': 'Al Ahly',
    'AZA': 'Zamalek',
    'SDD': 'Al Sadd',
    'PSB': 'Persib Bandung',
    'PSJ': 'Persija Jakarta',
    'BFC': 'Borneo FC',
    'BOR': 'Borneo FC',
    'MDG': 'Madura United',
    'PSM': 'PSM Makassar',
    'ARE': 'Arema FC',
    'BYU': 'Bali United',
    'SEO': 'FC Seoul',
    // National Teams (World Cup / U-17 / Nations League / AFC)
    'IDN': 'Indonesia',
    'INA': 'Indonesia',
    'JPN': 'Jepang',
    'BHR': 'Bahrain',
    'KOR': 'Korea Selatan',
    'AUS': 'Australia',
    'MOZ': 'Mozambik',
    'SPA': 'Spanyol',
    'ESP_NT': 'Spanyol',
    'FIJ': 'Fiji',
    'GRE': 'Yunani',
    'QAT': 'Qatar',
    'VIE': 'Vietnam',
    'MLI': 'Mali',
    'TJK': 'Tajikistan',
    'SEN': 'Senegal',
    'VEN': 'Venezuela',
    'ROU': 'Rumania',
    'UZB': 'Uzbekistan',
    'ITA': 'Italia',
    'COL': 'Kolombia',
    'SRB': 'Serbia',
    'MEX': 'Meksiko',
    'ECU': 'Ekuador',
    'CRO': 'Kroasia',
    'CUB': 'Kuba',
    'URU': 'Uruguay',
    'FRA': 'Prancis',
    'BEL': 'Belgia',
    'GER': 'Jerman',
    'ENG': 'Inggris',
    'NED': 'Belanda',
    'ARG': 'Argentina',
    'BRA': 'Brasil',
  };

  /// Cached raw EPG XML content and fetch timestamp to avoid redundant downloads.
  static String? _cachedEpgXml;
  static DateTime? _cachedEpgFetchedAt;
  static const Duration _epgCacheDuration = Duration(minutes: 5);

  /// Keeps track of match IDs that have already triggered an automatic popup
  /// during the current app session so the user is not spammed repeatedly.
  static final Set<String> _shownModalMatchIds = <String>{};

  static bool hasUnseenLiveMatches(List<LiveFootballMatch> matches) {
    return matches.any((m) => m.isLive && !_shownModalMatchIds.contains(m.id));
  }

  static void markMatchesAsShown(Iterable<LiveFootballMatch> matches) {
    for (final m in matches) {
      _shownModalMatchIds.add(m.id);
    }
  }

  @visibleForTesting
  static void clearShownMatchesForTest() {
    _shownModalMatchIds.clear();
  }

  /// Fetches all currently live football matches that are genuinely being
  /// broadcast right now on one or more Cineva Live TV channels.
  Future<List<LiveFootballMatch>> fetchLiveMatches({DateTime? nowUtc}) async {
    final currentUtc = (nowUtc ?? DateTime.now()).toUtc();

    // 1. Fetch real-time EPG XML and ESPN live scoreboards in parallel.
    final results = await Future.wait<dynamic>([
      _fetchEpgXml(),
      _fetchAllEspnLiveEvents(),
    ]);

    final epgXml = results[0] as String?;
    final espnEvents = results[1] as List<EspnLiveSoccerEvent>;

    if (epgXml == null || epgXml.isEmpty) {
      return const [];
    }

    // 2. Parse active football broadcasts airing right now (`start <= now < stop`).
    final activeProgrammes = parseActiveEpgFootballProgrammes(
      epgXml,
      nowUtc: currentUtc,
    );

    if (activeProgrammes.isEmpty) {
      return const [];
    }

    // 3. Cross-match active EPG football programmes with live ESPN scoreboard events.
    return buildVerifiedLiveMatches(
      activeProgrammes: activeProgrammes,
      espnEvents: espnEvents,
    );
  }

  Future<String?> _fetchEpgXml() async {
    final now = DateTime.now();
    if (_cachedEpgXml != null &&
        _cachedEpgFetchedAt != null &&
        now.difference(_cachedEpgFetchedAt!) < _epgCacheDuration) {
      return _cachedEpgXml;
    }

    try {
      final resp = await _dio.get<String>(
        _epgXmlUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final xml = resp.data;
      if (xml != null && xml.contains('<programme ')) {
        _cachedEpgXml = xml;
        _cachedEpgFetchedAt = now;
        return xml;
      }
    } catch (e) {
      debugPrint('[LiveFootballMatchService] EPG fetch note: $e');
    }
    return _cachedEpgXml;
  }

  Future<List<EspnLiveSoccerEvent>> _fetchAllEspnLiveEvents() async {
    final eventsById = <String, EspnLiveSoccerEvent>{};

    final futures = _scoreboardUrls.map((url) async {
      try {
        final resp = await _dio.get<dynamic>(url);
        final data = resp.data;
        if (data is Map<String, dynamic>) {
          final isIdn = url.contains('/idn.1/');
          return parseEspnLiveEvents(
            data,
            defaultCompetitionHint: isIdn ? 'BRI Liga 1' : null,
          );
        }
      } catch (_) {}
      return const <EspnLiveSoccerEvent>[];
    });

    final lists = await Future.wait(futures);
    for (final list in lists) {
      for (final ev in list) {
        eventsById.putIfAbsent(ev.id, () => ev);
      }
    }
    return eventsById.values.toList();
  }

  /// Fast scanner that extracts only currently airing (`startUtc <= nowUtc < stopUtc`)
  /// football match programmes for Cineva's mapped Live TV channels from `epg.xml`.
  static List<EpgFootballProgramme> parseActiveEpgFootballProgrammes(
    String xml, {
    DateTime? nowUtc,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final rawCandidates = <EpgFootballProgramme>[];

    int cursor = 0;
    while (true) {
      final tagStart = xml.indexOf('<programme ', cursor);
      if (tagStart == -1) break;

      final tagOpenEnd = xml.indexOf('>', tagStart + 11);
      if (tagOpenEnd == -1) break;

      final header = xml.substring(tagStart + 11, tagOpenEnd);
      final channelId = _extractXmlAttribute(header, 'channel');
      if (channelId == null || !_epgToCinevaChannelIds.containsKey(channelId)) {
        cursor = tagOpenEnd + 1;
        continue;
      }

      final startStr = _extractXmlAttribute(header, 'start');
      final stopStr = _extractXmlAttribute(header, 'stop');
      if (startStr == null || stopStr == null) {
        cursor = tagOpenEnd + 1;
        continue;
      }

      final startUtc = parseXmlTvTimestamp(startStr);
      final stopUtc = parseXmlTvTimestamp(stopStr);
      if (startUtc == null || stopUtc == null) {
        cursor = tagOpenEnd + 1;
        continue;
      }

      // Check if programme is currently on-air right now (`startUtc <= now < stopUtc`).
      if (now.isBefore(startUtc) || !now.isBefore(stopUtc)) {
        cursor = tagOpenEnd + 1;
        continue;
      }

      final tagClose = xml.indexOf('</programme>', tagOpenEnd);
      if (tagClose == -1) break;

      final innerXml = xml.substring(tagOpenEnd + 1, tagClose);
      final title = _extractXmlTagText(innerXml, 'title');
      cursor = tagClose + 12;

      if (title == null || title.trim().isEmpty) continue;

      final classified = classifyFootballProgramme(
        epgChannelId: channelId,
        rawTitle: _unescapeXml(title.trim()),
        startUtc: startUtc,
        stopUtc: stopUtc,
      );
      if (classified != null) {
        rawCandidates.add(classified);
      }
    }

    // Deduplicate overlapping EPG blocks per epgChannelId (e.g. when SCTV.id has
    // both a generic '+0700' block "UEFA Europa League (L)" and a specific '+0000'
    // block "Olympiacos Vs Ac Milan - Uefa Europa League - Live" at the same time).
    final byEpgChannel = <String, List<EpgFootballProgramme>>{};
    for (final prog in rawCandidates) {
      byEpgChannel.putIfAbsent(prog.epgChannelId, () => []).add(prog);
    }

    final deduplicated = <EpgFootballProgramme>[];
    for (final entry in byEpgChannel.entries) {
      final list = entry.value;
      final withTeams = list.where((p) => p.hasTeams).toList();
      if (withTeams.isNotEmpty) {
        deduplicated.add(withTeams.first);
      } else {
        deduplicated.add(list.first);
      }
    }

    return deduplicated;
  }

  /// Classifies whether an active EPG programme on [epgChannelId] is a football
  /// match broadcast (excluding non-football sports like Volleyball, Padel,
  /// MotoGP, Badminton, and non-match highlight/magazine fillers).
  static EpgFootballProgramme? classifyFootballProgramme({
    required String epgChannelId,
    required String rawTitle,
    required DateTime startUtc,
    required DateTime stopUtc,
  }) {
    final cinevaIds = _epgToCinevaChannelIds[epgChannelId];
    if (cinevaIds == null || cinevaIds.isEmpty) return null;

    final cinevaChannels = cinevaIds
        .map(LiveTvChannelsData.findById)
        .whereType<LiveTvChannel>()
        .toList();
    if (cinevaChannels.isEmpty) return null;

    final lower = rawTitle.toLowerCase();

    // 1. Exclude non-football sports and non-match TV programmes.
    const excludedKeywords = <String>[
      // Non-football sports
      'v-league',
      'volleyball',
      'voli',
      'premier padel',
      'padel',
      'badminton',
      'bwf',
      'motogp',
      'formula 1',
      'fei jumping',
      'equestrian',
      'tennis',
      'wimbledon',
      'basketball',
      'nba',
      'fiba',
      'ibl',
      'svns',
      'rugby',
      'golf',
      'ufc',
      'boxing',
      'mma',
      'wwe',
      'le mans',
      'motorsport',
      'cricket',
      'baseball',
      // Non-football shows containing "Liga" or general entertainment
      'liga dmd',
      'liga hipdut',
      'liga dangdut',
      'panggung rezeki',
      'ftv ',
      'ftv:',
      'sinetron',
      'liputan 6',
      'fokus',
      'patroli',
      'jadwal belum tersedia',
      // Non-match football fillers / highlights / magazine shows
      'highlights',
      'match hl',
      'mini match',
      'goals galore',
      'magazine',
      'rookies',
      'top 20',
      'top ten',
      'every goal',
      'club classic',
      'treble 20',
      'classic soccer',
      'world classic',
      'extra time',
      'planet football',
      'jurnal ',
      'laliga show',
      'ucl show',
      'uel show',
      'premier league show',
    ];

    for (final kw in excludedKeywords) {
      if (lower.contains(kw)) return null;
    }
    if (RegExp(r'\bshow\s+202\d').hasMatch(lower)) {
      return null;
    }

    // 2. Check for explicit live markers in the EPG title.
    final hasExplicitLiveTag =
        RegExp(r'\(\s*l\s*\)|\(\s*live\s*\)|-\s*live\b|\blive\s*:', caseSensitive: false)
            .hasMatch(rawTitle);

    // 3. Parse competition name and optional `<Home> Vs <Away>` tokens.
    final parsed = _parseTitleTokens(rawTitle);
    if (!parsed.isFootball) return null;

    return EpgFootballProgramme(
      epgChannelId: epgChannelId,
      cinevaChannels: cinevaChannels,
      startUtc: startUtc,
      stopUtc: stopUtc,
      rawTitle: rawTitle,
      competitionName: parsed.competitionName,
      homeToken: parsed.homeToken,
      awayToken: parsed.awayToken,
      hasExplicitLiveTag: hasExplicitLiveTag,
    );
  }

  static ({
    bool isFootball,
    String competitionName,
    String? homeToken,
    String? awayToken,
  }) _parseTitleTokens(String rawTitle) {
    // Strip trailing (L), (Live), - Live
    var cleaned = rawTitle
        .replaceAll(RegExp(r'\(\s*L\s*\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(\s*Live\s*\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*-\s*Live\s*$', caseSensitive: false), '')
        .trim();

    String? rawComp;
    String? teamsPart;

    // Pattern A: "Olympiacos Vs Ac Milan - Uefa Europa League"
    if (cleaned.contains(' - ') &&
        RegExp(r'\bvs\.?\b', caseSensitive: false).hasMatch(cleaned.split(' - ').first)) {
      final parts = cleaned.split(' - ');
      teamsPart = parts.first.trim();
      rawComp = parts.sublist(1).join(' - ').trim();
    }
    // Pattern B: "UEL 2026/27: CEL Vs BOU" or "Piala Dunia U-17: UZB Vs ITA"
    else if (cleaned.contains(':')) {
      final colonIdx = cleaned.indexOf(':');
      final left = cleaned.substring(0, colonIdx).trim();
      final right = cleaned.substring(colonIdx + 1).trim();
      if (RegExp(r'\bvs\.?\b', caseSensitive: false).hasMatch(right)) {
        rawComp = left;
        teamsPart = right;
      } else {
        rawComp = cleaned;
      }
    } else if (RegExp(r'\bvs\.?\b', caseSensitive: false).hasMatch(cleaned)) {
      teamsPart = cleaned;
    } else {
      rawComp = cleaned;
    }

    String? homeToken;
    String? awayToken;
    if (teamsPart != null) {
      final vsSplit = teamsPart.split(RegExp(r'\s+vs\.?\s+', caseSensitive: false));
      if (vsSplit.length >= 2) {
        homeToken = vsSplit[0].trim();
        awayToken = vsSplit.sublist(1).join(' ').trim();
      }
    }

    final normalizedComp = _normalizeCompetitionName(rawComp ?? rawTitle);
    final isKnownFootballComp = normalizedComp != null;

    if (!isKnownFootballComp && homeToken == null) {
      return (
        isFootball: false,
        competitionName: '',
        homeToken: null,
        awayToken: null,
      );
    }

    return (
      isFootball: true,
      competitionName: normalizedComp ?? (rawComp ?? 'Live Football'),
      homeToken: homeToken,
      awayToken: awayToken,
    );
  }

  static String? _normalizeCompetitionName(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('ucl') || lower.contains('uefa champions')) {
      return 'UEFA Champions League';
    }
    if (lower.contains('uecl') || lower.contains('conference league')) {
      return 'UEFA Conference League';
    }
    if (lower.contains('uel') || lower.contains('uefa europa') || lower.contains('europa league')) {
      return 'UEFA Europa League';
    }
    if (lower.contains('unl') || lower.contains('nations league')) {
      return 'UEFA Nations League';
    }
    if (lower.contains('premier league') || lower.contains('epl')) {
      return 'English Premier League';
    }
    if (lower.contains('laliga 2') || lower.contains('la liga 2')) {
      return 'Spanish LaLiga 2';
    }
    if (lower.contains('laliga') || lower.contains('la liga')) {
      return 'Spanish LaLiga';
    }
    if (lower.contains('serie a')) {
      return 'Italian Serie A';
    }
    if (lower.contains('bundesliga')) {
      return 'German Bundesliga';
    }
    if (lower.contains('ligue 1')) {
      return 'French Ligue 1';
    }
    if (lower.contains('super lig') || lower.contains('süper lig')) {
      return 'Turkish Süper Lig';
    }
    if (lower.contains('bri super league') ||
        lower.contains('bri liga 1') ||
        lower.contains('liga 1')) {
      return 'BRI Liga 1';
    }
    if (lower.contains('acl elite') || lower.contains('afc champions league elite')) {
      return 'AFC Champions League Elite';
    }
    if (lower.contains('acl two') || lower.contains('afc champions league two')) {
      return 'AFC Champions League Two';
    }
    if (lower.contains('afc') || lower.contains('asian cup')) {
      return 'AFC Football';
    }
    if (lower.contains('shopee cup') || lower.contains('asean club')) {
      return 'ASEAN Club Championship';
    }
    if (lower.contains('aff') || lower.contains('timnas')) {
      return 'Timnas Indonesia / AFF';
    }
    if (lower.contains('piala dunia u-17') || lower.contains('world cup u-17')) {
      return 'FIFA U-17 World Cup';
    }
    if (lower.contains('piala dunia') || lower.contains('world cup')) {
      return 'FIFA World Cup';
    }
    if (lower.contains('caf confed')) {
      return 'CAF Confederation Cup';
    }
    if (lower.contains('caf champions')) {
      return 'CAF Champions League';
    }
    if (lower.contains('pro futsal') || lower.contains('futsal')) {
      return 'Pro Futsal League Indonesia';
    }
    if (lower.contains('fa cup')) {
      return 'Emirates FA Cup';
    }
    if (lower.contains('copa del rey')) {
      return 'Copa del Rey';
    }
    return null;
  }

  /// Cross-matches currently airing [activeProgrammes] from EPG with in-progress
  /// [espnEvents] from ESPN Scoreboard, returning ONLY verified live matches
  /// and the exact channels currently broadcasting each match.
  static List<LiveFootballMatch> buildVerifiedLiveMatches({
    required List<EpgFootballProgramme> activeProgrammes,
    required List<EspnLiveSoccerEvent> espnEvents,
  }) {
    final verifiedMatches = <LiveFootballMatch>[];
    final usedEspnEventIds = <String>{};

    // 1. Group team-specific EPG programmes that refer to the exact same match
    // (e.g., "Olympiacos Vs Ac Milan" on SCTV.id and "UEL: OLY Vs MIL (L)" on beInSports3.id).
    final teamSpecificProgrammes = activeProgrammes.where((p) => p.hasTeams).toList();
    final genericProgrammes = activeProgrammes.where((p) => !p.hasTeams).toList();

    final groupedTeamProgrammes = <String, List<EpgFootballProgramme>>{};
    for (final prog in teamSpecificProgrammes) {
      final homeCanon = _canonicalTeamKey(prog.homeToken!);
      final awayCanon = _canonicalTeamKey(prog.awayToken!);
      final pairKey = '${homeCanon}__$awayCanon';
      groupedTeamProgrammes.putIfAbsent(pairKey, () => []).add(prog);
    }

    for (final entry in groupedTeamProgrammes.entries) {
      final group = entry.value;
      final firstProg = group.first;

      // Try to find a matching live ESPN event for this specific pair of teams.
      final matchedEspn = _findMatchingEspnEventForTeams(
        homeToken: firstProg.homeToken!,
        awayToken: firstProg.awayToken!,
        espnEvents: espnEvents,
      );

      // Only include a team-specific EPG programme if it either has an explicit
      // live indicator `(L)` / `- Live` OR matches a currently live (`state == 'in'`)
      // ESPN event (this prevents daytime replays without `(L)` from triggering).
      final isConfirmedLive =
          group.any((p) => p.hasExplicitLiveTag) || matchedEspn != null;
      if (!isConfirmedLive) continue;

      // Also attach any generic competition-only EPG programme on another channel
      // that matches this exact competition (only if that channel doesn't already
      // have its own team-specific programme).
      final matchingGenerics = genericProgrammes.where((g) {
        return g.competitionName == firstProg.competitionName;
      }).toList();

      final allProgsForMatch = [...group, ...matchingGenerics];
      final channelsAndInfo = _collectChannelsAndProgramInfo(allProgsForMatch);
      if (channelsAndInfo.channels.isEmpty) continue;

      if (matchedEspn != null) {
        usedEspnEventIds.add(matchedEspn.id);
        verifiedMatches.add(
          LiveFootballMatch(
            id: matchedEspn.id,
            competitionName: firstProg.competitionName.isNotEmpty
                ? firstProg.competitionName
                : matchedEspn.competitionName,
            homeTeamName: matchedEspn.homeName,
            homeTeamLogo: matchedEspn.homeLogo,
            homeScore: matchedEspn.homeScore,
            awayTeamName: matchedEspn.awayName,
            awayTeamLogo: matchedEspn.awayLogo,
            awayScore: matchedEspn.awayScore,
            statusDetail: matchedEspn.statusDetail,
            isLive: true,
            primaryChannel: channelsAndInfo.channels.first,
            alternateChannels: channelsAndInfo.channels.sublist(1),
            channelProgramInfo: channelsAndInfo.programInfo,
          ),
        );
      } else {
        final homeFullName = resolveTeamDisplayName(firstProg.homeToken!);
        final awayFullName = resolveTeamDisplayName(firstProg.awayToken!);
        final syntheticId =
            'epg_${firstProg.epgChannelId}_${_canonicalTeamKey(firstProg.homeToken!)}_${_canonicalTeamKey(firstProg.awayToken!)}';

        verifiedMatches.add(
          LiveFootballMatch(
            id: syntheticId,
            competitionName: firstProg.competitionName,
            homeTeamName: homeFullName,
            homeScore: '-',
            awayTeamName: awayFullName,
            awayScore: '-',
            statusDetail: firstProg.wibTimeWindow,
            isLive: true,
            primaryChannel: channelsAndInfo.channels.first,
            alternateChannels: channelsAndInfo.channels.sublist(1),
            channelProgramInfo: channelsAndInfo.programInfo,
          ),
        );
      }
    }

    // 2. Process remaining generic competition-only EPG programmes
    // (e.g. "BRI Super League 2026/27" on Indosiar.id or "UEFA Champions League (L)" on SCTV.id).
    final groupedGenerics = <String, List<EpgFootballProgramme>>{};
    for (final g in genericProgrammes) {
      groupedGenerics.putIfAbsent(g.competitionName, () => []).add(g);
    }

    for (final entry in groupedGenerics.entries) {
      final compName = entry.key;
      final progs = entry.value;
      final channelsAndInfo = _collectChannelsAndProgramInfo(progs);
      if (channelsAndInfo.channels.isEmpty) continue;

      // Find any unused live ESPN events belonging to this competition.
      final matchingEspnEvents = espnEvents.where((ev) {
        if (usedEspnEventIds.contains(ev.id)) return false;
        final evCompNorm = _normalizeCompetitionName(ev.competitionName) ?? ev.competitionName;
        return evCompNorm.toLowerCase() == compName.toLowerCase();
      }).toList();

      if (matchingEspnEvents.isNotEmpty) {
        for (final ev in matchingEspnEvents) {
          usedEspnEventIds.add(ev.id);
          verifiedMatches.add(
            LiveFootballMatch(
              id: ev.id,
              competitionName: compName,
              homeTeamName: ev.homeName,
              homeTeamLogo: ev.homeLogo,
              homeScore: ev.homeScore,
              awayTeamName: ev.awayName,
              awayTeamLogo: ev.awayLogo,
              awayScore: ev.awayScore,
              statusDetail: ev.statusDetail,
              isLive: true,
              primaryChannel: channelsAndInfo.channels.first,
              alternateChannels: channelsAndInfo.channels.sublist(1),
              channelProgramInfo: channelsAndInfo.programInfo,
            ),
          );
        }
      } else if (progs.any((p) => p.hasExplicitLiveTag) &&
          !verifiedMatches.any((m) => m.competitionName == compName)) {
        // Explicit live football/futsal competition broadcast without a specific team pair in EPG
        final firstProg = progs.first;
        verifiedMatches.add(
          LiveFootballMatch(
            id: 'epg_comp_${firstProg.epgChannelId}_${compName.hashCode}',
            competitionName: compName,
            homeTeamName: compName,
            homeScore: '-',
            awayTeamName: 'Siaran Langsung',
            awayScore: '-',
            statusDetail: firstProg.wibTimeWindow,
            isLive: true,
            primaryChannel: channelsAndInfo.channels.first,
            alternateChannels: channelsAndInfo.channels.sublist(1),
            channelProgramInfo: channelsAndInfo.programInfo,
          ),
        );
      }
    }

    return verifiedMatches;
  }

  static ({List<LiveTvChannel> channels, Map<String, String> programInfo})
  _collectChannelsAndProgramInfo(List<EpgFootballProgramme> programmes) {
    final channels = <LiveTvChannel>[];
    final programInfo = <String, String>{};

    for (final prog in programmes) {
      for (final ch in prog.cinevaChannels) {
        if (channels.every((c) => c.id != ch.id)) {
          channels.add(ch);
        }
        programInfo.putIfAbsent(ch.id, () => prog.formattedProgramInfo);
      }
    }

    return (channels: channels, programInfo: programInfo);
  }

  static EspnLiveSoccerEvent? _findMatchingEspnEventForTeams({
    required String homeToken,
    required String awayToken,
    required List<EspnLiveSoccerEvent> espnEvents,
  }) {
    for (final ev in espnEvents) {
      final directMatch =
          _teamMatchesToken(
            token: homeToken,
            teamName: ev.homeName,
            teamAbbr: ev.homeAbbreviation,
          ) &&
          _teamMatchesToken(
            token: awayToken,
            teamName: ev.awayName,
            teamAbbr: ev.awayAbbreviation,
          );
      if (directMatch) return ev;

      final swappedMatch =
          _teamMatchesToken(
            token: homeToken,
            teamName: ev.awayName,
            teamAbbr: ev.awayAbbreviation,
          ) &&
          _teamMatchesToken(
            token: awayToken,
            teamName: ev.homeName,
            teamAbbr: ev.homeAbbreviation,
          );
      if (swappedMatch) return ev;
    }
    return null;
  }

  static bool _teamMatchesToken({
    required String token,
    required String teamName,
    required String teamAbbr,
  }) {
    final cleanToken = token.trim().toUpperCase();
    final cleanAbbr = teamAbbr.trim().toUpperCase();
    if (cleanToken.isNotEmpty && cleanToken == cleanAbbr) {
      return true;
    }

    final tokenCanon = _canonicalTeamKey(token);
    final nameCanon = _canonicalTeamKey(teamName);
    if (tokenCanon.isEmpty || nameCanon.isEmpty) return false;

    if (tokenCanon == nameCanon ||
        nameCanon.contains(tokenCanon) ||
        tokenCanon.contains(nameCanon)) {
      return true;
    }

    return false;
  }

  /// Resolves a 3-letter EPG team code (e.g. `'CEL'`, `'OLY'`, `'MIL'`) or
  /// raw team name into a full readable display name.
  static String resolveTeamDisplayName(String token) {
    final trimmed = token.trim();
    final upper = trimmed.toUpperCase();
    if (_teamCodeDictionary.containsKey(upper)) {
      return _teamCodeDictionary[upper]!;
    }
    return trimmed;
  }

  static String _canonicalTeamKey(String tokenOrName) {
    final resolved = resolveTeamDisplayName(tokenOrName).toLowerCase();
    return resolved
        .replaceAll(RegExp(r'\b(fc|cf|sc|ac|afc|ud|cd|rcd|fk|sk|u-17|u17)\b'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  /// Parses an XMLTV timestamp (`YYYYMMDDHHMMSS +0700` or `YYYYMMDDHHMMSS +0000`)
  /// into a normalized UTC [DateTime].
  static DateTime? parseXmlTvTimestamp(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length < 14) return null;

    final year = int.tryParse(trimmed.substring(0, 4));
    final month = int.tryParse(trimmed.substring(4, 6));
    final day = int.tryParse(trimmed.substring(6, 8));
    final hour = int.tryParse(trimmed.substring(8, 10));
    final minute = int.tryParse(trimmed.substring(10, 12));
    final second = int.tryParse(trimmed.substring(12, 14));
    if (year == null ||
        month == null ||
        day == null ||
        hour == null ||
        minute == null ||
        second == null) {
      return null;
    }

    var dt = DateTime.utc(year, month, day, hour, minute, second);

    final rest = trimmed.substring(14).trim();
    if (rest.length >= 5 && (rest.startsWith('+') || rest.startsWith('-'))) {
      final sign = rest.startsWith('-') ? -1 : 1;
      final tzHours = int.tryParse(rest.substring(1, 3)) ?? 0;
      final tzMins = int.tryParse(rest.substring(3, 5)) ?? 0;
      final offset = Duration(hours: tzHours, minutes: tzMins);
      dt = sign > 0 ? dt.subtract(offset) : dt.add(offset);
    }

    return dt;
  }

  static String? _extractXmlAttribute(String tagHeader, String attrName) {
    final pattern = '$attrName="';
    final startIdx = tagHeader.indexOf(pattern);
    if (startIdx == -1) return null;
    final valStart = startIdx + pattern.length;
    final valEnd = tagHeader.indexOf('"', valStart);
    if (valEnd == -1) return null;
    return tagHeader.substring(valStart, valEnd);
  }

  static String? _extractXmlTagText(String innerXml, String tagName) {
    final openIdx = innerXml.indexOf('<$tagName');
    if (openIdx == -1) return null;
    final contentStart = innerXml.indexOf('>', openIdx);
    if (contentStart == -1) return null;
    final closeIdx = innerXml.indexOf('</$tagName>', contentStart);
    if (closeIdx == -1) return null;
    return innerXml.substring(contentStart + 1, closeIdx);
  }

  static String _unescapeXml(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  /// Parses an ESPN Soccer Scoreboard JSON response into [EspnLiveSoccerEvent] objects,
  /// returning only matches that have already started (`state == 'in'`).
  static List<EspnLiveSoccerEvent> parseEspnLiveEvents(
    Map<String, dynamic> json, {
    String? defaultCompetitionHint,
  }) {
    final events = json['events'];
    if (events is! List) return const [];

    String topLeagueName = defaultCompetitionHint ?? '';
    final leagues = json['leagues'];
    if (topLeagueName.isEmpty && leagues is List && leagues.isNotEmpty) {
      final firstLeague = leagues.first;
      if (firstLeague is Map) {
        topLeagueName =
            (firstLeague['name'] ?? firstLeague['shortName'] ?? '').toString();
      }
    }

    final liveEvents = <EspnLiveSoccerEvent>[];

    for (final rawEvent in events) {
      if (rawEvent is! Map) continue;
      final id = (rawEvent['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;

      final statusMap = rawEvent['status'];
      final typeMap = (statusMap is Map) ? statusMap['type'] : null;
      final state =
          ((typeMap is Map) ? typeMap['state'] : null)?.toString().toLowerCase() ??
          '';
      if (state != 'in') continue;

      final statusDetail =
          ((typeMap is Map)
                  ? (typeMap['shortDetail'] ?? typeMap['detail'] ?? 'LIVE')
                  : 'LIVE')
              .toString();

      final competitions = rawEvent['competitions'];
      if (competitions is! List || competitions.isEmpty) continue;
      final comp = competitions.first;
      if (comp is! Map) continue;

      final competitors = comp['competitors'];
      if (competitors is! List || competitors.length < 2) continue;

      Map? homeMap;
      Map? awayMap;
      for (final c in competitors) {
        if (c is! Map) continue;
        final homeAway = (c['homeAway'] ?? '').toString().toLowerCase();
        if (homeAway == 'home' && homeMap == null) {
          homeMap = c;
        } else if (homeAway == 'away' && awayMap == null) {
          awayMap = c;
        }
      }
      homeMap ??= competitors[0] as Map;
      awayMap ??= competitors[1] as Map;

      final homeTeam = (homeMap['team'] is Map) ? homeMap['team'] as Map : const {};
      final awayTeam = (awayMap['team'] is Map) ? awayMap['team'] as Map : const {};

      final homeName =
          (homeTeam['shortDisplayName'] ??
                  homeTeam['displayName'] ??
                  homeTeam['name'] ??
                  'Home')
              .toString();
      final awayName =
          (awayTeam['shortDisplayName'] ??
                  awayTeam['displayName'] ??
                  awayTeam['name'] ??
                  'Away')
              .toString();

      final homeAbbr = (homeTeam['abbreviation'] ?? '').toString();
      final awayAbbr = (awayTeam['abbreviation'] ?? '').toString();

      final homeLogo = (homeTeam['logo'] as String?)?.trim();
      final awayLogo = (awayTeam['logo'] as String?)?.trim();

      final homeScore = (homeMap['score'] ?? '0').toString();
      final awayScore = (awayMap['score'] ?? '0').toString();

      String competitionName = topLeagueName;
      if (competitionName.isEmpty) {
        final season = rawEvent['season'];
        if (season is Map && season['slug'] != null) {
          competitionName = _humanizeSlug(season['slug'].toString());
        }
      }
      if (competitionName.isEmpty) {
        competitionName = 'Live Football';
      }

      liveEvents.add(
        EspnLiveSoccerEvent(
          id: id,
          competitionName: competitionName,
          homeName: homeName,
          homeAbbreviation: homeAbbr,
          homeLogo: (homeLogo != null && homeLogo.isNotEmpty) ? homeLogo : null,
          homeScore: homeScore,
          awayName: awayName,
          awayAbbreviation: awayAbbr,
          awayLogo: (awayLogo != null && awayLogo.isNotEmpty) ? awayLogo : null,
          awayScore: awayScore,
          statusDetail: statusDetail,
        ),
      );
    }

    return liveEvents;
  }

  /// Parses an ESPN Soccer Scoreboard JSON response into [LiveFootballMatch] objects.
  /// If [activeProgrammes] is provided, only matches verified against those active
  /// EPG broadcasts are returned; otherwise falls back to [resolveBroadcastingChannels]
  /// for standalone unit tests.
  static List<LiveFootballMatch> parseEspnScoreboardJson(
    Map<String, dynamic> json, {
    String? defaultCompetitionHint,
    List<EpgFootballProgramme>? activeProgrammes,
  }) {
    final espnEvents = parseEspnLiveEvents(
      json,
      defaultCompetitionHint: defaultCompetitionHint,
    );
    if (activeProgrammes != null) {
      return buildVerifiedLiveMatches(
        activeProgrammes: activeProgrammes,
        espnEvents: espnEvents,
      );
    }

    return espnEvents.map((ev) {
      final mappedChannels = resolveBroadcastingChannels(
        competitionName: ev.competitionName,
        homeTeamName: ev.homeName,
        awayTeamName: ev.awayName,
      );
      return LiveFootballMatch(
        id: ev.id,
        competitionName: ev.competitionName,
        homeTeamName: ev.homeName,
        homeTeamLogo: ev.homeLogo,
        homeScore: ev.homeScore,
        awayTeamName: ev.awayName,
        awayTeamLogo: ev.awayLogo,
        awayScore: ev.awayScore,
        statusDetail: ev.statusDetail,
        isLive: true,
        primaryChannel: mappedChannels.primary,
        alternateChannels: mappedChannels.alternates,
      );
    }).toList();
  }

  /// Resolves static default broadcasting channels for a known competition/team
  /// when EPG XML is not supplied in unit tests.
  static ({LiveTvChannel primary, List<LiveTvChannel> alternates})
  resolveBroadcastingChannels({
    required String competitionName,
    required String homeTeamName,
    required String awayTeamName,
  }) {
    final compLower = competitionName.toLowerCase();
    final teamsLower = '$homeTeamName $awayTeamName'.toLowerCase();

    final bein1 = LiveTvChannelsData.findById('ch_bein_sports_1')!;
    final bein2 = LiveTvChannelsData.findById('ch_bein_sports_2')!;
    final bein3 = LiveTvChannelsData.findById('ch_bein_sports_3')!;
    final beinXtra = LiveTvChannelsData.findById('ch_bein_sports_xtra')!;
    final soccerCh = LiveTvChannelsData.findById('ch_soccer_channel')!;
    final fifa = LiveTvChannelsData.findById('ch_fifa_plus')!;
    final rmtv = LiveTvChannelsData.findById('ch_realmadrid_tv')!;
    final tvriSport = LiveTvChannelsData.findById('id_tvri_sport')!;
    final sctv = LiveTvChannelsData.findById('id_sctv')!;
    final indosiar = LiveTvChannelsData.findById('id_indosiar')!;
    final rcti = LiveTvChannelsData.findById('id_rcti')!;
    final inews = LiveTvChannelsData.findById('id_inews')!;

    if (teamsLower.contains('real madrid')) {
      return (primary: rmtv, alternates: [bein1, bein3]);
    }

    if (teamsLower.contains('indonesia') ||
        compLower.contains('afc') ||
        compLower.contains('asian') ||
        compLower.contains('asean') ||
        compLower.contains('aff')) {
      return (primary: rcti, alternates: [soccerCh, inews]);
    }

    if (compLower.contains('liga 1') ||
        compLower.contains('indonesia') ||
        teamsLower.contains('persib') ||
        teamsLower.contains('persija') ||
        teamsLower.contains('persebaya') ||
        teamsLower.contains('arema') ||
        teamsLower.contains('bali united')) {
      return (primary: indosiar, alternates: [soccerCh]);
    }

    if (compLower.contains('champions') ||
        compLower.contains('uefa') ||
        compLower.contains('europa') ||
        compLower.contains('premier league') ||
        compLower.contains('english')) {
      return (primary: sctv, alternates: [bein1, bein2, bein3, beinXtra]);
    }

    if (compLower.contains('fifa') || compLower.contains('world cup')) {
      return (primary: tvriSport, alternates: [fifa]);
    }

    return (primary: bein1, alternates: [bein2, bein3, soccerCh]);
  }

  static String _humanizeSlug(String slug) {
    final cleaned = slug.replaceAll('-', ' ').replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return 'Live Football';
    return cleaned
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
