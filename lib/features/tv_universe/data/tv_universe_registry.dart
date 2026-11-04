import '../domain/entities/tv_universe.dart';

class TvUniverseRegistry {
  TvUniverseRegistry._();

  static final List<TvUniverse> allUniverses = [
    // ── Naruto Universe ──
    const TvUniverse(
      id: 'naruto-universe',
      name: 'Semesta Naruto & Boruto',
      description:
          'Kisah epik dunia shinobi dari impian seorang bocah yatim piatu menjadi Hokage hingga perang dunia ninja dan era baru ninja modern.',
      backdropPath: '/5F0HVEgkgP99fEWDjPyikGt9jQi.jpg',
      posterPath: '/xppeysfvDKVx775MFuH8Z9BlpMk.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 46260,
          title: 'Naruto',
          orderIndex: 1,
          type: TvUniverseEntryType.mainSeries,
          yearRange: '2002–2007',
          note: 'Serial Awal: Perjalanan Naruto Uzumaki menjadi Genin dan pencarian Sasuke.',
          posterPath: '/xppeysfvDKVx775MFuH8Z9BlpMk.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 31910,
          title: 'Naruto: Shippuden',
          orderIndex: 2,
          type: TvUniverseEntryType.sequel,
          yearRange: '2007–2017',
          note: 'Sekuel Utama: Naruto remaja menghadapi ancaman Akatsuki dan Perang Dunia Shinobi Ke-4.',
          posterPath: '/kV27j3Nz4d5z8u6mN3EJw9RiLg2.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 70881,
          title: 'Boruto: Naruto Next Generations',
          orderIndex: 3,
          type: TvUniverseEntryType.sequel,
          yearRange: '2017–2023',
          note: 'Sekuel Generasi Baru: Kisah Boruto Uzumaki menghadapi ancaman klan Otsutsuki.',
          posterPath: '/e0B6i48kxdRkMcK4tR4YNfXGWOc.jpg',
        ),
      ],
    ),

    // ── Breaking Bad Universe ──
    const TvUniverse(
      id: 'breaking-bad-universe',
      name: 'Semesta Breaking Bad',
      description:
          'Dunia kriminal Albuquerque dari transformasi pengacara licik Jimmy McGill hingga kekaisaran metamfetamin Heisenberg.',
      backdropPath: '/tsRy63Mu5cu8etL1X7ZLyf7UP1M.jpg',
      posterPath: '/anFx9aTOOYqgS3v7x3R84Kz67ly.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 60059,
          title: 'Better Call Saul',
          orderIndex: 1,
          type: TvUniverseEntryType.prequel,
          yearRange: '2015–2022',
          note: 'Prekuel: Perjalanan transformasi pengacara idealis Jimmy McGill menjadi Saul Goodman.',
          posterPath: '/fC2HDm5t0kHl7mTm7jxMR31b7by.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 1396,
          title: 'Breaking Bad',
          orderIndex: 2,
          type: TvUniverseEntryType.mainSeries,
          yearRange: '2008–2013',
          note: 'Serial Utama: Guru kimia Walter White bermetamorfosis menjadi gembong narkoba legendaris.',
          posterPath: '/anFx9aTOOYqgS3v7x3R84Kz67ly.jpg',
        ),
      ],
    ),

    // ── Game of Thrones Universe ──
    const TvUniverse(
      id: 'got-universe',
      name: 'Semesta Game of Thrones (Westeros)',
      description:
          'Perebutan tahta Iron Throne dan perang dinasti naga House Targaryen di benua Westeros.',
      backdropPath: '/577eXC8wFQT0eUrJcgznSiFPRmk.jpg',
      posterPath: '/7V0Ebks0GgpKvQ7QbLAIdX5dos4.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 94997,
          title: 'House of the Dragon',
          orderIndex: 1,
          type: TvUniverseEntryType.prequel,
          yearRange: '2022–present',
          note: 'Prekuel 200 Tahun: Perang saudara klan Targaryen yang dikenal sebagai Dance of the Dragons.',
          posterPath: '/7V0Ebks0GgpKvQ7QbLAIdX5dos4.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 1399,
          title: 'Game of Thrones',
          orderIndex: 2,
          type: TvUniverseEntryType.mainSeries,
          yearRange: '2011–2019',
          note: 'Serial Utama: Perang sembilan keluarga bangsawan memperebutkan kendali atas Seven Kingdoms.',
          posterPath: '/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg',
        ),
      ],
    ),

    // ── The Walking Dead Universe ──
    const TvUniverse(
      id: 'twd-universe',
      name: 'The Walking Dead Universe',
      description:
          'Kisah perjuangan umat manusia bertahan hidup setelah wabah zombie menghancurkan peradaban bumi.',
      backdropPath: '/rAOjnEFTuNysY7bot8zonhImGMh.jpg',
      posterPath: '/ng3cMtxYKt1OSQYqFlnKWnVsqNO.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 62286,
          title: 'Fear the Walking Dead',
          orderIndex: 1,
          type: TvUniverseEntryType.prequel,
          yearRange: '2015–2023',
          note: 'Prekuel & Pendamping: Awal mula merebaknya virus mayat hidup di kota Los Angeles.',
          posterPath: '/eKt4ELpQZUKGZCKIDobEbwHwk3I.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 1402,
          title: 'The Walking Dead',
          orderIndex: 2,
          type: TvUniverseEntryType.mainSeries,
          yearRange: '2010–2022',
          note: 'Serial Utama: Perjalanan epik Rick Grimes dan kelompok penyintas di Virginia.',
          posterPath: '/ng3cMtxYKt1OSQYqFlnKWnVsqNO.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 194583,
          title: 'The Walking Dead: Dead City',
          orderIndex: 3,
          type: TvUniverseEntryType.sequel,
          yearRange: '2023–present',
          note: 'Sekuel: Misi berbahaya Maggie dan Negan di Manhattan pasca-apokaliptik.',
          posterPath: '/wq3vuQzQgbS83zX3malAFWMsSwX.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 211684,
          title: 'The Walking Dead: Daryl Dixon',
          orderIndex: 4,
          type: TvUniverseEntryType.sequel,
          yearRange: '2023–present',
          note: 'Sekuel: Daryl Dixon terdampar dan berjuang melintasi daratan Prancis.',
          posterPath: '/sP5QdW9FN18XWcA4ROz3MPAQBTx.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 206586,
          title: 'The Walking Dead: The Ones Who Live',
          orderIndex: 5,
          type: TvUniverseEntryType.sequel,
          yearRange: '2024',
          note: 'Sekuel Puncak: Kisah cinta dan reuni antara Rick Grimes dan Michonne.',
          posterPath: '/ywbacot78IuNhGW4uVZPxxxVTkm.jpg',
        ),
      ],
    ),

    // ── Money Heist Universe ──
    const TvUniverse(
      id: 'money-heist-universe',
      name: 'Semesta Money Heist (La Casa de Papel)',
      description:
          'Rencana perampokan paling brilian dan spektakuler di Eropa yang dirancang oleh Sang Profesor.',
      backdropPath: '/xGexTKCJDkl12dTW4YCBDXWb1AD.jpg',
      posterPath: '/reEMJA1uzscCbkpeRJeTT2bjqUp.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 146176,
          title: 'Berlin',
          orderIndex: 1,
          type: TvUniverseEntryType.prequel,
          yearRange: '2023–present',
          note: 'Prekuel: Masa kejayaan Berlin saat merencanakan pencurian perhiasan terbesar di Paris.',
          posterPath: '/69YuvoiWTtK6oyYH2Jl4Q6SgZ59.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 71446,
          title: 'Money Heist (La Casa de Papel)',
          orderIndex: 2,
          type: TvUniverseEntryType.mainSeries,
          yearRange: '2017–2021',
          note: 'Serial Utama: Perampokan bersejarah di Badan Percetakan Uang dan Bank of Spain.',
          posterPath: '/reEMJA1uzscCbkpeRJeTT2bjqUp.jpg',
        ),
      ],
    ),

    // ── Dragon Ball Universe ──
    const TvUniverse(
      id: 'dragon-ball-universe',
      name: 'Semesta Dragon Ball',
      description:
          'Petualangan Son Goku mengasah kekuatan bela diri bangsa Saiyan demi melindungi alam semesta.',
      backdropPath: '/ydf1CeiBLfdxiyNTpskM0802TKl.jpg',
      posterPath: '/oQ5CnVj3TRifXl2bIOri6H6rfNe.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 12609,
          title: 'Dragon Ball',
          orderIndex: 1,
          type: TvUniverseEntryType.mainSeries,
          yearRange: '1986–1989',
          note: 'Serial Awal: Masa kecil Goku mencari 7 bola naga bersama Bulma dan Master Roshi.',
          posterPath: '/onCLyCOgszTIyyVs2XKYSkKPOPG.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 12971,
          title: 'Dragon Ball Z',
          orderIndex: 2,
          type: TvUniverseEntryType.sequel,
          yearRange: '1989–1996',
          note: 'Sekuel: Pertarungan Super Saiyan melawan Vegeta, Frieza, Cell, dan Majin Buu.',
          posterPath: '/oQ5CnVj3TRifXl2bIOri6H6rfNe.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 62715,
          title: 'Dragon Ball Super',
          orderIndex: 3,
          type: TvUniverseEntryType.sequel,
          yearRange: '2015–2018',
          note: 'Sekuel: Melawan Dewa Kehancuran Beerus, Goku Black, hingga Turnamen Kekuatan.',
          posterPath: '/qEUrbXJ2qt4Rg84Btlx4STOhgte.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 236994,
          title: 'Dragon Ball DAIMA',
          orderIndex: 4,
          type: TvUniverseEntryType.sequel,
          yearRange: '2024–present',
          note: 'Petualangan Baru: Goku dan kawan-kawan berubah menjadi anak kecil di Alam Iblis.',
          posterPath: '/lMULbSFZNXUC87MqOZQ4SSV9DXI.jpg',
        ),
      ],
    ),

    // ── The Boys Universe ──
    const TvUniverse(
      id: 'the-boys-universe',
      name: 'Semesta The Boys',
      description:
          'Dunia superhero korup di mana pahlawan berkekuatan super disembah publik namun dikendalikan korporasi serakah.',
      backdropPath: '/bq28ajZaoMyzEIm6REelqyqtEDZ.jpg',
      posterPath: '/in1R2dDc421JxsoRWaIIAqVI2KE.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 205715,
          title: 'Gen V',
          orderIndex: 1,
          type: TvUniverseEntryType.spinoff,
          yearRange: '2023–present',
          note: 'Spin-off Kampus: Mahasiswa berkekuatan super di Godolkin University menguak rahasia gelap Woods.',
          posterPath: '/tEv842Nd5uMSavURG4aQO1pNtst.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 76479,
          title: 'The Boys',
          orderIndex: 2,
          type: TvUniverseEntryType.mainSeries,
          yearRange: '2019–present',
          note: 'Serial Utama: Pasukan The Boys pimpinan Billy Butcher berusaha menjatuhkan Homelander dan Vought.',
          posterPath: '/in1R2dDc421JxsoRWaIIAqVI2KE.jpg',
        ),
      ],
    ),

    // ── Yellowstone Universe ──
    const TvUniverse(
      id: 'yellowstone-universe',
      name: 'Semesta Yellowstone (Dutton Saga)',
      description:
          'Kisah generasi keluarga Dutton mempertahankan tanah peternakan terbesar di Montana melintasi abad.',
      backdropPath: '/ynSOcgDLZfdLCZfRSYZGiTgYJVo.jpg',
      posterPath: '/peNC0eyc3TQJa6x4TdKcBPNP4t0.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 118357,
          title: '1883',
          orderIndex: 1,
          type: TvUniverseEntryType.prequel,
          yearRange: '2021–2022',
          note: 'Prekuel Abad 19: Perjalanan generasi awal Dutton melintasi Great Plains menuju Montana.',
          posterPath: '/waLbm384SQDwLTCn6ttPqQS5kfV.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 157744,
          title: '1923',
          orderIndex: 2,
          type: TvUniverseEntryType.prequel,
          yearRange: '2022–2024',
          note: 'Prekuel Abad 20: Keluarga Dutton menghadapi era depresi besar dan hukum rimba di Montana.',
          posterPath: '/zgZRJZvZn5cpsWAB0zMUdad3iZd.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 73586,
          title: 'Yellowstone',
          orderIndex: 3,
          type: TvUniverseEntryType.mainSeries,
          yearRange: '2018–2024',
          note: 'Serial Utama: John Dutton memimpin peternakan menghadapi pengembang modern dan reservasi.',
          posterPath: '/peNC0eyc3TQJa6x4TdKcBPNP4t0.jpg',
        ),
      ],
    ),
  ];

  /// Finds a matching universe for a given TMDB TV show ID
  static TvUniverse? findUniverseByTvId(int tvId) {
    return allUniverses.where((u) => u.entries.any((e) => e.tmdbTvId == tvId)).firstOrNull;
  }

  /// Finds universe by its unique identifier
  static TvUniverse? getUniverseById(String universeId) {
    return allUniverses.where((u) => u.id == universeId).firstOrNull;
  }
}
