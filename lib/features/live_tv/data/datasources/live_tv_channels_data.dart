import '../../domain/entities/live_tv_channel.dart';

/// Curated registry of public, verified, and free HLS live television broadcasts.
/// Includes Sports, News, Movies, Entertainment, Kids, Science, and Indonesian channels.
class LiveTvChannelsData {
  LiveTvChannelsData._();

  static const List<String> categories = [
    'Semua',
    'Olahraga',
    'Berita',
    'Film & Hiburan',
    'Indonesia',
    'Anak & Animasi',
    'Sains & Edukasi',
    'Musik',
  ];

  static const List<LiveTvChannel> defaultChannels = [
    // ── Olahraga (Sports) ──
    LiveTvChannel(
      id: 'ch_redbull_tv',
      name: 'Red Bull TV',
      category: 'Olahraga',
      streamUrl:
          'https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8',
      logoUrl:
          'https://images.redbull.com/images/w_800/q_auto,f_auto/redbullcom/2020/6/15/dsvff6w4g2z05ywh5m1l/red-bull-tv-logo',
      quality: 'FHD',
      country: 'Global',
      description: 'Extreme sports, live racing, skate, surf, and documentaries.',
    ),
    LiveTvChannel(
      id: 'ch_fight_sports',
      name: 'Fight Sports Max',
      category: 'Olahraga',
      streamUrl:
          'https://d18dyv90m90v1b.cloudfront.net/live/master.m3u8',
      quality: 'HD',
      country: 'Global',
      description: 'Championship boxing, MMA, kickboxing, and martial arts.',
    ),
    LiveTvChannel(
      id: 'ch_outdoor_sports',
      name: 'Outdoor Sports Channel',
      category: 'Olahraga',
      streamUrl:
          'https://playout.cdn.cartoonexpress.com/live/outdoorsport/playlist.m3u8',
      quality: 'HD',
      country: 'Global',
      description: 'Adventure, mountain biking, skiing, and water sports.',
    ),

    // ── Berita (News) ──
    LiveTvChannel(
      id: 'ch_aljazeera_en',
      name: 'Al Jazeera English',
      category: 'Berita',
      streamUrl:
          'https://live-hls-web-aje.getaj.net/AJE/03.m3u8',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/en/thumb/f/f2/Aljazeera_eng.svg/1200px-Aljazeera_eng.svg.png',
      quality: '1080p',
      country: 'Global',
      description: '24/7 breaking global news and in-depth investigative reports.',
    ),
    LiveTvChannel(
      id: 'ch_dw_en',
      name: 'DW News English',
      category: 'Berita',
      streamUrl:
          'https://dwamdstream102.akamaized.net/hls/live/2015525/dwstream102/index.m3u8',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/Deutsche_Welle_symbol_2012.svg/1200px-Deutsche_Welle_symbol_2012.svg.png',
      quality: '1080p',
      country: 'Germany / Global',
      description: 'German international news broadcaster covering international affairs.',
    ),
    LiveTvChannel(
      id: 'ch_france24_en',
      name: 'France 24 English',
      category: 'Berita',
      streamUrl:
          'https://f24hls-i.akamaihd.net/hls/live/221193/F24_EN_LO_HLS/master.m3u8',
      quality: '720p',
      country: 'France / Global',
      description: 'International news from a European and French perspective.',
    ),
    LiveTvChannel(
      id: 'ch_abc_news',
      name: 'ABC News Live',
      category: 'Berita',
      streamUrl:
          'https://content.uplynk.com/channel/3324f2467c414329b3b0cc5cd987b6be.m3u8',
      quality: '720p',
      country: 'USA',
      description: 'Live coverage of US and international news events.',
    ),
    LiveTvChannel(
      id: 'ch_euronews',
      name: 'Euronews English',
      category: 'Berita',
      streamUrl:
          'https://euronews-euronews-world-1-us.plex.tv/hls/master.m3u8',
      quality: 'HD',
      country: 'Europe',
      description: 'Independent news and insights from all across Europe.',
    ),
    LiveTvChannel(
      id: 'ch_bloomberg_quicktake',
      name: 'Bloomberg Quicktake',
      category: 'Berita',
      streamUrl:
          'https://bloomberg.com/media-manifest/streams/us.m3u8',
      quality: 'HD',
      country: 'Global',
      description: 'Business, global finance, markets, and technological innovation.',
    ),

    // ── Film & Hiburan (Movies & Entertainment) ──
    LiveTvChannel(
      id: 'ch_rakuten_action',
      name: 'Action Movies Live',
      category: 'Film & Hiburan',
      streamUrl:
          'https://rakuten-actionmovies-1-eu.rakuten.wurl.tv/playlist.m3u8',
      quality: 'HD',
      country: 'Europe',
      description: 'High-octane non-stop action movies, martial arts, and thrillers.',
    ),
    LiveTvChannel(
      id: 'ch_filmstream',
      name: 'Filmstream Channel',
      category: 'Film & Hiburan',
      streamUrl:
          'https://d35j504z0x2vu2.cloudfront.net/v1/master/0bc8e8376c3417e877079e73b3e286fa19e0494e/Filmstream/playlist.m3u8',
      quality: 'HD',
      country: 'Global',
      description: 'Award-winning independent cinema, arthouse, and classics.',
    ),
    LiveTvChannel(
      id: 'ch_dust_scifi',
      name: 'DUST Sci-Fi Channel',
      category: 'Film & Hiburan',
      streamUrl:
          'https://dust-dust-1-us.plex.tv/hls/master.m3u8',
      quality: 'HD',
      country: 'USA',
      description: 'Binge-worthy sci-fi movies, series, futuristic stories, and short films.',
    ),
    LiveTvChannel(
      id: 'ch_classic_cinema',
      name: 'Classic Cinema World',
      category: 'Film & Hiburan',
      streamUrl:
          'https://linear-417.frequency.stream/mt/studio/417/hls/master/playlist.m3u8',
      quality: 'HD',
      country: 'USA',
      description: 'Golden era cinema, vintage Hollywood, noir, and dramatic classics.',
    ),

    // ── Indonesia ──
    LiveTvChannel(
      id: 'ch_tvri_nasional',
      name: 'TVRI Nasional HD',
      category: 'Indonesia',
      streamUrl:
          'https://ott-linear.tvri.go.id/Content/HLS/Live/Channel(TVRINasional)/index.m3u8',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Logo_TVRI_2019.svg/1200px-Logo_TVRI_2019.svg.png',
      quality: '1080p',
      country: 'Indonesia',
      description: 'Saluran televisi publik resmi Republik Indonesia dengan siaran nasional.',
    ),
    LiveTvChannel(
      id: 'ch_tvri_world',
      name: 'TVRI World',
      category: 'Indonesia',
      streamUrl:
          'https://ott-linear.tvri.go.id/Content/HLS/Live/Channel(TVRIWorld)/index.m3u8',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Logo_TVRI_2019.svg/1200px-Logo_TVRI_2019.svg.png',
      quality: '1080p',
      country: 'Indonesia',
      description: 'Siaran berita, budaya, pariwisata, dan potensi Indonesia untuk dunia.',
    ),
    LiveTvChannel(
      id: 'ch_kompas_tv',
      name: 'Kompas TV HD',
      category: 'Indonesia',
      streamUrl:
          'https://video.kompas.com/live/kompastv/master.m3u8',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Kompas_TV_2018.svg/1200px-Kompas_TV_2018.svg.png',
      quality: '1080p',
      country: 'Indonesia',
      description: 'Inspirasi Indonesia, berita terkini, talkshow, dan investigasi mendalam.',
    ),
    LiveTvChannel(
      id: 'ch_beritasatu',
      name: 'BTV (BeritaSatu)',
      category: 'Indonesia',
      streamUrl:
          'https://edge.medialink.co.id/live/btv/index.m3u8',
      quality: 'HD',
      country: 'Indonesia',
      description: 'Saluran televisi informasi dan berita terpercaya Indonesia.',
    ),
    LiveTvChannel(
      id: 'ch_nusantara_tv',
      name: 'Nusantara TV',
      category: 'Indonesia',
      streamUrl:
          'https://live.nusantaratv.com/live/ntv/index.m3u8',
      quality: 'HD',
      country: 'Indonesia',
      description: 'Televisi digital swasta nasional dengan ragam program hiburan dan berita.',
    ),

    // ── Anak & Animasi (Kids & Animation) ──
    LiveTvChannel(
      id: 'ch_duck_tv',
      name: 'Duck TV Kids',
      category: 'Anak & Animasi',
      streamUrl:
          'https://ducktv-rakuten.amagi.tv/hls/amagi_hls_ducktv_rakuten/index.m3u8',
      quality: 'HD',
      country: 'Global',
      description: 'Educational and joyful animated series for toddlers and children.',
    ),
    LiveTvChannel(
      id: 'ch_cartoon_classics',
      name: 'Cartoon Classics',
      category: 'Anak & Animasi',
      streamUrl:
          'https://linear-416.frequency.stream/mt/studio/416/hls/master/playlist.m3u8',
      quality: 'HD',
      country: 'USA',
      description: 'Classic cartoons, Popeye, Betty Boop, Looney Tunes, and animated favorites.',
    ),

    // ── Sains & Edukasi (Science & Documentary) ──
    LiveTvChannel(
      id: 'ch_nasa_tv',
      name: 'NASA TV HD (Public)',
      category: 'Sains & Edukasi',
      streamUrl:
          'https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/NASA_logo.svg/1200px-NASA_logo.svg.png',
      quality: '1080p',
      country: 'USA',
      description: 'Live rocket launches, spacewalks, views from the ISS, and astrophysics.',
    ),
    LiveTvChannel(
      id: 'ch_wildearth',
      name: 'WildEarth Safari Live',
      category: 'Sains & Edukasi',
      streamUrl:
          'https://wildearth-samsungau.amagi.tv/playlist.m3u8',
      quality: 'HD',
      country: 'South Africa / Global',
      description: 'Live interactive wilderness safaris, wildlife tracking in African reserves.',
    ),

    // ── Musik (Music) ──
    LiveTvChannel(
      id: 'ch_clubbing_tv',
      name: 'Clubbing TV HD',
      category: 'Musik',
      streamUrl:
          'https://clubbingtv-rakuten.amagi.tv/playlist.m3u8',
      quality: '1080p',
      country: 'France / Global',
      description: 'Electronic music, DJ sets, festivals, and world-class club culture.',
    ),
  ];
}
