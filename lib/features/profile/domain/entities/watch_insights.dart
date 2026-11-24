import 'dart:math' as math;
import '../../../../core/localization/app_language.dart';
import '../../../history/data/models/watch_history_item.dart';
import '../models/user_profile.dart';

/// Card visual style for the shareable KTP / ATM Member Card.
enum MemberCardStyle {
  ktp,
  atm,
}

/// Genre distribution slice for Cineva Insights DNA breakdown.
class GenreDistributionItem {
  final String labelId;
  final String labelEn;
  final String labelHi;
  final int count;
  final double percentage;

  const GenreDistributionItem({
    required this.labelId,
    required this.labelEn,
    required this.labelHi,
    required this.count,
    required this.percentage,
  });

  String localizedLabel(AppLanguage lang) {
    if (lang.isHindi) return labelHi;
    if (lang.isIndonesian) return labelId;
    return labelEn;
  }
}

/// Aggregated representation of a Movie or TV Series for the "Most Watched" leaderboard.
///
/// For TV Series, [totalWatchedMs] and [episodesCount] aggregate all watched episodes
/// across all seasons (including cumulative multi-season progress such as Season 1 -> Season 4).
class TopWatchedTitleItem {
  final int id;
  final String mediaType; // 'movie' or 'tv'
  final String title;
  final String? posterPath;
  final int totalWatchedMs;
  final int episodesCount;
  final int? latestSeason;
  final int? latestEpisode;

  const TopWatchedTitleItem({
    required this.id,
    required this.mediaType,
    required this.title,
    this.posterPath,
    required this.totalWatchedMs,
    this.episodesCount = 1,
    this.latestSeason,
    this.latestEpisode,
  });

  bool get isTv => mediaType == 'tv';
  int get totalMinutes => math.max(1, (totalWatchedMs / 60000).round());
  int get hours => totalMinutes ~/ 60;
  int get remainingMinutes => totalMinutes % 60;

  /// Formats aggregated watch duration (e.g. "20j 15m" or "1j 30m" or "45 mnt").
  String formattedDuration(AppLanguage lang, {double progressFactor = 1.0}) {
    final scaledMins = math.max(1, (totalMinutes * progressFactor).round());
    final h = scaledMins ~/ 60;
    final m = scaledMins % 60;

    if (lang.isHindi) {
      if (h == 0) return '$m मि';
      if (m == 0) return '$h घं';
      return '$hघं $mमि';
    }
    if (lang.isIndonesian) {
      if (h == 0) return '$m mnt';
      if (m == 0) return '${h}j';
      return '${h}j ${m}m';
    }
    if (h == 0) return '$m min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Formats subtitle showing multi-season progress & episode count for TV series.
  String formattedSubtitle(AppLanguage lang) {
    if (!isTv) {
      if (lang.isHindi) return 'फ़िल्म';
      return lang.isIndonesian ? 'Film' : 'Movie';
    }
    final s = latestSeason ?? 1;
    final e = latestEpisode ?? 1;
    final epLabel = lang.isHindi
        ? '$episodesCount एपिसोड'
        : (lang.isIndonesian
            ? '$episodesCount Episode'
            : '$episodesCount Episodes');

    if (s > 1) {
      return 'S1–S$s (E$e) • $epLabel';
    }
    return 'S$s • E$e • $epLabel';
  }
}

/// Comprehensive personal watch statistics and member card metadata.
class WatchInsights {
  final int totalWatchTimeMs;
  final int moviesWatchedCount;
  final int episodesWatchedCount;
  final int tvSeriesWatchedCount;
  final int completedTitlesCount;
  final int watchlistCount;
  final int completionRatePercent;
  final double averageRating;
  final int activeDaysCount;
  final int activeDaysStreak;

  /// Watch duration in minutes for Monday (index 0) through Sunday (index 6).
  final List<int> weeklyMinutesByWeekday;

  final int personaLevel; // 1..5
  final int nextLevelTargetHours;
  final double levelProgress; // 0.0..1.0

  final String ktpNikNumber;
  final String atmCardNumber;
  final String memberSinceYear;

  final List<GenreDistributionItem> topFlavors;
  final List<WatchHistoryItem> topWatchedItems;
  final List<TopWatchedTitleItem> topWatchedTitles;

  const WatchInsights({
    required this.totalWatchTimeMs,
    required this.moviesWatchedCount,
    required this.episodesWatchedCount,
    required this.tvSeriesWatchedCount,
    required this.completedTitlesCount,
    required this.watchlistCount,
    required this.completionRatePercent,
    required this.averageRating,
    required this.activeDaysCount,
    required this.activeDaysStreak,
    required this.weeklyMinutesByWeekday,
    required this.personaLevel,
    required this.nextLevelTargetHours,
    required this.levelProgress,
    required this.ktpNikNumber,
    required this.atmCardNumber,
    required this.memberSinceYear,
    required this.topFlavors,
    required this.topWatchedItems,
    this.topWatchedTitles = const [],
  });

  int get totalMinutes => (totalWatchTimeMs / 60000).round();
  int get totalHours => totalMinutes ~/ 60;
  int get remainingMinutes => totalMinutes % 60;
  double get totalHoursDecimal => totalWatchTimeMs / 3600000.0;
  int get totalTitlesAndEpisodes => moviesWatchedCount + episodesWatchedCount;

  /// Estimated cinema tickets saved (1 per movie + 1 per 3 episodes, minimum 1 if watched).
  int get estimatedTicketsSaved {
    final raw = moviesWatchedCount + (episodesWatchedCount / 3).ceil();
    if (raw == 0 && totalMinutes > 0) return 1;
    return raw;
  }

  /// Formatted total watch duration (e.g. "14j 25m", "14h 25m", "14घं 25मि").
  String formattedDurationCompact(
    AppLanguage lang, {
    double progressFactor = 1.0,
  }) {
    final scaledMinutes = (totalMinutes * progressFactor).round();
    final h = scaledMinutes ~/ 60;
    final m = scaledMinutes % 60;
    if (lang.isHindi) {
      if (h == 0) return '$m मि';
      return '$hघं $mमि';
    }
    if (lang.isIndonesian) {
      if (h == 0) return '$m mnt';
      return '${h}j ${m}m';
    }
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  /// Verbose watch duration for captions (e.g. "14 Jam 25 Menit").
  String formattedDurationVerbose(AppLanguage lang) {
    final h = totalHours;
    final m = remainingMinutes;
    if (lang.isHindi) {
      if (h == 0) return '$m मिनट';
      return '$h घंटे $m मिनट';
    }
    if (lang.isIndonesian) {
      if (h == 0) return '$m Menit';
      if (m == 0) return '$h Jam';
      return '$h Jam $m Menit';
    }
    if (h == 0) return '$m Minutes';
    if (m == 0) return '$h Hours';
    return '$h Hours $m Mins';
  }

  /// Localized humorous/prestigious Persona Rank Title.
  String personaTitle(AppLanguage lang) {
    switch (personaLevel) {
      case 1:
        if (lang.isHindi) return 'सिनेमा नवागंतुक';
        return lang.isIndonesian ? 'Warga Baru Bioskop' : 'Cinema Newcomer';
      case 2:
        if (lang.isHindi) return 'सोफ़ा सुपरस्टार';
        return lang.isIndonesian ? 'Pahlawan Rebahan' : 'Couch Potato Hero';
      case 3:
        if (lang.isHindi) return 'मिडनाइट बिंज एंबेसडर';
        return lang.isIndonesian
            ? 'Duta Maraton Malam'
            : 'Midnight Binge Ambassador';
      case 4:
        if (lang.isHindi) return 'प्राइवेट सिनेमा सुल्तान';
        return lang.isIndonesian
            ? 'Sultan Bioskop Pribadi'
            : 'Private Cinema Sultan';
      case 5:
      default:
        if (lang.isHindi) return '4K सिनेमा ग्रैंडमास्टर';
        return lang.isIndonesian
            ? 'Menteri Perrebahan & Sinema 4K'
            : 'Grandmaster of 4K Cinema';
    }
  }

  /// Localized witty description for the user's Persona Rank.
  String personaTagline(AppLanguage lang) {
    switch (personaLevel) {
      case 1:
        if (lang.isHindi) {
          return 'अभी सोफ़ा गर्म होना शुरू हुआ है, असली मैराथन बाकी है!';
        }
        return lang.isIndonesian
            ? 'Baru pemanasan rebahan, bantal sofa masih dingin.'
            : 'Just warming up the couch, the real marathon awaits.';
      case 2:
        if (lang.isHindi) {
          return 'एंड क्रेडिट खत्म होने से पहले सोफ़े से उठना सख्त मना है।';
        }
        return lang.isIndonesian
            ? 'Pantang beranjak dari kasur sebelum teks kredit akhir selesai.'
            : 'Never leaving the couch before the final end credits roll.';
      case 3:
        if (lang.isHindi) {
          return 'प्रसिद्ध आखिरी वाक्य: "बस एक और एपिसोड, इसके बाद पक्का सोऊंगा!"';
        }
        return lang.isIndonesian
            ? 'Kalimat andalan jam 2 pagi: "Satu episode lagi deh, janji tidur!"'
            : 'Famous 2 AM words: "Just one more episode, then I promise I\'ll sleep!"';
      case 4:
        if (lang.isHindi) {
          return 'कमरा अब आधिकारिक तौर पर प्राइवेट IMAX थिएटर में बदल चुका है।';
        }
        return lang.isIndonesian
            ? 'Kamar tidur sudah resmi beralih fungsi jadi studio IMAX pribadi.'
            : 'Bedroom has officially been upgraded into a private IMAX theater.';
      case 5:
      default:
        if (lang.isHindi) {
          return 'निर्देशक के शूटिंग करने से पहले ही प्लॉट ट्विस्ट भाँप लेने वाले लीजेंड!';
        }
        return lang.isIndonesian
            ? 'Legenda hidup perfilman—hapal plot twist bahkan sebelum sutradara syuting!'
            : 'Living cinema legend—predicts the plot twist before the director shoots it!';
    }
  }

  /// Next persona title for progress bar display.
  String nextPersonaTitle(AppLanguage lang) {
    if (personaLevel >= 5) {
      if (lang.isHindi) return 'अधिकतम स्तर (MAX LEVEL)';
      return lang.isIndonesian ? 'Level Maksimal Tercapai' : 'Max Level Reached';
    }
    final preview = WatchInsights(
      totalWatchTimeMs: totalWatchTimeMs,
      moviesWatchedCount: moviesWatchedCount,
      episodesWatchedCount: episodesWatchedCount,
      tvSeriesWatchedCount: tvSeriesWatchedCount,
      completedTitlesCount: completedTitlesCount,
      watchlistCount: watchlistCount,
      completionRatePercent: completionRatePercent,
      averageRating: averageRating,
      activeDaysCount: activeDaysCount,
      activeDaysStreak: activeDaysStreak,
      weeklyMinutesByWeekday: weeklyMinutesByWeekday,
      personaLevel: personaLevel + 1,
      nextLevelTargetHours: nextLevelTargetHours,
      levelProgress: levelProgress,
      ktpNikNumber: ktpNikNumber,
      atmCardNumber: atmCardNumber,
      memberSinceYear: memberSinceYear,
      topFlavors: topFlavors,
      topWatchedItems: topWatchedItems,
      topWatchedTitles: topWatchedTitles,
    );
    return preview.personaTitle(lang);
  }

  /// Generates 6 humorous, witty default social media captions in ID, EN, or HI
  /// inviting friends to download the Cineva app.
  List<String> generateHumorousCaptions({
    required AppLanguage lang,
    required UserProfile profile,
  }) {
    const downloadUrl = 'https://github.com/cineva-stream/Cineva/releases';
    final durationText = formattedDurationVerbose(lang);
    final persona = personaTitle(lang);
    final totalCount = totalTitlesAndEpisodes;
    final tickets = estimatedTicketsSaved;

    if (lang.isHindi) {
      return [
        'सिनेमा गणराज्य Cineva का आधिकारिक KTP (दर्शक पहचान पत्र) मिल गया! 🪪🎬 कुल सोफ़ा मैराथन: $durationText ($moviesWatchedCount फ़िल्में और $episodesWatchedCount एपिसोड)। वर्तमान पद: "$persona" 🏆। महंगे सब्सक्रिप्शन पर पैसे खर्च करने के बजाय Cineva पर आएं—हज़ारों फ़िल्में, वेब सीरीज़ और एनीमे 100% मुफ़्त और बिना किसी फालतू विज्ञापन के! अभी डाउनलोड करें: $downloadUrl 🚀🍿',
        'बैंक ATM कार्ड में बैलेंस कम ❌ Cineva ATM कार्ड में मूवी घंटों का बैलेंस फुल ✅💳 "$persona" के खिताब के साथ $durationText सिनेमा की दुनिया में बिताए! अगर आप भी मुफ़्त में HD फ़िल्में, K-Drama और Live TV देखना चाहते हैं, तो अभी Cineva इंस्टॉल करें: $downloadUrl 🔥🎥',
        'मेरे खाली समय की आधिकारिक ऑडिट रिपोर्ट 📊🍿: Cineva पर $durationText की स्ट्रीमिंग, $totalCount फ़िल्में/एपिसोड पूरे, और लगभग $tickets सिनेमा टिकटों की बचत! ऐप एकदम प्रीमियम है, ऑफ़लाइन डाउनलोड और Watch Party भी मुफ़्त है। अपना दर्शक कार्ड यहाँ बनाएं: $downloadUrl ✨🎬',
        'डॉक्टर ने आराम करने को कहा था, मैंने Cineva खोलकर $durationText फ़िल्में देख डालीं 😎🛋️। अब मेरा आधिकारिक दर्जा "$persona" है! बिना किसी मासिक शुल्क के अनलिमिटेड HD स्ट्रीमिंग के लिए Cineva डाउनलोड करें: $downloadUrl 🍿👑',
        '"बस एक एपिसोड और" कहते-कहते $durationText कब बीत गए पता ही नहीं चला 😂🎬! Cineva ने मुझे आधिकारिक तौर पर "$persona" घोषित कर दिया है। अपने दोस्तों के साथ मुफ़्त Watch Party करने के लिए यहाँ से ऐप डाउनलोड करें: $downloadUrl 🚀🎞️',
        'पेश है मेरा VIP Cineva Black ATM कार्ड 💳✨! इसमें पैसे नहीं, बल्कि $totalCount शानदार फ़िल्मों और सीरीज़ का अनुभव जमा है ($durationText)। मुफ़्त, तेज़ और विज्ञापन-मुक्त सिनेमा के लिए आज ही Cineva से जुड़ें: $downloadUrl 🍿🔥',
      ];
    }

    if (lang.isIndonesian) {
      return [
        'Resmi mengantongi KTP (Kartu Tanda Penonton) Republik Sinema Cineva! 🪪🎬 Total jam terbang rebahan produktif: $durationText ($moviesWatchedCount film & $episodesWatchedCount episode). Jabatan resmi saat ini: "$persona" 🏆. Daripada bayar langganan banyak aplikasi bikin dompet menangis, mending pindah ke Cineva — nonton ribuan film, drakor, anime & TV lokal 100% GRATIS tanpa iklan judol! Download di sini: $downloadUrl 🚀🍿',
        'Kartu ATM isi saldo ❌ Kartu ATM isi Jam Terbang Nonton Cineva ✅💳 Tercatat sudah $durationText menghilang dari peradaban demi menamatkan $totalCount tontonan dengan pangkat "$persona". Buat kaum rebahan elit yang mau nonton film & series HD gratis seumur hidup, wajib install Cineva sekarang! 👉 $downloadUrl 🔥🎥',
        'LPJ (Laporan Pertanggungjawaban) waktu luangku tahun ini 📊🍿: $durationText nonton di Cineva, hemat setara $tickets tiket bioskop, dan resmi menyandang gelar "$persona"! Aplikasinya gratis, desainnya mewah, bisa download offline & nobar Watch Party pula. Yuk cetak KTP Penontonmu sendiri di Cineva: $downloadUrl ✨🎬',
        'Kata dokter disuruh banyak istirahat, eh keterusan rebahan $durationText nonton di Cineva sampai dapet pangkat "$persona" 😎🛋️. Nonton film bioskop, anime & drakor subtitle Indonesia super ngebut tanpa biaya bulanan. Gas download Cineva: $downloadUrl 🍿👑',
        'Berawal dari kalimat "Satu episode lagi deh, janji tidur!", tahu-tahu sudah terkumpul $durationText ($totalCount tontonan) di Kartu ATM Cineva-ku 😂🎬. Yang belum punya KTP Penonton resmi dan mau streaming gratis tanpa batas, langsung meluncur ke: $downloadUrl 🚀🎞️',
        'Pamer kartu ATM saldo miliaran sudah biasa. Pamer Black Card Cineva dengan rekor $durationText nonton & gelar "$persona" baru luar biasa 💳✨! Bebas biaya langganan selamanya, tinggal duduk manis langsung play. Download aplikasinya di: $downloadUrl 🍿🔥',
      ];
    }

    return [
      'Officially received my Cinema ID Card (KTP) from the Republic of Cineva! 🪪🎬 Total productive couch time: $durationText ($moviesWatchedCount movies & $episodesWatchedCount episodes). Current official rank: "$persona" 🏆. Why pay for 5 different streaming subscriptions when Cineva gives you thousands of HD movies, anime, K-dramas & Live TV 100% FREE with zero annoying ads? Download here: $downloadUrl 🚀🍿',
      'Bank ATM card balance: questionable ❌ Cineva VIP Black ATM Card watch hours: legendary ✅💳 Officially logged $durationText in the cinema universe with the title "$persona". For fellow elite binge-watchers who want free HD movies & series forever, grab Cineva now! 👉 $downloadUrl 🔥🎥',
      'My official free-time audit report 📊🍿: $durationText streamed on Cineva, $totalCount titles/episodes watched, saving roughly $tickets movie tickets, and earning the rank "$persona"! Free offline downloads, Watch Party with friends, and a sleek UI. Mint your own Cinema ID Card on Cineva: $downloadUrl ✨🎬',
      'The doctor told me to get plenty of rest, so I spent $durationText binge-watching on Cineva and unlocked the "$persona" rank 😎🛋️. Unlimited HD movies, series & auto-translated subtitles without monthly fees. Download Cineva today: $downloadUrl 🍿👑',
      'It all started with "Just one more episode, I promise!" and now my Cineva ATM Card shows $durationText across $totalCount titles 😂🎬. Ready to ditch overpriced subscriptions? Join Cineva for free: $downloadUrl 🚀🎞️',
      'Flexing a bank card is temporary; flexing a Cineva VIP Black Card with $durationText of cinema wisdom and the "$persona" badge is eternal 💳✨! 100% free streaming across Mobile, Tablet, PC & Android TV. Get it here: $downloadUrl 🍿🔥',
    ];
  }
}
