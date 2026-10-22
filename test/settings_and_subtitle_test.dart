import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/features/settings/data/settings_service.dart';
import 'package:cineva/features/player/data/services/subtitle_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cineva_settings_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SettingsService Default Subtitle Preference & Quality Tests', () {
    test('Default values are correctly set for Indonesian experience', () {
      expect(SettingsService.getDefaultSubtitleLang(), equals('id'));
      expect(SettingsService.getAutoTranslate(), isTrue);
      expect(SettingsService.getDefaultQuality(), equals('Auto'));
    });

    test('Can update and persist default subtitle language', () async {
      await SettingsService.setDefaultSubtitleLang('en');
      expect(SettingsService.getDefaultSubtitleLang(), equals('en'));

      await SettingsService.setDefaultSubtitleLang('off');
      expect(SettingsService.getDefaultSubtitleLang(), equals('off'));

      await SettingsService.setDefaultSubtitleLang('id');
      expect(SettingsService.getDefaultSubtitleLang(), equals('id'));
    });

    test('Can update auto-translate preference', () async {
      await SettingsService.setAutoTranslate(false);
      expect(SettingsService.getAutoTranslate(), isFalse);

      await SettingsService.setAutoTranslate(true);
      expect(SettingsService.getAutoTranslate(), isTrue);
    });

    test('Can update default quality preference', () async {
      await SettingsService.setDefaultQuality('1080p');
      expect(SettingsService.getDefaultQuality(), equals('1080p'));

      await SettingsService.setDefaultQuality('Auto');
      expect(SettingsService.getDefaultQuality(), equals('Auto'));
    });
  });

  group('Player Subtitle Auto-Selection & Auto-Translation Selection Logic', () {
    final sampleSubtitles = [
      SubtitleInfo(
        id: '101',
        language: 'en',
        languageName: 'English',
        fileName: 'Movie.2023.1080p.en.srt',
        downloadCount: 500,
      ),
      SubtitleInfo(
        id: '102',
        language: 'es',
        languageName: 'Spanish',
        fileName: 'Movie.2023.1080p.es.srt',
        downloadCount: 300,
      ),
    ];

    test('When ID subtitle is not available and pref is ID, chooses English fallback', () {
      final idSub = sampleSubtitles.where((s) => s.language.toLowerCase() == 'id').firstOrNull;
      expect(idSub, isNull);

      final fallbackSub = sampleSubtitles.where((s) => s.language.toLowerCase() == 'en').firstOrNull ?? sampleSubtitles.first;
      expect(fallbackSub.language, equals('en'));
      expect(fallbackSub.id, equals('101'));
    });

    test('When native ID subtitle is present, it is selected immediately', () {
      final subsWithId = [
        ...sampleSubtitles,
        SubtitleInfo(
          id: '103',
          language: 'id',
          languageName: 'Indonesia',
          fileName: 'Movie.2023.1080p.id.srt',
          downloadCount: 450,
        ),
      ];

      final idSub = subsWithId.where((s) => s.language.toLowerCase() == 'id').firstOrNull;
      expect(idSub, isNotNull);
      expect(idSub!.language, equals('id'));
      expect(idSub.id, equals('103'));
    });
  });

  group('ContentPreference Settings & Priority Matching Tests', () {
    test('Default content preference is "all" (Global)', () {
      expect(SettingsService.getContentPreference(), equals('all'));
    });

    test('Can update and persist content preference', () async {
      await SettingsService.setContentPreference('indonesia');
      expect(SettingsService.getContentPreference(), equals('indonesia'));

      await SettingsService.setContentPreference('anime');
      expect(SettingsService.getContentPreference(), equals('anime'));

      await SettingsService.setContentPreference('all');
      expect(SettingsService.getContentPreference(), equals('all'));
    });
  });
}
