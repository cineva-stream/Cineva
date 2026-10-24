import 'package:flutter_test/flutter_test.dart';
import 'package:cineva/features/player/data/models/subtitle_cue.dart';
import 'package:cineva/features/player/data/models/subtitle_style_settings.dart';
import 'package:cineva/features/player/data/services/subtitle_translator_service.dart';

void main() {
  group('SubtitleCue and Parser Tests', () {
    test('Correctly parses standard SRT format', () {
      const srtSample = '''
1
00:00:01,000 --> 00:00:04,500
Hello Peter, welcome back!

2
00:00:05,200 --> 00:00:08,750
<i>The city needs Spider-Man.</i>
''';

      final cues = SubtitleCue.parseSrt(srtSample);
      expect(cues.length, 2);

      expect(cues[0].start, const Duration(seconds: 1));
      expect(cues[0].end, const Duration(seconds: 4, milliseconds: 500));
      expect(cues[0].text, 'Hello Peter, welcome back!');

      expect(cues[1].start, const Duration(seconds: 5, milliseconds: 200));
      expect(cues[1].end, const Duration(seconds: 8, milliseconds: 750));
      // HTML tag <i> should be stripped
      expect(cues[1].text, 'The city needs Spider-Man.');
    });

    test('Correctly parses WebVTT format with 2-part and 3-part timestamps', () {
      const vttSample = '''
WEBVTT

00:35.201 --> 00:37.537 line:90% align:center
(ENCHANTING MUSIC PLAYING)

01:22.749 --> 01:24.375
JAKE: The forests of Pandora

01:05:10.500 --> 01:05:14.200
We must protect this place.
''';

      final cues = SubtitleCue.parseSrt(vttSample);
      expect(cues.length, 3);

      expect(cues[0].start, const Duration(seconds: 35, milliseconds: 201));
      expect(cues[0].end, const Duration(seconds: 37, milliseconds: 537));
      expect(cues[0].text, '(ENCHANTING MUSIC PLAYING)');

      expect(cues[1].start, const Duration(minutes: 1, seconds: 22, milliseconds: 749));
      expect(cues[1].end, const Duration(minutes: 1, seconds: 24, milliseconds: 375));
      expect(cues[1].text, 'JAKE: The forests of Pandora');

      expect(cues[2].start, const Duration(hours: 1, minutes: 5, seconds: 10, milliseconds: 500));
      expect(cues[2].end, const Duration(hours: 1, minutes: 5, seconds: 14, milliseconds: 200));
      expect(cues[2].text, 'We must protect this place.');
    });

    test('isActiveAt correctly matches duration ranges', () {
      const cue = SubtitleCue(
        start: Duration(seconds: 10),
        end: Duration(seconds: 15),
        text: 'Test line',
      );

      expect(cue.isActiveAt(const Duration(seconds: 9)), false);
      expect(cue.isActiveAt(const Duration(seconds: 10)), true);
      expect(cue.isActiveAt(const Duration(seconds: 12)), true);
      expect(cue.isActiveAt(const Duration(seconds: 15)), true);
      expect(cue.isActiveAt(const Duration(seconds: 16)), false);
    });

    test('SubtitleStyleSettings syncOffsetMs adjustment', () {
      const settings = SubtitleStyleSettings(syncOffsetMs: 0);
      final delayed = settings.copyWith(syncOffsetMs: 500);
      expect(delayed.syncOffsetMs, 500);

      final advanced = settings.copyWith(syncOffsetMs: -500);
      expect(advanced.syncOffsetMs, -500);
    });

    test('refineIndonesianPronouns correctly replaces KAMU/Kamu/kamu/ANDA/Anda/anda with Kau', () {
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('Kamu harus percaya padaku.'),
        'Kau harus percaya padaku.',
      );
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('Apakah kamu sudah siap?'),
        'Apakah kau sudah siap?',
      );
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('KAMU TIDAK BISA KABUR!'),
        'KAU TIDAK BISA KABUR!',
      );
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('Silakan Anda masuk.'),
        'Silakan Kau masuk.',
      );
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('anda harus tenang.'),
        'kau harus tenang.',
      );
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('ANDA ADALAH PAHLAWAN!'),
        'KAU ADALAH PAHLAWAN!',
      );

      // Verify that words containing "kamu" or "anda" are NOT corrupted
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('Ini tanda tangan kamu, pandanganmu sangat tajam.'),
        'Ini tanda tangan kau, pandanganmu sangat tajam.',
      );
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('Mandat ini untukmu.'),
        'Mandat ini untukmu.',
      );

      // Verify SAYA / Saya / saya -> AKU / Aku / aku
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('Saya tidak tahu apa yang kamu maksud.'),
        'Aku tidak tahu apa yang kau maksud.',
      );
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('Apakah saya boleh pergi?'),
        'Apakah aku boleh pergi?',
      );
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('SAYA AKAN MELINDUNGI ANDA!'),
        'AKU AKAN MELINDUNGI KAU!',
      );

      // Verify that words containing "saya" are NOT corrupted (e.g. sayap, sayang, rekayasa)
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('Burung itu memiliki sayap yang indah, sayangku.'),
        'Burung itu memiliki sayap yang indah, sayangku.',
      );
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('Ini semua bukan rekayasa saya.'),
        'Ini semua bukan rekayasa aku.',
      );

      // Verify kamulah / andalah -> kaulah (smart capitalization)
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('Kamulah yang terpilih untuk misi ini.'),
        'Kaulah yang terpilih untuk misi ini.',
      );
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('Karena andalah satu-satunya harapan kami.'),
        'Karena kaulah satu-satunya harapan kami.',
      );
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('sebab kamulah pemenangnya dan andalah juaranya.'),
        'sebab kaulah pemenangnya dan kaulah juaranya.',
      );
      expect(
        SubtitleTranslatorService.refineIndonesianPronouns('KAMULAH RAJA KAMI! ANDALAH PAHLAWAN SEJATI!'),
        'KAULAH RAJA KAMI! KAULAH PAHLAWAN SEJATI!',
      );
    });

    test('balanceSubtitleLines wraps long lines at natural word boundaries without clipping', () {
      // 1. Short text should not be wrapped
      const shortText = 'Halo teman-teman sekalian.';
      expect(SubtitleTranslatorService.balanceSubtitleLines(shortText), shortText);

      // 2. Long text (>42 chars) should be split into balanced lines
      const longText = 'Tetapi aku rasa kita harus segera pergi ke tempat itu sebelum semuanya terlambat.';
      final balanced = SubtitleTranslatorService.balanceSubtitleLines(longText, maxLineChars: 42);
      expect(balanced.contains('\n'), isTrue);

      final lines = balanced.split('\n');
      expect(lines.length, 2);
      for (final line in lines) {
        expect(line.length <= 45, isTrue);
      }
      // Re-joining words should match original words
      expect(balanced.replaceAll('\n', ' '), longText);

      // 3. Multi-line text with one long line
      const multi = 'Halo.\nTetapi aku rasa kita harus segera pergi ke tempat itu sebelum semuanya terlambat.';
      final multiBalanced = SubtitleTranslatorService.balanceSubtitleLines(multi, maxLineChars: 42);
      final multiLines = multiBalanced.split('\n');
      expect(multiLines.length, 3);
      expect(multiLines[0], 'Halo.');
    });

    test('smartFormatIndonesianSubtitle cleans chaotic casing, capitalizes sentences, sacred names and places', () {
      // 1. Chaotic mixed casing normalized & capitalized at start of sentence
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('KAmi sedang berjalan di taman.'),
        'Kami sedang berjalan di taman.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('KAMI SUDAH SIAP. BAGAIMANA DENGAN KALIAN?'),
        'Kami sudah siap. Bagaimana dengan kalian?',
      );

      // 2. Capitalization after dot '.' and dialogue dashes '-'
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('- apa yang terjadi? - KAMI tidak tahu.'),
        '- Apa yang terjadi? - Kami tidak tahu.',
      );

      // 3. Sacred names of God / Tuhan
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('tuhan tolong kami!'),
        'Tuhan tolong kami!',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('semoga TUHAN memberkati kamu sekalian.'),
        'Semoga Tuhan memberkati kamu sekalian.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('ya allah, lindungi kami.'),
        'Ya Allah, lindungi kami.',
      );

      // 4. Street names, places and honorifics followed by names
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('jalan sudirman sangat macet hari ini.'),
        'Jalan Sudirman sangat macet hari ini.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('apakah dokter smith dan kapten miller sudah tiba di new york?'),
        'Apakah Dokter Smith dan Kapten Miller sudah tiba di New York?',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('dia tinggal di kota bandung bersama paman sam.'),
        'Dia tinggal di Kota Bandung bersama Paman Sam.',
      );

      // 5. Acronyms & hyphenated proper names
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('kami melihat agen fbi di bandara soekarno-hatta.'),
        'Kami melihat agen FBI di Bandara Soekarno-Hatta.',
      );

      // 6. Days, months and islands
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('senin depan kita akan pergi ke pulau bali.'),
        'Senin depan kita akan pergi ke Pulau Bali.',
      );

      // 7. Reduplication at start of sentence vs middle of sentence
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('anak-anak sedang bermain di taman.'),
        'Anak-anak sedang bermain di taman.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('kami menjaga anak-anak di taman.'),
        'Kami menjaga anak-anak di taman.',
      );
    });
  });
}
