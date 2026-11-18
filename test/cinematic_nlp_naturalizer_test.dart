import 'package:cineva/features/player/data/services/subtitle_translator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cinematic NLP Post-Processing Engine Tests', () {
    test('Naturalizes literal English idioms to natural Indonesian film dialogue', () {
      // "I got your back" -> "melindungimu"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Jangan khawatir, aku punya punggungmu.'),
        'Jangan khawatir, aku melindungimu.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Dia punya punggungku saat patroli.'),
        'Dia melindungiku saat patroli.',
      );

      // "Give me a break" -> "yang benar saja"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Beri aku istirahat, itu masuk akal.'),
        'Yang benar saja, masuk akal.',
      );

      // "Heads up" -> "awas"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Kepala ke atas! Ada mobil melaju kencang.'),
        'Awas! Ada mobil melaju kencang.',
      );

      // "Call it a day" -> "cukup untuk hari ini"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Mari kita sebut itu sehari.'),
        'Mari kita cukup untuk hari ini.',
      );

      // "Piece of cake" -> "sangat mudah" / "tidak mudah"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Ujian ini bukan sepotong kue.'),
        'Ujian ini tidak mudah.',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Misi ini sepotong kue bagi kita.'),
        'Misi ini sangat mudah bagi kita.',
      );

      // "In the same boat" -> "senasib"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Kita berada di kapal yang sama sekarang.'),
        'Kita senasib sekarang.',
      );

      // "Under the weather" -> "kurang enak badan"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Aku sedang di bawah cuaca hari ini.'),
        'Aku sedang kurang enak badan hari ini.',
      );

      // "Pulling your leg" -> "hanya bercanda"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Tenanglah, aku hanya tarik kakimu.'),
        'Tenanglah, aku hanya bercanda.',
      );

      // "Out of the question" -> "mustahil"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Rencana itu keluar dari pertanyaan.'),
        'Rencana itu mustahil.',
      );
    });

    test('Naturalizes police, crime & action shows (The Rookie, SWAT, FBI)', () {
      // "Copy that" -> "dimengerti"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Salin itu, kami butuh cadangan sekarang!'),
        'Dimengerti, kami butuh bantuan sekarang!',
      );

      // "Hold your fire" -> "tahan tembakan"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Pegang apimu, jangan tembak!'),
        'Tahan tembakan, jangan tembak!',
      );

      // "Shots fired" -> "ada tembakan"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Semua unit, tembakan dilepaskan di sektor 4!'),
        'Semua unit, ada tembakan di sektor 4!',
      );

      // "Suspect in custody" -> "tersangka sudah diamankan"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Tersangka dalam tahanan oleh petugas L.A.P.D.'),
        'Tersangka sudah diamankan oleh petugas L.A.P.D.',
      );

      // "On my way" -> "aku segera ke sana"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Tenanglah, dalam perjalanan saya ke TKP.'),
        'Tenanglah, aku segera ke sana ke TKP.',
      );

      // "All clear" -> "area aman"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Lantai dua semua bersih.'),
        'Lantai dua area aman.',
      );

      // "Drop your weapon" & "Don't move"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Jatuhkan senjatamu dan jangan bergerak!'),
        'Jatuhkan senjatamu dan jangan bergerak!',
      );
    });

    test('Smooths stiff robotic phrasing into conversational film dialogue', () {
      // "I don't think so" -> "kurasa tidak"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Aku tidak berpikir begitu.'),
        'Kurasa tidak.',
      );

      // "I think" -> "kurasa"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Aku pikir kita harus segera pergi.'),
        'Kurasa kita harus segera pergi.',
      );

      // "That makes sense" -> "masuk akal"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Penjelasanmu, itu masuk akal.'),
        'Penjelasanmu, masuk akal.',
      );

      // "That doesn't make sense" -> "tak masuk akal"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Semua bukti ini, tidak masuk akal!'),
        'Semua bukti ini, tak masuk akal!',
      );

      // "That's okay / alright" -> "tak apa"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Itu tidak apa-apa, jangan khawatir tentang itu.'),
        'Tak apa, jangan khawatir.',
      );

      // "There you are" -> "rupanya kau di sana"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Di sanalah kau berada, aku mencarimu kemana-mana.'),
        'Rupanya kau di sana, aku mencarimu kemana-mana.',
      );

      // "What are you talking about?" -> "kau bicara apa"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Apa yang sedang kau bicarakan?'),
        'Kau bicara apa?',
      );

      // "What are you waiting for?" -> "tunggu apa lagi"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Ayo cepat, apa yang kau tunggu?'),
        'Ayo cepat, tunggu apa lagi?',
      );

      // "You're welcome" -> "sama-sama"
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('Kau dipersilakan, kawan.'),
        'Sama-sama, kawan.',
      );
    });

    test('Preserves casing (ALL CAPS, TitleCase, lowercase) faithfully', () {
      // Direct naturalizer preserves ALL CAPS
      expect(
        SubtitleTranslatorService.applyCinematicIndonesianNaturalizer('PEGANG APIMU! ANGKAT TANGANMU!'),
        'TAHAN TEMBAKAN! ANGKAT TANGAN!',
      );
      expect(
        SubtitleTranslatorService.applyCinematicIndonesianNaturalizer('SALIN ITU, KAMI BUTUH CADANGAN!'),
        'DIMENGERTI, KAMI BUTUH BANTUAN!',
      );

      // smartFormatIndonesianSubtitle normalizes all-caps shouting to clean sentence case
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('PEGANG APIMU! ANGKAT TANGANMU!'),
        'Tahan tembakan! Angkat tangan!',
      );
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('SALIN ITU, KAMI BUTUH CADANGAN!'),
        'Dimengerti, kami butuh bantuan!',
      );

      // Dialogue dashes with TitleCase
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('- Salin itu. - Pegang apimu!'),
        '- Dimengerti. - Tahan tembakan!',
      );

      // Lowercase in mid-sentence
      expect(
        SubtitleTranslatorService.smartFormatIndonesianSubtitle('dia bilang aku tidak berpikir begitu.'),
        'Dia bilang kurasa tidak.',
      );
    });

    test('Seamless combination of Pronoun refinement, Naturalizer, and Abbreviation formatting', () {
      // Full pipeline test
      const rawStream = 'Salin itu, petugas l.A.P.D! Aku pikir kamu berada di kapal yang sama, jadi jangan khawatir, aku punya punggungmu.';
      final refined = SubtitleTranslatorService.refineIndonesianPronouns(rawStream);
      final formatted = SubtitleTranslatorService.smartFormatIndonesianSubtitle(refined);

      expect(
        formatted,
        'Dimengerti, petugas L.A.P.D! Kurasa kau senasib, jadi jangan khawatir, aku melindungimu.',
      );
    });
  });
}
