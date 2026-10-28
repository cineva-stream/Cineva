import '../../domain/entities/live_tv_channel.dart';

/// Curated registry of public, verified, and free HLS live television broadcasts.
/// Includes Indonesia, Sports, News, Movies & Entertainment, Kids, Science, and Music.
/// Every channel contains a verified stream URL and high-resolution logo.
class LiveTvChannelsData {
  LiveTvChannelsData._();

  static const List<String> categories = [
    'Semua',
    'Indonesia',
    'Olahraga',
    'Berita',
    'Film & Hiburan',
    'Anak & Animasi',
    'Sains & Edukasi',
    'Musik',
  ];

  static const List<LiveTvChannel> defaultChannels = [
    // ════════════════════════════════════════════════════════════════
    // 1. INDONESIA
    // ════════════════════════════════════════════════════════════════
    LiveTvChannel(
      id: 'id_tvri_nasional',
      name: 'TVRI Nasional',
      category: 'Indonesia',
      streamUrl: 'https://ott-balancer.tvri.go.id/live/eds/Nasional/hls/Nasional.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/TVRI_logo_2019.svg/512px-TVRI_logo_2019.svg.png',
      quality: '1080p',
      country: 'Indonesia',
      description: 'Saluran televisi nasional resmi Republik Indonesia menyajikan siaran publik terlengkap.',
    ),
    LiveTvChannel(
      id: 'id_tvri_world',
      name: 'TVRI World',
      category: 'Indonesia',
      streamUrl: 'https://ott-balancer.tvri.go.id/live/eds/TVRIWorld/hls/TVRIWorld.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c2/TVRI_World_logo_2020.svg/512px-TVRI_World_logo_2020.svg.png',
      quality: '1080p',
      country: 'Indonesia',
      description: 'Siaran internasional resmi dari TVRI menyajikan budaya, pariwisata, dan berita Nusantara.',
    ),
    LiveTvChannel(
      id: 'id_daai_tv',
      name: 'DAAI TV Indonesia',
      category: 'Indonesia',
      streamUrl: 'https://pull.daaiplus.com/live-DAAIPLUS/live-DAAIPLUS_HD.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Logo_DAAI_TV.png/512px-Logo_DAAI_TV.png',
      quality: 'HD',
      country: 'Indonesia',
      description: 'Televisi cinta kasih dengan tayangan edukasi, inspirasi, dan kemanusiaan.',
    ),
    LiveTvChannel(
      id: 'id_garuda_tv',
      name: 'Garuda TV',
      category: 'Indonesia',
      streamUrl: 'https://hgmtv.com:19360/garudatvlivestreaming/garudatvlivestreaming.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Garuda_TV_logo_2023.png/512px-Garuda_TV_logo_2023.png',
      quality: '1080p',
      country: 'Indonesia',
      description: 'Saluran televisi swasta nasional berita dan hiburan keluarga nusantara.',
    ),
    LiveTvChannel(
      id: 'id_indonesiana_tv',
      name: 'Indonesiana TV',
      category: 'Indonesia',
      streamUrl: 'https://tvstreamcast.com/indonesiana.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/db/Logo_Indonesiana_TV.png/512px-Logo_Indonesiana_TV.png',
      quality: '720p',
      country: 'Indonesia',
      description: 'Kanal kebudayaan dan seni tradisi nusantara dari Kemendikbudristek.',
    ),
    LiveTvChannel(
      id: 'id_albahjah_tv',
      name: 'Al-Bahjah TV',
      category: 'Indonesia',
      streamUrl: 'http://202.150.161.117:8000/play/AlBahjahTV',
      logoUrl: 'https://i.imgur.com/52dlDZk.png',
      quality: '1080p',
      country: 'Indonesia',
      description: 'Siaran dakwah, kajian Islam dan edukasi nilai-nilai kebaikan keluarga.',
    ),
    LiveTvChannel(
      id: 'id_ahsan_tv',
      name: 'Ahsan TV',
      category: 'Indonesia',
      streamUrl: 'https://5bf7b725107e5.streamlock.net/ahsantv/ahsantv/playlist.m3u8',
      logoUrl: 'https://i.imgur.com/dZdUbYd.png',
      quality: '720p',
      country: 'Indonesia',
      description: 'Kanal dakwah sunnah, tafsir Al-Quran dan inspirasi Islam sejuk.',
    ),
    LiveTvChannel(
      id: 'id_ashiil_tv',
      name: 'Ashiil TV',
      category: 'Indonesia',
      streamUrl: 'https://wahyu1ptv.pages.dev/AshiilTV-HD.m3u8',
      logoUrl: 'https://i.imgur.com/bTktkcr.png',
      quality: '720p',
      country: 'Indonesia',
      description: 'Saluran siaran dakwah dan kajian Islam komprehensif.',
    ),

    // ════════════════════════════════════════════════════════════════
    // 2. OLAHRAGA (SPORTS)
    // ════════════════════════════════════════════════════════════════
    LiveTvChannel(
      id: 'ch_redbull_tv',
      name: 'Red Bull TV',
      category: 'Olahraga',
      streamUrl: 'https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8',
      logoUrl: 'https://i.imgur.com/Lv53nh4.png',
      quality: '1080p',
      country: 'Global',
      description: 'Extreme sports, live racing, skate, surf, and action documentaries.',
    ),
    LiveTvChannel(
      id: 'ch_acc_sports',
      name: 'ACC Digital Network',
      category: 'Olahraga',
      streamUrl: 'https://raycom-accdn-firetv.amagi.tv/playlist.m3u8',
      logoUrl: 'https://i.imgur.com/V6Kaqha.png',
      quality: '1080p',
      country: 'USA',
      description: 'Live college basketball, football, highlights, and championship games.',
    ),
    LiveTvChannel(
      id: 'ch_aspor',
      name: 'A Spor HD',
      category: 'Olahraga',
      streamUrl: 'https://rnttwmjcin.turknet.ercdn.net/lcpmvefbyo/aspor/aspor.m3u8',
      logoUrl: 'https://i.imgur.com/ZhkZzLf.png',
      quality: '1080p',
      country: 'Europe',
      description: 'European football, premier league coverage, cup competitions and sports talk.',
    ),
    LiveTvChannel(
      id: 'ch_golf_kingdom',
      name: 'Golf Kingdom TV',
      category: 'Olahraga',
      streamUrl: 'https://30a-tv.com/feeds/vidaa/golf.m3u8',
      logoUrl: 'https://i.imgur.com/Lv53nh4.png',
      quality: '720p',
      country: 'USA',
      description: 'Championship golf tournaments, course guides, and pro masterclasses.',
    ),

    // ════════════════════════════════════════════════════════════════
    // 3. BERITA (NEWS)
    // ════════════════════════════════════════════════════════════════
    LiveTvChannel(
      id: 'ch_dw_en',
      name: 'DW News English',
      category: 'Berita',
      streamUrl: 'https://dwamdstream102.akamaized.net/hls/live/2015525/dwstream102/index.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/Deutsche_Welle_symbol_2012.svg/512px-Deutsche_Welle_symbol_2012.svg.png',
      quality: '1080p',
      country: 'Germany / Global',
      description: 'German international news broadcaster covering global events 24/7.',
    ),
    LiveTvChannel(
      id: 'ch_bloomberg',
      name: 'Bloomberg TV+',
      category: 'Berita',
      streamUrl: 'https://bloomberg.com/media-manifest/streams/us.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/56/Bloomberg_Television_logo.svg/512px-Bloomberg_Television_logo.svg.png',
      quality: '1080p',
      country: 'USA / Global',
      description: 'Global business, financial markets, tech stocks, and economic analysis.',
    ),
    LiveTvChannel(
      id: 'ch_3catinfo',
      name: '3CatInfo News',
      category: 'Berita',
      streamUrl: 'https://directes-tv-int.3catdirectes.cat/live-origin/canal324-hls/master.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/69/3CatInfo_logo.svg/960px-3CatInfo_logo.svg.png',
      quality: '1080p',
      country: 'Europe',
      description: 'European continuous breaking news and geopolitics network.',
    ),
    LiveTvChannel(
      id: 'ch_4sides_news',
      name: '4 SiDES TV News',
      category: 'Berita',
      streamUrl: 'https://stream.ottlive.co.in/4sidestv/index.m3u8',
      logoUrl: 'https://jiotvimages.cdn.jio.com/dare_images/images/4sites.png',
      quality: '1080p',
      country: 'Global',
      description: 'Worldwide current events, live reports, and multi-perspective headlines.',
    ),

    // ════════════════════════════════════════════════════════════════
    // 4. FILM & HIBURAN (MOVIES & SERIES)
    // ════════════════════════════════════════════════════════════════
    LiveTvChannel(
      id: 'ch_pluto_movies',
      name: 'Pluto TV Movies',
      category: 'Film & Hiburan',
      streamUrl: 'https://service-stitcher.clusters.pluto.tv/v1/stitch/embed/hls/channel/5d8bda705e4a86000966ffbd/master.m3u8?advertisingId=&appName=web&appVersion=unknown&appStoreUrl=&architecture=&buildVersion=&clientDeviceType=0&deviceDNT=0&deviceId=unknown&deviceMake=unknown&deviceModel=unknown&deviceType=unknown&deviceVersion=unknown&includeExtendedEvents=false&sid=unknown&userId=',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Pluto_TV_logo_2024.svg/512px-Pluto_TV_logo_2024.svg.png',
      quality: '1080p',
      country: 'USA',
      description: 'Blockbuster films, award-winning drama, and Hollywood favorites 24/7.',
    ),
    LiveTvChannel(
      id: 'ch_50cent_action',
      name: '50 Cent Action',
      category: 'Film & Hiburan',
      streamUrl: 'https://jmp2.uk/plu-68487fb3f212bedacf5a53e3.m3u8',
      logoUrl: 'https://provider-static.plex.tv/epg/cms/production/bcfb9977-809f-49ae-acc7-430f2c6ffb26/50CentAction_Logo_1500x1000_DarkBG_-_Chris_Connors.png',
      quality: '720p',
      country: 'USA',
      description: 'High-octane action movies, thrillers, and crime drama curated by 50 Cent.',
    ),
    LiveTvChannel(
      id: 'ch_4ever_cinema',
      name: '4ever Cinema HD',
      category: 'Film & Hiburan',
      streamUrl: 'http://stream.mcquack.net/258/index.m3u8',
      logoUrl: 'https://i.imgur.com/vFOgVbG.png',
      quality: '1080p',
      country: 'Global',
      description: 'Curated cinema channel streaming classic cinema and world films.',
    ),
    LiveTvChannel(
      id: 'ch_70s_cinema',
      name: '70s Cinema Channel',
      category: 'Film & Hiburan',
      streamUrl: 'https://jmp2.uk/plu-5f4d878d3d19b30007d2e782.m3u8',
      logoUrl: 'https://i.imgur.com/mgXeEE4.png',
      quality: '720p',
      country: 'USA',
      description: 'The golden age of Hollywood 1970s cult movies and classics.',
    ),
    LiveTvChannel(
      id: 'ch_00s_replay',
      name: '00s Replay',
      category: 'Film & Hiburan',
      streamUrl: 'https://jmp2.uk/plu-62ba60f059624e000781c436.m3u8',
      logoUrl: 'https://images.pluto.tv/channels/62ba60f059624e000781c436/colorLogoPNG.png',
      quality: '720p',
      country: 'USA',
      description: 'Popular 2000s series, comedies, and nostalgic entertainment.',
    ),

    // ════════════════════════════════════════════════════════════════
    // 5. ANAK & ANIMASI (KIDS)
    // ════════════════════════════════════════════════════════════════
    LiveTvChannel(
      id: 'ch_4fun_kids',
      name: '4 Fun Kids',
      category: 'Anak & Animasi',
      streamUrl: 'https://stream.4fun.tv:8889/hls/4fk.m3u8',
      logoUrl: 'https://i.imgur.com/2JO5Y8c.png',
      quality: 'HD',
      country: 'Global',
      description: 'Animated musical songs, fun cartoons, and educational kids programming.',
    ),
    LiveTvChannel(
      id: 'ch_3abn_kids',
      name: '3ABN Kids Network',
      category: 'Anak & Animasi',
      streamUrl: 'https://3abn.bozztv.com/3abn2/Kids_live/smil:Kids_live.smil/playlist.m3u8',
      logoUrl: 'https://i.imgur.com/z3npqO1.png',
      quality: '720p',
      country: 'USA',
      description: 'Wholesome family animations, nature discoveries, and children stories.',
    ),
    LiveTvChannel(
      id: 'ch_90s_kids',
      name: '90s Kids Toons',
      category: 'Anak & Animasi',
      streamUrl: 'https://jmp2.uk/plu-6452c814939a590008567a3b.m3u8',
      logoUrl: 'https://images.pluto.tv/channels/6452c814939a590008567a3b/colorLogoPNG_1731836283044.png',
      quality: '720p',
      country: 'USA',
      description: 'Retro Saturday morning cartoons and beloved 90s animation.',
    ),

    // ════════════════════════════════════════════════════════════════
    // 6. MUSIK (MUSIC)
    // ════════════════════════════════════════════════════════════════
    LiveTvChannel(
      id: 'ch_1hd_music',
      name: '1HD Music Television',
      category: 'Musik',
      streamUrl: 'http://176.118.197.101/1HD/index.m3u8',
      logoUrl: 'https://i.imgur.com/4Ww7CsR.png',
      quality: '1080p',
      country: 'Global',
      description: 'High definition international music videos, chart hits, and live DJ sets.',
    ),
    LiveTvChannel(
      id: 'ch_4ever_music',
      name: '4ever Music HD',
      category: 'Musik',
      streamUrl: 'http://stream.mcquack.net/257/index.m3u8',
      logoUrl: 'https://i.imgur.com/UJ5oaeU.png',
      quality: '1080p',
      country: 'Global',
      description: 'Non-stop music videos covering Pop, Rock, R&B, and electronic hits.',
    ),
    LiveTvChannel(
      id: 'ch_3abn_praise',
      name: '3ABN Praise Him Music',
      category: 'Musik',
      streamUrl: 'https://3abn.bozztv.com/3abn1/PraiseHim/smil:PraiseHim.smil/playlist.m3u8',
      logoUrl: 'https://i.imgur.com/iBcqT8L.png',
      quality: '720p',
      country: 'USA',
      description: 'Peaceful acoustic performances, orchestra, and inspiring vocals.',
    ),

    // ════════════════════════════════════════════════════════════════
    // 7. SAINS & EDUKASI (SCIENCE)
    // ════════════════════════════════════════════════════════════════
    LiveTvChannel(
      id: 'ch_nasa_tv',
      name: 'NASA TV Public',
      category: 'Sains & Edukasi',
      streamUrl: 'https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/NASA_logo.svg/512px-NASA_logo.svg.png',
      quality: '1080p',
      country: 'USA',
      description: 'Official NASA coverage of spacewalks, rocket launches, and ISS views.',
    ),
    LiveTvChannel(
      id: 'ch_discovery_science',
      name: 'Discovery Science',
      category: 'Sains & Edukasi',
      streamUrl: 'https://drk6xq0vhn.gpcdn.net/live/discovery_science_abr/index.m3u8',
      logoUrl: 'https://dtil.tmsimg.com/assets/s159107_ld_h15_aa.png?lock=720x540',
      quality: '720p',
      country: 'USA / Global',
      description: 'Deep dives into space, physics, engineering, and groundbreaking technology.',
    ),
    LiveTvChannel(
      id: 'ch_bfm_tech',
      name: 'BFM Tech & Co',
      category: 'Sains & Edukasi',
      streamUrl: 'https://ncdn-live-bfm.pfd.sfr.net/shls/LIVE\$BFM_TECHANDCO/index.m3u8?end=END&start=LIVE',
      logoUrl: 'https://i.imgur.com/FQ0FpXV.png',
      quality: '1080p',
      country: 'France / Europe',
      description: 'Live technology channel covering AI, digital innovation, and tech start-ups.',
    ),
    LiveTvChannel(
      id: 'ch_scifi',
      name: '.sci-fi Channel',
      category: 'Sains & Edukasi',
      streamUrl: 'http://stream.mcquack.net/180/index.m3u8',
      logoUrl: 'https://i.imgur.com/nSSUHcg.png',
      quality: 'HD',
      country: 'Global',
      description: 'Futuristic discoveries, astronomy documentaries, and science fiction.',
    ),
  ];
}
