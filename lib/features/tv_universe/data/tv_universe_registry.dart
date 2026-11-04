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
      backdropPath: '/vIohhH61p2iWJp6VnQ67Q5o8V7y.jpg',
      posterPath: '/xppeGar9j2DrQIbZ83vH0598yhu.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 46260,
          title: 'Naruto',
          orderIndex: 1,
          type: TvUniverseEntryType.mainSeries,
          yearRange: '2002–2007',
          note: 'Serial Awal: Perjalanan Naruto Uzumaki menjadi Genin dan pencarian Sasuke.',
          posterPath: '/xppeGar9j2DrQIbZ83vH0598yhu.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 31910,
          title: 'Naruto: Shippuden',
          orderIndex: 2,
          type: TvUniverseEntryType.sequel,
          yearRange: '2007–2017',
          note: 'Sekuel Utama: Naruto remaja menghadapi ancaman Akatsuki dan Perang Dunia Shinobi Ke-4.',
          posterPath: '/kV27inB9x49m5G72N1v5E5M7Xj.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 70881,
          title: 'Boruto: Naruto Next Generations',
          orderIndex: 3,
          type: TvUniverseEntryType.sequel,
          yearRange: '2017–2023',
          note: 'Sekuel Generasi Baru: Kisah Boruto Uzumaki menghadapi ancaman klan Otsutsuki.',
          posterPath: '/179rKqc8k5P7Z7f9D545zCg37e.jpg',
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
      posterPath: '/ztkUQFLlC19CCMYHW9o1zWhJRNq.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 60059,
          title: 'Better Call Saul',
          orderIndex: 1,
          type: TvUniverseEntryType.prequel,
          yearRange: '2015–2022',
          note: 'Prekuel: Perjalanan transformasi pengacara idealis Jimmy McGill menjadi Saul Goodman.',
          posterPath: '/fC2HDm5t0kHVR79Kc7Ba2dlrjWu.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 1396,
          title: 'Breaking Bad',
          orderIndex: 2,
          type: TvUniverseEntryType.mainSeries,
          yearRange: '2008–2013',
          note: 'Serial Utama: Guru kimia Walter White bermetamorfosis menjadi gembong narkoba legendaris.',
          posterPath: '/ztkUQFLlC19CCMYHW9o1zWhJRNq.jpg',
        ),
      ],
    ),

    // ── Game of Thrones Universe ──
    const TvUniverse(
      id: 'got-universe',
      name: 'Semesta Game of Thrones (Westeros)',
      description:
          'Perebutan tahta Iron Throne dan perang dinasti naga House Targaryen di benua Westeros.',
      backdropPath: '/2OMB0ynKlyIenMJWI2Dy9IWT4c.jpg',
      posterPath: '/7QMsOTMUswlwxJP0rTTZfmz2tX2.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 94997,
          title: 'House of the Dragon',
          orderIndex: 1,
          type: TvUniverseEntryType.prequel,
          yearRange: '2022–present',
          note: 'Prekuel 200 Tahun: Perang saudara klan Targaryen yang dikenal sebagai Dance of the Dragons.',
          posterPath: '/7QMsOTMUswlwxJP0rTTZfmz2tX2.jpg',
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
      backdropPath: '/uro2Khv7JdryeY8tOxEGnvAp0ht.jpg',
      posterPath: '/xf9wuDcqlUPWABZNeDKPbZUjWx0.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 62286,
          title: 'Fear the Walking Dead',
          orderIndex: 1,
          type: TvUniverseEntryType.prequel,
          yearRange: '2015–2023',
          note: 'Prekuel & Pendamping: Awal mula merebaknya virus mayat hidup di kota Los Angeles.',
          posterPath: '/up0DoxMv7y5R7qWz1W96B68oK8o.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 1402,
          title: 'The Walking Dead',
          orderIndex: 2,
          type: TvUniverseEntryType.mainSeries,
          yearRange: '2010–2022',
          note: 'Serial Utama: Perjalanan epik Rick Grimes dan kelompok penyintas di Virginia.',
          posterPath: '/xf9wuDcqlUPWABZNeDKPbZUjWx0.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 194766,
          title: 'The Walking Dead: Dead City',
          orderIndex: 3,
          type: TvUniverseEntryType.sequel,
          yearRange: '2023–present',
          note: 'Sekuel: Misi berbahaya Maggie dan Negan di Manhattan pasca-apokaliptik.',
          posterPath: '/x8sC7H46Jp3Z0xL50F3N5Q2U7z.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 209670,
          title: 'The Walking Dead: Daryl Dixon',
          orderIndex: 4,
          type: TvUniverseEntryType.sequel,
          yearRange: '2023–present',
          note: 'Sekuel: Daryl Dixon terdampar dan berjuang melintasi daratan Prancis.',
          posterPath: '/kxCE5F3Jg975QzY5P9x94z6f5e.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 206586,
          title: 'The Walking Dead: The Ones Who Live',
          orderIndex: 5,
          type: TvUniverseEntryType.sequel,
          yearRange: '2024',
          note: 'Sekuel Puncak: Kisah cinta dan reuni antara Rick Grimes dan Michonne.',
          posterPath: '/2P6Y15n5Xy2yFqO3g1fH0k8F8P.jpg',
        ),
      ],
    ),

    // ── Money Heist Universe ──
    const TvUniverse(
      id: 'money-heist-universe',
      name: 'Semesta Money Heist (La Casa de Papel)',
      description:
          'Rencana perampokan paling brilian dan spektakuler di Eropa yang dirancang oleh Sang Profesor.',
      backdropPath: '/gFZri2YbFUReMwQZ3zMC4Ki5VIQ.jpg',
      posterPath: '/reEMJA1uzscCbk5rUhGny4m7Zcu.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 136283,
          title: 'Berlin',
          orderIndex: 1,
          type: TvUniverseEntryType.prequel,
          yearRange: '2023–present',
          note: 'Prekuel: Masa kejayaan Berlin saat merencanakan pencurian perhiasan terbesar di Paris.',
          posterPath: '/j6CwO6h4vR3O0a1L8x3j1Q6o7w.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 71446,
          title: 'Money Heist (La Casa de Papel)',
          orderIndex: 2,
          type: TvUniverseEntryType.mainSeries,
          yearRange: '2017–2021',
          note: 'Serial Utama: Perampokan bersejarah di Badan Percetakan Uang dan Bank of Spain.',
          posterPath: '/reEMJA1uzscCbk5rUhGny4m7Zcu.jpg',
        ),
      ],
    ),

    // ── Dragon Ball Universe ──
    const TvUniverse(
      id: 'dragon-ball-universe',
      name: 'Semesta Dragon Ball',
      description:
          'Petualangan Son Goku mengasah kekuatan bela diri bangsa Saiyan demi melindungi alam semesta.',
      backdropPath: '/2wgiZq78wL67pA9o6w9l0n7aV2q.jpg',
      posterPath: '/dM0D4C5mR00hB3u9pGf4X6kUqJp.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 12609,
          title: 'Dragon Ball',
          orderIndex: 1,
          type: TvUniverseEntryType.mainSeries,
          yearRange: '1986–1989',
          note: 'Serial Awal: Masa kecil Goku mencari 7 bola naga bersama Bulma dan Master Roshi.',
          posterPath: '/clzyhK78iO7Y2VpU6mR0v1bE2rF.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 12971,
          title: 'Dragon Ball Z',
          orderIndex: 2,
          type: TvUniverseEntryType.sequel,
          yearRange: '1989–1996',
          note: 'Sekuel: Pertarungan Super Saiyan melawan Vegeta, Frieza, Cell, dan Majin Buu.',
          posterPath: '/dM0D4C5mR00hB3u9pGf4X6kUqJp.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 62715,
          title: 'Dragon Ball Super',
          orderIndex: 3,
          type: TvUniverseEntryType.sequel,
          yearRange: '2015–2018',
          note: 'Sekuel: Melawan Dewa Kehancuran Beerus, Goku Black, hingga Turnamen Kekuatan.',
          posterPath: '/sUgkG0X4d91u5V1v4Q7L6M3m8.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 236844,
          title: 'Dragon Ball Daima',
          orderIndex: 4,
          type: TvUniverseEntryType.sequel,
          yearRange: '2024–present',
          note: 'Petualangan Baru: Goku dan kawan-kawan berubah menjadi anak kecil di Alam Iblis.',
          posterPath: '/5Q4bWz68x2V1v7Z8M4X3m9N2.jpg',
        ),
      ],
    ),

    // ── The Boys Universe ──
    const TvUniverse(
      id: 'the-boys-universe',
      name: 'Semesta The Boys',
      description:
          'Dunia superhero korup di mana pahlawan berkekuatan super disembah publik namun dikendalikan korporasi serakah.',
      backdropPath: '/mGVrXeIehIgAvqvAhpqIRZaqcvq.jpg',
      posterPath: '/7Ns6tO3aYjppI5LoNOFvjA7n7eS.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 205715,
          title: 'Gen V',
          orderIndex: 1,
          type: TvUniverseEntryType.spinoff,
          yearRange: '2023–present',
          note: 'Spin-off Kampus: Mahasiswa berkekuatan super di Godolkin University menguak rahasia gelap Woods.',
          posterPath: '/uuA4f50l5bW28Z7c9M7R1w6z6N.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 76479,
          title: 'The Boys',
          orderIndex: 2,
          type: TvUniverseEntryType.mainSeries,
          yearRange: '2019–present',
          note: 'Serial Utama: Pasukan The Boys pimpinan Billy Butcher berusaha menjatuhkan Homelander dan Vought.',
          posterPath: '/7Ns6tO3aYjppI5LoNOFvjA7n7eS.jpg',
        ),
      ],
    ),

    // ── Yellowstone Universe ──
    const TvUniverse(
      id: 'yellowstone-universe',
      name: 'Semesta Yellowstone (Dutton Saga)',
      description:
          'Kisah generasi keluarga Dutton mempertahankan tanah peternakan terbesar di Montana melintasi abad.',
      backdropPath: '/84XPpjGvxNyExjSuLQe0GIO9MfV.jpg',
      posterPath: '/iqWCUwYrCe5vF8vM6f6q7i8fR8f.jpg',
      entries: [
        TvUniverseEntry(
          tmdbTvId: 118357,
          title: '1883',
          orderIndex: 1,
          type: TvUniverseEntryType.prequel,
          yearRange: '2021–2022',
          note: 'Prekuel Abad 19: Perjalanan generasi awal Dutton melintasi Great Plains menuju Montana.',
          posterPath: '/1E5baAaEse26fej7uH0AL79WoM9.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 199996,
          title: '1923',
          orderIndex: 2,
          type: TvUniverseEntryType.prequel,
          yearRange: '2022–2024',
          note: 'Prekuel Abad 20: Keluarga Dutton menghadapi era depresi besar dan hukum rimba di Montana.',
          posterPath: '/mY4f4h8V5q1k9x6Q7b2L3o4.jpg',
        ),
        TvUniverseEntry(
          tmdbTvId: 73586,
          title: 'Yellowstone',
          orderIndex: 3,
          type: TvUniverseEntryType.mainSeries,
          yearRange: '2018–2024',
          note: 'Serial Utama: John Dutton memimpin peternakan menghadapi pengembang modern dan reservasi.',
          posterPath: '/iqWCUwYrCe5vF8vM6f6q7i8fR8f.jpg',
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

