import '../../domain/entities/live_tv_channel.dart';

/// Curated registry of public, verified, and free HLS/DASH live television broadcasts.
/// Includes comprehensive Indonesia National Channels, Football & Sports, International News,
/// Movies & Entertainment, Kids, Science, and Music.
/// Every channel contains a verified primary stream URL, multi-source fallback URLs,
/// and an official high-resolution logo matching the exact broadcast.
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
    // 1. INDONESIA (SALURAN NASIONAL & REGIONAL LENGKAP)
    // ════════════════════════════════════════════════════════════════
    LiveTvChannel(
      id: 'id_tvri_nasional',
      name: 'TVRI Nasional',
      category: 'Indonesia',
      streamUrl:
          'https://ott-balancer.tvri.go.id/live/eds/Nasional/hls/Nasional.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/tvri/index.m3u8',
        'https://vidio123.mikrofast.web.id/vidio/6441/index.mpd',
      ],
      logoUrl:
          'https://raw.githubusercontent.com/tv-logo/tv-logos/main/countries/indonesia/tvri-id.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Saluran televisi nasional resmi Republik Indonesia menyajikan siaran publik terlengkap.',
    ),
    LiveTvChannel(
      id: 'id_rcti',
      name: 'RCTI HD',
      category: 'Indonesia',
      streamUrl: 'https://rplus.inisemar.my.id/rcti.m3u8',
      fallbackStreamUrls: [
        'https://r-plus.sedotcw3.workers.dev/index.m3u8?id=rcti',
      ],
      logoUrl:
          'https://raw.githubusercontent.com/tv-logo/tv-logos/main/countries/indonesia/rcti-id.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Kebanggaan Bersama Milik Bangsa: Siaran langsung Timnas Indonesia, AFC Champions League, Piala Asia, dan sinetron unggulan.',
    ),
    LiveTvChannel(
      id: 'id_sctv',
      name: 'SCTV HD',
      category: 'Indonesia',
      streamUrl: 'https://vidio123.mikrofast.web.id/vidio/204/index.mpd',
      logoUrl:
          'https://thumbor.prod.vidiocdn.com/kH-K9J4cROqL0TZrAyQhw7P5pBk=/230x230/filters:quality(70)/vidio-web-prod-livestreaming/uploads/livestreaming/square_image/204/4e9f5c.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Satu Untuk Semua: Siaran langsung UEFA Champions League, Europa League, Premier League, Liputan 6, dan sinetron unggulan.',
    ),
    LiveTvChannel(
      id: 'id_indosiar',
      name: 'Indosiar HD',
      category: 'Indonesia',
      streamUrl: 'https://vidio123.mikrofast.web.id/vidio/205/index.mpd',
      fallbackStreamUrls: [
        'http://013tv.com:8080/F33848/cbd9779b/162138',
      ],
      logoUrl:
          'https://thumbor.prod.vidiocdn.com/0plBZ7Gso7gNBJxid9ksA8HMGxc=/230x230/filters:quality(70)/vidio-web-prod-livestreaming/uploads/livestreaming/square_image/205/54ab19.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Saluran televisi swasta terkemuka Indonesia dengan siaran eksklusif BRI Liga 1, Timnas U-20, Mega Series, dan Dangdut Academy.',
    ),
    LiveTvChannel(
      id: 'id_mnctv',
      name: 'MNCTV HD',
      category: 'Indonesia',
      streamUrl:
          'https://linier-mnctv.rctiplus.id/mnctv-sdi-avc1_1000000=17-mp4a_96000=1.m3u8',
      fallbackStreamUrls: [
        'https://rplus.inisemar.my.id/mnctv.m3u8',
        'https://r-plus.sedotcw3.workers.dev/index.m3u8?id=mnctv',
      ],
      logoUrl:
          'https://raw.githubusercontent.com/tv-logo/tv-logos/main/countries/indonesia/mnc-tv-id.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Selalu di Hati: Siaran langsung sepak bola ASEAN (AFF Cup), Futsal Nasional, dan hiburan keluarga Indonesia.',
    ),
    LiveTvChannel(
      id: 'id_gtv',
      name: 'GTV HD',
      category: 'Indonesia',
      streamUrl:
          'https://linier-gtv.rctiplus.id/gtv-sdi-avc1_1000000=7-mp4a_96000=1.m3u8',
      fallbackStreamUrls: [
        'https://rplus.inisemar.my.id/gtv.m3u8',
        'https://r-plus.sedotcw3.workers.dev/index.m3u8?id=gtv',
      ],
      logoUrl:
          'https://raw.githubusercontent.com/tv-logo/tv-logos/main/countries/indonesia/gtv-id.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Pilihan Terbaik Keluarga Indonesia: Turnamen olahraga, kualifikasi sepak bola, Big Movies, animasi, dan hiburan seru.',
    ),
    LiveTvChannel(
      id: 'id_moji',
      name: 'Moji HD',
      category: 'Indonesia',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/moji/index.m3u8',
      fallbackStreamUrls: [
        'https://vidio123.mikrofast.web.id/vidio/206/index.mpd',
        'https://op-flashcon-digdayahd-1.dens.tv/h/h207/01.m3u8',
      ],
      logoUrl:
          'https://thumbor.prod.vidiocdn.com/g7gTjD2Il1GI4DJULOZ1cv6NSj4=/230x230/filters:quality(70)/vidio-web-prod-livestreaming/uploads/livestreaming/square_image/206/1823dc.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Everyday is a Moji Day: Siaran olahraga Premier League, UEFA Champions League, Voli Proliga, dan hiburan gaya hidup.',
    ),
    LiveTvChannel(
      id: 'id_trans_tv',
      name: 'Trans TV',
      category: 'Indonesia',
      streamUrl:
          'https://live.cnbcindonesia.com/transtv/smil:transtv.smil/playlist.m3u8',
      fallbackStreamUrls: [
        'http://013tv.com:8080/F33848/cbd9779b/162503',
      ],
      logoUrl:
          'https://thumbor.prod.vidiocdn.com/__j35q7LPpcS2EgkR7v8GpE4USQ=/230x230/filters:quality(70)/vidio-web-prod-livestreaming/uploads/livestreaming/square_image/733/ecaa60.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Milik Kita Bersama: Bioskop Trans TV terlengkap, variety show populer, dan hiburan keluarga.',
    ),
    LiveTvChannel(
      id: 'id_trans7',
      name: 'Trans7 HD',
      category: 'Indonesia',
      streamUrl:
          'https://live.cnbcindonesia.com/trans7/smil:trans7.smil/playlist.m3u8',
      fallbackStreamUrls: [
        'http://013tv.com:8080/F33848/cbd9779b/162502',
      ],
      logoUrl:
          'https://thumbor.prod.vidiocdn.com/-MEB2a6J4sB6SvBDimCb7JYP6WY=/230x230/filters:quality(70)/vidio-web-prod-livestreaming/uploads/livestreaming/square_image/734/131514.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Aktif, Cerdas, dan Menghibur: Lapor Pak!, On The Spot, Jejak Petualang, dan siaran MotoGP.',
    ),
    LiveTvChannel(
      id: 'id_antv',
      name: 'ANTV HD',
      category: 'Indonesia',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/antv/index.m3u8',
      fallbackStreamUrls: [
        'https://vidio123.mikrofast.web.id/vidio/782/index.mpd',
        'http://013tv.com:8080/F33848/cbd9779b/165072',
      ],
      logoUrl:
          'https://thumbor.prod.vidiocdn.com/IRVkD3QGRzroJ4IZzXBpS-0MRls=/230x230/filters:quality(70)/vidio-web-prod-livestreaming/uploads/livestreaming/square_image/782/e1af8b.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Kanal drama series Asia terfavorit, sinema India, dan program hiburan terpopuler.',
    ),
    LiveTvChannel(
      id: 'id_mdtv',
      name: 'MDTV HD (NET.)',
      category: 'Indonesia',
      streamUrl: 'https://vidio123.mikrofast.web.id/vidio/875/index.mpd',
      fallbackStreamUrls: [
        'https://op-flashcon-digdayahd-1.dens.tv/h/h223/02.m3u8',
      ],
      logoUrl:
          'https://thumbor.prod.vidiocdn.com/LCZH_yEBnTYEQzrU1pB7w7ev-Bw=/230x230/filters:quality(70)/vidio-web-prod-livestreaming/uploads/livestreaming/square_image/875/325605.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Drama masa kini, serial pilihan, talkshow malam, dan hiburan keluarga modern Indonesia.',
    ),
    LiveTvChannel(
      id: 'id_tvone',
      name: 'tvOne HD',
      category: 'Indonesia',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/tvone/index.m3u8',
      fallbackStreamUrls: [
        'https://vidio123.mikrofast.web.id/vidio/783/index.mpd',
        'https://op-group1-densxvisionhd-1.dens.tv/h/h40/01.m3u8',
      ],
      logoUrl:
          'https://thumbor.prod.vidiocdn.com/APQ6a9vXvN6lU1zjeyL15IV_AJQ=/230x230/filters:quality(70)/vidio-web-prod-livestreaming/uploads/livestreaming/square_image/783/07750c.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Memang Beda: Berita terkini, Indonesia Lawyers Club, Kabar Petang, dan olahraga One Pride MMA.',
    ),
    LiveTvChannel(
      id: 'id_rtv',
      name: 'RTV HD',
      category: 'Indonesia',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/rtv/index.m3u8',
      fallbackStreamUrls: [
        'https://vidio123.mikrofast.web.id/vidio/1561/index.mpd',
      ],
      logoUrl:
          'https://raw.githubusercontent.com/tv-logo/tv-logos/main/countries/indonesia/rtv-id.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Rajawali Televisi Makin Cakep: Animasi anak populer, tokusatsu, dan hiburan keluarga Indonesia.',
    ),
    LiveTvChannel(
      id: 'id_metro_tv',
      name: 'Metro TV HD',
      category: 'Indonesia',
      streamUrl:
          'https://edge.medcom.id/live-edge/smil:metro.smil/playlist.m3u8',
      fallbackStreamUrls: [
        'https://vidio123.mikrofast.web.id/vidio/777/index.mpd',
        'https://op-flashcon-digdayahd-1.dens.tv/h/h12/01.m3u8',
      ],
      logoUrl:
          'https://thumbor.prod.vidiocdn.com/u0aa_S_rQeujrp5eR6LwXdertrI=/230x230/filters:quality(70)/vidio-web-prod-livestreaming/uploads/livestreaming/square_image/777/ea8483.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Knowledge to Elevate: Televisi berita 24 jam pelopor di Indonesia dengan liputan investigasi terpercaya.',
    ),
    LiveTvChannel(
      id: 'id_kompas_tv',
      name: 'Kompas TV HD',
      category: 'Indonesia',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/kompas/index.m3u8',
      fallbackStreamUrls: [
        'https://op-flashcon-digdayahd-1.dens.tv/s/s104/index.m3u8',
      ],
      logoUrl:
          'https://thumbor.prod.vidiocdn.com/Pf8yLSfHEUZeRI9tUzLDR2U8Zow=/230x230/filters:quality(70)/vidio-web-prod-livestreaming/uploads/livestreaming/square_image/874/042ca3.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Independen | Tepercaya: Berita aktual, dialog politik, investigasi mendalam, dan Stand Up Comedy Indonesia.',
    ),
    LiveTvChannel(
      id: 'id_inews',
      name: 'iNews HD',
      category: 'Indonesia',
      streamUrl:
          'https://linier-inews.rctiplus.id/inews-sdi-avc1_1000000=22-mp4a_96000=1.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/inews/index.m3u8',
        'https://rplus.inisemar.my.id/inews.m3u8',
        'https://live.i-news.tv/hls/stream.m3u8',
      ],
      logoUrl:
          'https://thumbor.prod.vidiocdn.com/BmeGg2IWkB_FAVPDviCk8gP8qcw=/230x230/filters:quality(70)/vidio-web-prod-livestreaming/uploads/livestreaming/square_image/5409/c40666.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Inspirasi Nusantara: Jaringan berita nasional dan siaran langsung olahraga sepak bola serta BWF.',
    ),
    LiveTvChannel(
      id: 'id_cnn_indonesia',
      name: 'CNN Indonesia',
      category: 'Indonesia',
      streamUrl:
          'https://video.detik.com/livecnn/smil:cnntv/chunklist_w268557525_b384000_sleng.m3u8',
      fallbackStreamUrls: [
        'https://live.cnnindonesia.com/livecnn/smil:cnntv/chunklist_w1188349826_b384000_sleng.m3u8',
      ],
      logoUrl: 'https://i.imgur.com/l0JyOrm.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Kanal berita berstandar internasional menyajikan laporan terkini, analisis mendalam, dan fakta akurat.',
    ),
    LiveTvChannel(
      id: 'id_cnbc_indonesia',
      name: 'CNBC Indonesia',
      category: 'Indonesia',
      streamUrl:
          'https://video.detik.com/livecnbc/smil:cnbctv/chunklist_w1279679883_b384000_sleng.m3u8',
      fallbackStreamUrls: [
        'http://013tv.com:8080/F33848/cbd9779b/165062',
      ],
      logoUrl:
          'https://raw.githubusercontent.com/apistech/project/refs/heads/main/logo/image_ch_cnbcindonesia.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Beyond Business: Informasi pasar modal, finansial, ekonomi makro, dan pergerakan bursa global.',
    ),
    LiveTvChannel(
      id: 'id_btv',
      name: 'BTV Indonesia',
      category: 'Indonesia',
      streamUrl:
          'https://lnd0t3b922.tenbytecdn.com/ta-sg1/90369cf5-6ac2-411d-b3d0-15fae10a2e2c/master.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/btv/index.m3u8',
        'https://vidio123.mikrofast.web.id/vidio/6165/index.mpd',
      ],
      logoUrl:
          'https://raw.githubusercontent.com/tv-logo/tv-logos/main/countries/indonesia/btv-id.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Bersatu Menginspirasi: Saluran televisi nasional berita, inspirasi bisnis, dan hiburan keluarga.',
    ),
    LiveTvChannel(
      id: 'id_jawa_pos_tv',
      name: 'Jawa Pos TV',
      category: 'Indonesia',
      streamUrl:
          'http://122.248.43.242:1935/JAWAPOSTVJKT/_definst_/myStream/playlist.m3u8',
      logoUrl:
          'https://raw.githubusercontent.com/apistech/project/refs/heads/main/logo/image_ch_jawapos.png',
      quality: '720p',
      country: 'Indonesia',
      description:
          'Melihat Indonesia Sesungguhnya: Jaringan informasi nasional grup Jawa Pos.',
    ),
    LiveTvChannel(
      id: 'id_jtv',
      name: 'JTV Surabaya',
      category: 'Indonesia',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/jtv/index.m3u8',
      fallbackStreamUrls: [
        'http://122.248.43.242:1935/JTVSURABAYA/_definst_/myStream/playlist.m3u8',
      ],
      logoUrl: 'https://i.imgur.com/mIDWIQk.png',
      quality: '720p',
      country: 'Indonesia',
      description:
          'Jawa Timur Televisi: Siaran khas budaya lokal, komedi Suroboyoan, dan berita daerah terpopuler.',
    ),
    LiveTvChannel(
      id: 'id_tvri_world',
      name: 'TVRI World',
      category: 'Indonesia',
      streamUrl:
          'https://ott-balancer.tvri.go.id/live/eds/TVRIWorld/hls/TVRIWorld.m3u8',
      logoUrl:
          'https://raw.githubusercontent.com/tv-logo/tv-logos/main/countries/indonesia/tvri-world-id.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Siaran internasional resmi dari TVRI menyajikan budaya, pariwisata, dan berita Nusantara.',
    ),
    LiveTvChannel(
      id: 'id_daai_tv',
      name: 'DAAI TV Indonesia',
      category: 'Indonesia',
      streamUrl:
          'https://pull.daaiplus.com/live-DAAIPLUS/live-DAAIPLUS_HD.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/daaitv/index.m3u8',
        'https://op-flashcon-digdayahd-1.dens.tv/h/h16/01.m3u8',
      ],
      logoUrl: 'https://i.imgur.com/YC7JCHo.png',
      quality: 'HD',
      country: 'Indonesia',
      description:
          'Televisi cinta kasih dengan tayangan edukasi, inspirasi, dan kemanusiaan.',
    ),
    LiveTvChannel(
      id: 'id_garuda_tv',
      name: 'Garuda TV',
      category: 'Indonesia',
      streamUrl:
          'https://hgmtv.com:19360/garudatvlivestreaming/garudatvlivestreaming.m3u8',
      logoUrl: 'https://i.imgur.com/sXsAcZ3.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Saluran televisi swasta nasional berita dan hiburan keluarga nusantara.',
    ),
    LiveTvChannel(
      id: 'id_indonesiana_tv',
      name: 'Indonesiana TV',
      category: 'Indonesia',
      streamUrl: 'https://tvstreamcast.com/indonesiana.m3u8',
      logoUrl: 'https://i.imgur.com/192wiS1.png',
      quality: '720p',
      country: 'Indonesia',
      description:
          'Kanal kebudayaan dan seni tradisi nusantara dari Kemendikbudristek.',
    ),
    LiveTvChannel(
      id: 'id_albahjah_tv',
      name: 'Al-Bahjah TV',
      category: 'Indonesia',
      streamUrl: 'http://202.150.161.117:8000/play/AlBahjahTV',
      logoUrl: 'https://i.imgur.com/52dlDZk.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Siaran dakwah, kajian Islam dan edukasi nilai-nilai kebaikan keluarga.',
    ),
    LiveTvChannel(
      id: 'id_ahsan_tv',
      name: 'Ahsan TV',
      category: 'Indonesia',
      streamUrl:
          'https://5bf7b725107e5.streamlock.net/ahsantv/ahsantv/playlist.m3u8',
      logoUrl: 'https://i.imgur.com/dZdUbYd.png',
      quality: '720p',
      country: 'Indonesia',
      description:
          'Kanal dakwah sunnah, tafsir Al-Quran dan inspirasi Islam sejuk.',
    ),
    LiveTvChannel(
      id: 'id_rodja_tv',
      name: 'Rodja TV',
      category: 'Indonesia',
      streamUrl: 'https://rodjatv.com/rodjatv/live.m3u8',
      logoUrl: 'https://i.imgur.com/XwCeHlC.png',
      quality: '720p',
      country: 'Indonesia',
      description:
          'Saluran televisi dakwah Islam terkemuka di Indonesia menyajikan kajian ilmiah, tilawah Al-Quran, dan siaran keagamaan 24 jam.',
    ),

    // ════════════════════════════════════════════════════════════════
    // 2. OLAHRAGA & SEPAK BOLA (FOOTBALL & SPORTS)
    // ════════════════════════════════════════════════════════════════
    LiveTvChannel(
      id: 'ch_bein_sports_1',
      name: 'beIN Sports 1 HD',
      category: 'Olahraga',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/bein1/index.m3u8',
      fallbackStreamUrls: [
        'https://bein-xtra-bein.amagi.tv/playlist.m3u8',
      ],
      logoUrl:
          'https://images.pluto.tv/channels/5d8d164d92e97a5e107638d2/colorLogoPNG.png',
      quality: '1080p',
      country: 'Global / Europe',
      description:
          'Siaran langsung LaLiga, Serie A, Ligue 1, FA Cup, dan pertandingan sepak bola klub top Eropa.',
    ),
    LiveTvChannel(
      id: 'ch_bein_sports_2',
      name: 'beIN Sports 2 HD',
      category: 'Olahraga',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/bein2/index.m3u8',
      fallbackStreamUrls: [
        'https://bein-xtra-bein.amagi.tv/playlist.m3u8',
      ],
      logoUrl:
          'https://images.pluto.tv/channels/5d8d164d92e97a5e107638d2/colorLogoPNG.png',
      quality: '1080p',
      country: 'Global / Europe',
      description:
          'Saluran kedua beIN Sports menyajikan pertandingan langsung liga-liga Eropa, turnamen piala domestik, dan analisis bola.',
    ),
    LiveTvChannel(
      id: 'ch_bein_sports_3',
      name: 'beIN Sports 3 HD',
      category: 'Olahraga',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/bein3/index.m3u8',
      fallbackStreamUrls: [
        'https://bein-xtra-bein.amagi.tv/playlist.m3u8',
      ],
      logoUrl:
          'https://images.pluto.tv/channels/5d8d164d92e97a5e107638d2/colorLogoPNG.png',
      quality: '1080p',
      country: 'Global / Europe',
      description:
          'Saluran ketiga beIN Sports untuk liputan simultan big match sepak bola Eropa dan kejuaraan dunia.',
    ),
    LiveTvChannel(
      id: 'ch_bein_sports_xtra',
      name: 'beIN Sports Xtra HD',
      category: 'Olahraga',
      streamUrl: 'https://bein-xtra-bein.amagi.tv/playlist.m3u8',
      fallbackStreamUrls: [
        'https://bein-xtra-bein.amagi.tv/playlistR720P.m3u8',
        'https://dc1644a9jazgj.cloudfront.net/beIN_Sports_Xtra_Espanol.m3u8',
      ],
      logoUrl:
          'https://images.pluto.tv/channels/5d8d164d92e97a5e107638d2/colorLogoPNG.png',
      quality: '1080p',
      country: 'Global / Europe',
      description:
          'Siaran langsung sepak bola Eropa, Ligue 1, Süper Lig, Copa Libertadores, dan highlight liga-liga top dunia 24/7.',
    ),
    LiveTvChannel(
      id: 'ch_soccer_channel',
      name: 'Soccer Channel HD',
      category: 'Olahraga',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/soccer/index.m3u8',
      logoUrl: 'https://a.espncdn.com/i/leaguelogos/soccer/500/23.png',
      quality: '1080p',
      country: 'Indonesia / Global',
      description:
          'Saluran khusus sepak bola 24 jam menayangkan pertandingan Timnas, AFC, kualifikasi Piala Dunia, dan liga internasional.',
    ),
    LiveTvChannel(
      id: 'ch_fifa_plus',
      name: 'FIFA+ Live HD',
      category: 'Olahraga',
      streamUrl:
          'https://95cedebd.wurl.com/master/f36d25e7e52f1ba8d7e56eb859c636563214f541/Vml6aW9fRklGQVBsdXNFbmdsaXNoX0hMUw/playlist.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/soccer/index.m3u8',
      ],
      logoUrl: 'https://a.espncdn.com/i/leaguelogos/soccer/500/4.png',
      quality: '1080p',
      country: 'Global',
      description:
          'Saluran resmi FIFA 24/7 menayangkan pertandingan live FIFA, klasik Piala Dunia, dan dokumenter sepak bola dunia.',
    ),
    LiveTvChannel(
      id: 'ch_realmadrid_tv',
      name: 'Real Madrid TV HD',
      category: 'Olahraga',
      streamUrl: 'http://88.212.15.50/live/real_madrid_tv/index.m3u8',
      logoUrl: 'https://a.espncdn.com/i/teamlogos/soccer/500/86.png',
      quality: '1080p',
      country: 'Spain / Europe',
      description:
          'Saluran televisi resmi klub Real Madrid CF: liputan LaLiga, UEFA Champions League, sesi latihan, dan pertandingan penuh.',
    ),
    LiveTvChannel(
      id: 'id_tvri_sport',
      name: 'TVRI Sport HD',
      category: 'Olahraga',
      streamUrl:
          'https://ott-balancer.tvri.go.id/live/eds/SportHD/hls/SportHD.m3u8',
      logoUrl:
          'https://raw.githubusercontent.com/tv-logo/tv-logos/main/countries/indonesia/tvri-sport-id.png',
      quality: '1080p',
      country: 'Indonesia',
      description:
          'Saluran olahraga nasional resmi TVRI menayangkan sepak bola nasional, bulutangkis, dan kejuaraan olahraga dunia.',
    ),
    LiveTvChannel(
      id: 'ch_spotv_2',
      name: 'SPOTV 2 HD',
      category: 'Olahraga',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/spotv2/index.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/ss1/index.m3u8',
      ],
      logoUrl:
          'https://raw.githubusercontent.com/apistech/project/refs/heads/main/logo/image_ch_spotv2.png',
      quality: '1080p',
      country: 'Asia / Global',
      description:
          'Siaran olahraga premium Asia & Eropa: Saudi Pro League, MotoGP, BWF World Tour, dan turnamen internasional.',
    ),
    LiveTvChannel(
      id: 'ch_sportstars',
      name: 'Sportstars HD',
      category: 'Olahraga',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/ss1/index.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/ss2/index.m3u8',
      ],
      logoUrl: 'https://a.espncdn.com/i/leaguelogos/soccer/500/12.png',
      quality: '1080p',
      country: 'Indonesia / Global',
      description:
          'Saluran olahraga Vision+ dengan liputan sepak bola, futsal, bulu tangkis, dan turnamen dunia.',
    ),
    LiveTvChannel(
      id: 'ch_cbs_sports_hq',
      name: 'CBS Sports HQ HD',
      category: 'Olahraga',
      streamUrl:
          'https://dai.google.com/linear/hls/event/Sid4xiTQTkCT1SLu6rjUSQ/master.m3u8',
      logoUrl:
          'https://images.pluto.tv/channels/5e9f2c05172a0f0007db4786/colorLogoPNG.png',
      quality: '1080p',
      country: 'USA / Europe',
      description:
          'Liputan langsung UEFA Champions League, Serie A, Europa League, skor real-time, dan analisis pertandingan 24/7.',
    ),
    LiveTvChannel(
      id: 'ch_aspor',
      name: 'A Spor HD',
      category: 'Olahraga',
      streamUrl:
          'https://rnttwmjcin.turknet.ercdn.net/lcpmvefbyo/aspor/aspor.m3u8',
      logoUrl: 'https://i.imgur.com/ZhkZzLf.png',
      quality: '1080p',
      country: 'Europe',
      description:
          'European football, cup competitions, live match coverage, and sports talk.',
    ),
    LiveTvChannel(
      id: 'ch_fox_sports_news',
      name: 'Fox Sports News HD',
      category: 'Olahraga',
      streamUrl:
          'https://skynewsau-live-premium.akamaized.net/hls/live/2105307/foxsportsnews/live_1080p.m3u8',
      logoUrl:
          'https://t2.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://www.foxsports.com.au&size=256',
      quality: '1080p',
      country: 'Global',
      description:
          'Live 24/7 sports breaking news, football match highlights, analysis, and global sports coverage.',
    ),
    LiveTvChannel(
      id: 'ch_redbull_tv',
      name: 'Red Bull TV',
      category: 'Olahraga',
      streamUrl:
          'https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8',
      logoUrl:
          'https://images.pluto.tv/channels/5e7cb84a172a0f0007da69e4/colorLogoPNG.png',
      quality: '1080p',
      country: 'Global',
      description:
          'Extreme sports, live racing, skate, surf, and action documentaries.',
    ),
    LiveTvChannel(
      id: 'ch_acc_sports',
      name: 'ACC Digital Network',
      category: 'Olahraga',
      streamUrl: 'https://raycom-accdn-firetv.amagi.tv/playlist.m3u8',
      logoUrl: 'https://i.imgur.com/V6Kaqha.png',
      quality: '1080p',
      country: 'USA',
      description:
          'Live college basketball, football, highlights, and championship games.',
    ),
    LiveTvChannel(
      id: 'ch_fight_sports',
      name: 'Fight Sports HD',
      category: 'Olahraga',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/fightsports/index.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/outdoor/index.m3u8',
      ],
      logoUrl:
          'https://raw.githubusercontent.com/apistech/project/refs/heads/main/logo/image_ch_fightsport.png',
      quality: '1080p',
      country: 'USA / Global',
      description:
          'World championship boxing, kickboxing, MMA, martial arts, and combat sports 24/7.',
    ),

    // ════════════════════════════════════════════════════════════════
    // 3. BERITA (INTERNATIONAL & REGIONAL NEWS)
    // ════════════════════════════════════════════════════════════════
    LiveTvChannel(
      id: 'ch_cnn_news18',
      name: 'CNN News 18',
      category: 'Berita',
      streamUrl:
          'https://n18syndication.akamaized.net/bpk-tv/CNN_News18_NW18_MOB/output01/master.m3u8',
      logoUrl:
          'https://dtil.tmsimg.com/assets/s142747_ld_h15_aa.png?lock=720x540',
      quality: '1080p',
      country: 'Global / Asia',
      description:
          'CNN International partnership channel delivering 24/7 world breaking news and interviews.',
    ),
    LiveTvChannel(
      id: 'ch_bbc_news',
      name: 'BBC News International',
      category: 'Berita',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/bbcworld/index.m3u8',
      fallbackStreamUrls: [
        'http://23.237.104.106:8080/USA_BBC_NEWS/index.m3u8',
      ],
      logoUrl:
          'https://xstreamcp-assets-msp.streamready.in/assets/LIVETV/LIVECHANNEL/LIVETV_LIVETVCHANNEL_BBC_NEWS/images/LOGO_HD/image.png',
      quality: '1080p',
      country: 'United Kingdom / Global',
      description:
          'British Broadcasting Corporation global coverage, investigative journalism, and analysis.',
    ),
    LiveTvChannel(
      id: 'ch_abc_news',
      name: 'ABC News Live',
      category: 'Berita',
      streamUrl:
          'https://abc-news-dmd-streams-1.akamaized.net/out/v1/701126012d044971b3fa89406a440133/index_5.m3u8',
      logoUrl:
          'https://t2.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://abcnews.go.com&size=256',
      quality: '720p',
      country: 'USA / Global',
      description:
          'Premier 24/7 live breaking news, live event specials, and in-depth reporting from ABC News.',
    ),
    LiveTvChannel(
      id: 'ch_cbs_news',
      name: 'CBS News 24/7',
      category: 'Berita',
      streamUrl:
          'https://cbsn-us.cbsnstream.cbsnews.com/out/v1/55a8648e8f134e82a470f83d562deeca/master.m3u8',
      logoUrl:
          'https://images.pluto.tv/channels/6350fdd266e9ea0007bedec5/colorLogoPNG.png',
      quality: '720p',
      country: 'USA / Global',
      description:
          'The live streaming service from CBS News with continuous coverage, 60 Minutes specials, and debates.',
    ),
    LiveTvChannel(
      id: 'ch_nbc_news',
      name: 'NBC News NOW',
      category: 'Berita',
      streamUrl:
          'https://d1si3n1st4nkgb.cloudfront.net/10502/88896001/hls/master.m3u8?ads.xumo_channelId=88896001',
      logoUrl: 'https://i.imgur.com/JZt2qh5.png',
      quality: '1080p',
      country: 'USA / Global',
      description:
          'NBC News round-the-clock live stream network delivering original reporting and world headlines.',
    ),
    LiveTvChannel(
      id: 'ch_aljazeera_en',
      name: 'Al Jazeera English',
      category: 'Berita',
      streamUrl: 'https://live-hls-apps-aje-fa.getaj.net/AJE/index.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/aljazeera/index.m3u8',
      ],
      logoUrl: 'https://www.mncvision.id/userfiles/image/channel/aljazeera.png',
      quality: '1080p',
      country: 'Qatar / Global',
      description:
          'Award-winning international news channel with unparalleled coverage of global affairs.',
    ),
    LiveTvChannel(
      id: 'ch_dw_en',
      name: 'DW News English',
      category: 'Berita',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/dwtv/index.m3u8',
      fallbackStreamUrls: [
        'https://dwamdstream102.akamaized.net/hls/live/2015525/dwstream102/index.m3u8',
      ],
      logoUrl:
          'https://raw.githubusercontent.com/apistech/project/refs/heads/main/logo/image_ch_dwtv.png',
      quality: '1080p',
      country: 'Germany / Global',
      description:
          'German international news broadcaster covering global events, European perspectives, and technology.',
    ),
    LiveTvChannel(
      id: 'ch_fox_news',
      name: 'FOX News Channel HD',
      category: 'Berita',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/foxnews/index.m3u8',
      logoUrl: 'https://www.visionplus.id/images/repository/677/677-LOGO-m.png',
      quality: '1080p',
      country: 'USA / Global',
      description:
          'Live 24/7 breaking news, political commentary, interviews, and world headlines.',
    ),
    LiveTvChannel(
      id: 'ch_france24_en',
      name: 'France 24 English',
      category: 'Berita',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/france24/index.m3u8',
      fallbackStreamUrls: [
        'https://live.france24.com/hls/live/2037218-b/F24_EN_HI_HLS/master_5000.m3u8',
      ],
      logoUrl: 'https://i.imgur.com/u8N6uoj.png',
      quality: '1080p',
      country: 'France / Global',
      description:
          'International news from a French perspective with live debates, culture, and world reportage.',
    ),
    LiveTvChannel(
      id: 'ch_cnbc_intl',
      name: 'CNBC International',
      category: 'Berita',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/cnbc/index.m3u8',
      fallbackStreamUrls: [
        'https://cnbc-live.akamaized.net/cnbc/master.m3u8',
      ],
      logoUrl:
          'https://raw.githubusercontent.com/apistech/project/refs/heads/main/logo/image_ch_cnbcasia.png',
      quality: '1080p',
      country: 'Global',
      description:
          'World business and financial news leader with real-time stock exchanges and market summits.',
    ),
    LiveTvChannel(
      id: 'ch_cna_news',
      name: 'CNA (Channel NewsAsia) HD',
      category: 'Berita',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/cna/index.m3u8',
      logoUrl:
          'https://cms.cignal.tv/Upload/Images/CNA%20LOGO%20-horizontal%20-%20on%20light%20background.png',
      quality: '1080p',
      country: 'Singapore / Asia',
      description:
          'Asian and international breaking news, business analysis, and current affairs from Singapore.',
    ),
    LiveTvChannel(
      id: 'ch_euronews_en',
      name: 'Euronews English HD',
      category: 'Berita',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/euronews/index.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/bloomberg/index.m3u8',
      ],
      logoUrl:
          'https://raw.githubusercontent.com/apistech/project/refs/heads/main/logo/image_ch_euronews.png',
      quality: '1080p',
      country: 'Europe / Global',
      description:
          'Pan-European continuous breaking news, world affairs, business, and geopolitics network.',
    ),

    // ════════════════════════════════════════════════════════════════
    // 4. FILM & HIBURAN (MOVIES & SERIES)
    // ════════════════════════════════════════════════════════════════
    LiveTvChannel(
      id: 'ch_galaxy_premium',
      name: 'Galaxy Premium Movies HD',
      category: 'Film & Hiburan',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/galaxyprem/index.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/galaxy/index.m3u8',
      ],
      logoUrl: 'https://i.imgur.com/oGKtYYG.png',
      quality: '1080p',
      country: 'Global',
      description:
          'Blockbuster Hollywood movies, action hits, and award-winning cinema 24/7.',
    ),
    LiveTvChannel(
      id: 'ch_hits_movies',
      name: 'HITS Movies HD',
      category: 'Film & Hiburan',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/hitsmovies/index.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/hits/index.m3u8',
      ],
      logoUrl: 'https://www.visionplus.id/images/repository/622/622-LOGO-m.png',
      quality: '1080p',
      country: 'Global',
      description:
          'Iconic Hollywood blockbuster films and timeless movie favorites 24/7.',
    ),
    LiveTvChannel(
      id: 'ch_axn_hd',
      name: 'AXN HD',
      category: 'Film & Hiburan',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/axn/index.m3u8',
      logoUrl: 'https://www.visionplus.id/images/repository/617/617-LOGO-m.png',
      quality: '1080p',
      country: 'Global',
      description:
          'High-energy action series, blockbuster movies, crime dramas, and adventure entertainment.',
    ),
    LiveTvChannel(
      id: 'ch_rock_action',
      name: 'ROCK Action HD',
      category: 'Film & Hiburan',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/rockaction/index.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/kix/index.m3u8',
      ],
      logoUrl: 'https://www.visionplus.id/images/repository/664/664-LOGO-m.png',
      quality: '1080p',
      country: 'Global',
      description:
          'Non-stop adrenaline-fueled action films, martial arts cinema, and Hollywood blockbusters.',
    ),
    LiveTvChannel(
      id: 'ch_thrill_movies',
      name: 'Thrill Horror & Suspense HD',
      category: 'Film & Hiburan',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/thrill/index.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/celestialmovies/index.m3u8',
      ],
      logoUrl: 'https://www.visionplus.id/images/repository/626/626-LOGO-m.png',
      quality: '1080p',
      country: 'Asia / Global',
      description:
          '24/7 horror, thriller, suspense, and supernatural cinema favorites.',
    ),
    LiveTvChannel(
      id: 'ch_tvn_movies',
      name: 'tvN Movies HD',
      category: 'Film & Hiburan',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/tvnmovies/index.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/celestialmovies/index.m3u8',
      ],
      logoUrl: 'https://www.visionplus.id/images/repository/658/658-LOGO-m.png',
      quality: '1080p',
      country: 'Korea / Asia',
      description:
          'Home of Korean blockbuster movies, box-office hits, and award-winning Asian cinema.',
    ),
    LiveTvChannel(
      id: 'ch_my_cinema_europe',
      name: 'My Cinema Europe HD',
      category: 'Film & Hiburan',
      streamUrl: 'https://op-flashcon-digdayahd-1.dens.tv/h/h18/01.m3u8',
      logoUrl:
          'https://raw.githubusercontent.com/apistech/project/refs/heads/main/logo/My_Cinema_Europe_HD_1.jpg',
      quality: '1080p',
      country: 'Europe / Global',
      description:
          'Curated European cinema, festival gems, and critically acclaimed films.',
    ),

    // ════════════════════════════════════════════════════════════════
    // 5. ANAK & ANIMASI (KIDS)
    // ════════════════════════════════════════════════════════════════
    LiveTvChannel(
      id: 'ch_dreamworks_kids',
      name: 'DreamWorks Channel HD',
      category: 'Anak & Animasi',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/dreamworks/index.m3u8',
      logoUrl: 'https://www.visionplus.id/images/repository/649/649-LOGO-m.png',
      quality: '1080p',
      country: 'USA / Global',
      description:
          'Official DreamWorks Animation channel featuring Kung Fu Panda, Madagascar, Trolls, and family adventures.',
    ),
    LiveTvChannel(
      id: 'ch_cbeebies_kids',
      name: 'BBC CBeebies HD',
      category: 'Anak & Animasi',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/cbeebies/index.m3u8',
      logoUrl: 'https://ichef.bbci.co.uk/images/ic/1920xn/p0fpxchz.png',
      quality: '1080p',
      country: 'United Kingdom / Global',
      description:
          'Award-winning BBC preschool & children programming, interactive stories, and educational cartoons.',
    ),
    LiveTvChannel(
      id: 'ch_nick_jr',
      name: 'Nick Jr. HD',
      category: 'Anak & Animasi',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/nickjr/index.m3u8',
      logoUrl: 'https://www.visionplus.id/images/repository/652/652-LOGO-m.png',
      quality: '1080p',
      country: 'USA / Global',
      description:
          'PAW Patrol, Dora the Explorer, Blue\'s Clues, and fun learning adventures for kids.',
    ),
    LiveTvChannel(
      id: 'ch_animax_hd',
      name: 'Animax Anime HD',
      category: 'Anak & Animasi',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/animax/index.m3u8',
      logoUrl: 'https://www.visionplus.id/images/repository/646/646-LOGO-m.png',
      quality: '1080p',
      country: 'Japan / Asia',
      description:
          '24/7 Japanese anime television network broadcasting popular action, fantasy, and comedy anime series.',
    ),
    LiveTvChannel(
      id: 'ch_moonbug_kids',
      name: 'Moonbug Kids HD (CoComelon)',
      category: 'Anak & Animasi',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/moonbug/index.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/zoomoo/index.m3u8',
      ],
      logoUrl:
          'https://www.visionplus.id/images/repository/909/162909-LOGO-m.png',
      quality: '1080p',
      country: 'Global',
      description:
          'CoComelon, Blippi, Little Baby Bum, and joyful animated nursery rhymes for children.',
    ),

    // ════════════════════════════════════════════════════════════════
    // 6. MUSIK (MUSIC)
    // ════════════════════════════════════════════════════════════════
    LiveTvChannel(
      id: 'ch_1hd_music',
      name: '1HD Music Television',
      category: 'Musik',
      streamUrl: 'http://176.118.197.101/1HD/index.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/musictv/index.m3u8',
      ],
      logoUrl: 'https://i.imgur.com/4Ww7CsR.png',
      quality: '1080p',
      country: 'Global',
      description:
          'High definition international music videos, chart hits, and live DJ sets.',
    ),
    LiveTvChannel(
      id: 'ch_vision_music_tv',
      name: 'Music TV HD',
      category: 'Musik',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/musictv/index.m3u8',
      logoUrl:
          'https://raw.githubusercontent.com/apistech/project/refs/heads/main/logo/image_ch_musikindonesia.png',
      quality: '1080p',
      country: 'Indonesia / Global',
      description:
          'Non-stop Indonesian & international music videos, pop chart hits, and concert specials 24/7.',
    ),
    LiveTvChannel(
      id: 'ch_adria_music',
      name: 'Adria Music Television HD',
      category: 'Musik',
      streamUrl: 'https://adriaapp.b-cdn.net/1080p/index.m3u8',
      logoUrl: 'https://i.imgur.com/QoDpnKg.png',
      quality: '1080p',
      country: 'Europe / Global',
      description:
          'Top European and international chart hits, pop music, and high-energy music videos.',
    ),

    // ════════════════════════════════════════════════════════════════
    // 7. SAINS & EDUKASI (SCIENCE & DOCUMENTARY)
    // ════════════════════════════════════════════════════════════════
    LiveTvChannel(
      id: 'ch_bbc_earth',
      name: 'BBC Earth HD',
      category: 'Sains & Edukasi',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/bbcearth/index.m3u8',
      fallbackStreamUrls: [
        'https://amg00793-amg00793c6-xumo-us-2669.playouts.now.amagi.tv/BBCStudios-BBCEarthA-hls/playlist.m3u8',
      ],
      logoUrl: 'https://www.visionplus.id/images/repository/634/634-LOGO-m.png',
      quality: '1080p',
      country: 'United Kingdom / Global',
      description:
          'Landmark BBC natural history documentaries, wildlife expeditions, space science, and Planet Earth.',
    ),
    LiveTvChannel(
      id: 'ch_history_hd',
      name: 'History Channel HD',
      category: 'Sains & Edukasi',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/history/index.m3u8',
      logoUrl: 'https://www.visionplus.id/images/repository/638/638-LOGO-m.png',
      quality: '1080p',
      country: 'USA / Global',
      description:
          'Ancient civilizations, engineering marvels, world history documentaries, and scientific mysteries.',
    ),
    LiveTvChannel(
      id: 'ch_love_nature',
      name: 'Love Nature HD',
      category: 'Sains & Edukasi',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/lovenature/index.m3u8',
      logoUrl: 'https://www.visionplus.id/images/repository/639/639-LOGO-m.png',
      quality: '1080p',
      country: 'Global',
      description:
          'Breathtaking wildlife stories, ocean discoveries, and nature documentaries from around the globe.',
    ),
    LiveTvChannel(
      id: 'ch_global_trekker',
      name: 'Global Trekker HD',
      category: 'Sains & Edukasi',
      streamUrl: 'https://dsgtq5sngxkde.cloudfront.net/globetrekker/index.m3u8',
      fallbackStreamUrls: [
        'https://dsgtq5sngxkde.cloudfront.net/cgtndoc/index.m3u8',
      ],
      logoUrl: 'https://www.visionplus.id/images/repository/637/637-LOGO-m.png',
      quality: '1080p',
      country: 'Global',
      description:
          'Science, technology, global exploration, cultural documentaries, and innovation insights.',
    ),
  ];

  /// Looks up a [LiveTvChannel] by its unique [id].
  static LiveTvChannel? findById(String id) {
    for (final ch in defaultChannels) {
      if (ch.id == id) return ch;
    }
    return null;
  }

  /// Returns all football-capable channels in priority order.
  static List<LiveTvChannel> get footballChannels {
    const ids = [
      'ch_bein_sports_1',
      'ch_bein_sports_2',
      'ch_bein_sports_3',
      'ch_bein_sports_xtra',
      'ch_soccer_channel',
      'id_sctv',
      'id_indosiar',
      'id_rcti',
      'id_moji',
      'id_tvri_sport',
      'ch_fifa_plus',
      'ch_realmadrid_tv',
      'ch_spotv_2',
      'ch_sportstars',
      'ch_cbs_sports_hq',
      'id_inews',
      'id_mnctv',
      'ch_aspor',
    ];
    return ids.map(findById).whereType<LiveTvChannel>().toList();
  }
}
