import 'package:cineva/features/player/data/models/subtitle_cue.dart';
import 'package:cineva/features/player/data/services/subtitle_translator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Subtitle Abbreviation and Acronym Normalization Tests', () {
    test('Normalizes user specific examples (l.A.P.D, i.A, t.O) cleanly', () {
      // Direct examples requested by user
      const rawText = 'petugas l.A.P.D dan i.A serta t.O';
      final formatted = SubtitleTranslatorService.smartFormatIndonesianSubtitle(rawText);
      expect(formatted, 'Petugas L.A.P.D dan I.A serta T.O');
    });

    test('Normalizes dotted abbreviations with hyphenated suffixes (The Rookie context)', () {
      // Training Officer (T.O.) context in The Rookie
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('t.O.-ku adalah Opsir Nolan.'),
        'T.O.-ku adalah Opsir Nolan.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('t.O.-ku sangat tegas.'),
        'T.O.-ku sangat tegas.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('dia adalah t.o.-nya yang baru.'),
        'Dia adalah T.O.-nya yang baru.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('seragam l.a.p.d.-nya sangat rapi.'),
        'Seragam L.A.P.D.-nya sangat rapi.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('laporan i.a.-ku sudah diserahkan.'),
        'Laporan I.A.-ku sudah diserahkan.',
      );
    });

    test('Normalizes Internal Affairs (I.A.) and training abbreviations with dots', () {
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('divisi i.a. sedang menyelidiki kasus ini.'),
        'Divisi I.A. sedang menyelidiki kasus ini.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('divisi i.A. sedang menyelidiki kasus ini.'),
        'Divisi I.A. sedang menyelidiki kasus ini.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('apakah i.a sudah datang?'),
        'Apakah I.A sudah datang?',
      );
    });

    test('Prevents false sentence capitalization after trailing abbreviation period', () {
      // Continuation words following L.A.P.D. should stay lowercase
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('petugas L.A.P.D. itu sedang bertugas di lapangan.'),
        'Petugas L.A.P.D. itu sedang bertugas di lapangan.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('mobil L.A.P.D. ini melaju kencang.'),
        'Mobil L.A.P.D. ini melaju kencang.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('agen F.B.I. yang mencurigakan itu menghilang.'),
        'Agen F.B.I. yang mencurigakan itu menghilang.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('divisi I.A. sedang melakukan pemeriksaan internal.'),
        'Divisi I.A. sedang melakukan pemeriksaan internal.',
      );
    });

    test('Correctly capitalizes next word when abbreviation truly ends a sentence', () {
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Dia bekerja untuk L.A.P.D. Mereka sangat hebat.'),
        'Dia bekerja untuk L.A.P.D. Mereka sangat hebat.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Lapor ke I.A. Jangan beritahu siapapun.'),
        'Lapor ke I.A. Jangan beritahu siapapun.',
      );
    });

    test('Normalizes spaced abbreviations (e.g. l. a. p. d. -> L.A.P.D.)', () {
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('kami melihat mobil l. a. p. d. dan t. o. datang.'),
        'Kami melihat mobil L.A.P.D. dan T.O. datang.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('petugas i. a. memeriksa berkas.'),
        'Petugas I.A. memeriksa berkas.',
      );
    });

    test('Strictly preserves Indonesian pronoun "ia" without turning it into IA', () {
      // Indonesian pronoun "ia" (dia) must NEVER be capitalized in mid-sentence
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('kemarin ia pergi ke kantor polisi.'),
        'Kemarin ia pergi ke kantor polisi.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('ia berkata bahwa ia tidak bersalah.'),
        'Ia berkata bahwa ia tidak bersalah.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('apakah ia yang menelepon ambulans?'),
        'Apakah ia yang menelepon ambulans?',
      );
    });

    test('Strictly preserves Indonesian word "doa" (prayer) without turning into DOA', () {
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('panjatkan doa untuk keselamatan mereka.'),
        'Panjatkan doa untuk keselamatan mereka.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('semoga doa kita didengar oleh Tuhan.'),
        'Semoga doa kita didengar oleh Tuhan.',
      );

      // But dotted D.O.A. (Dead On Arrival) IS formatted to uppercase
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('korban dinyatakan d.o.a. di rumah sakit.'),
        'Korban dinyatakan D.O.A. di rumah sakit.',
      );
    });

    test('Normalizes standalone police, military, and medical acronyms', () {
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('anggota lapd dan nypd bekerja sama dengan fbi.'),
        'Anggota LAPD dan NYPD bekerja sama dengan FBI.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('korban butuh cpr dan panggil tim ems atau emt!'),
        'Korban butuh CPR dan panggil tim EMS atau EMT!',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('tim swat mengepung lokasi persembunyian.'),
        'Tim SWAT mengepung lokasi persembunyian.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('kasus ini diselidiki oleh polri dan kpk.'),
        'Kasus ini diselidiki oleh POLRI dan KPK.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('pasukan tni dan petugas basarnas telah tiba.'),
        'Pasukan TNI dan petugas BASARNAS telah tiba.',
      );
    });

    test('Normalizes standalone acronyms with hyphenated Indonesian suffixes', () {
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('mobil lapd-nya rusak berat.'),
        'Mobil LAPD-nya rusak berat.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('seragam swat-ku masih basah.'),
        'Seragam SWAT-ku masih basah.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('laporan fbi-nya sudah diterima.'),
        'Laporan FBI-nya sudah diterima.',
      );
    });

    test('fixAbbreviations helper handles raw subtitle strings directly', () {
      expect(
        SubtitleTranslatorService.fixAbbreviations('petugas l.A.P.D dan i.A serta t.O'),
        'petugas L.A.P.D dan I.A serta T.O',
      );
      expect(
        SubtitleTranslatorService.fixAbbreviations('t.O.-ku adalah Nolan'),
        'T.O.-ku adalah Nolan',
      );
      expect(
        SubtitleTranslatorService.fixAbbreviations('l. a. p. d.'),
        'L.A.P.D.',
      );
      expect(
        SubtitleTranslatorService.fixAbbreviations('korban butuh cpr segera'),
        'korban butuh CPR segera',
      );
    });

    test('SubtitleCue.parseSrt automatically cleans messy abbreviation casing at parse time', () {
      const srt = '''
1
00:00:01,000 --> 00:00:04,000
petugas l.A.P.D dan i.A tiba di lokasi.

2
00:00:05,000 --> 00:00:08,000
t.O.-ku menyuruhku melakukan cpr.
''';

      final cues = SubtitleCue.parseSrt(srt);
      expect(cues.length, 2);
      expect(cues[0].text, 'petugas L.A.P.D dan I.A tiba di lokasi.');
      expect(cues[1].text, 'T.O.-ku menyuruhku melakukan CPR.');
    });
  });
}
