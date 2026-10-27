import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/features/profile/domain/models/user_profile.dart';
import 'package:cineva/features/profile/domain/models/avatar_catalog.dart';
import 'package:cineva/features/profile/data/profile_service.dart';
import 'package:cineva/features/profile/presentation/providers/profile_provider.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/core/localization/app_strings.dart';
import 'package:cineva/features/settings/data/settings_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cineva_profile_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await ProfileService.resetProfile();
  });

  group('UserProfile Model Tests', () {
    test('defaultProfile returns default movie fan profile', () {
      final profile = UserProfile.defaultProfile();
      expect(profile.name, 'Penikmat Film');
      expect(profile.username, 'cineva_fan');
      expect(profile.avatarId, 'avatar_popcorn');
      expect(profile.customAvatarPath, isNull);
      expect(profile.isConfigured, isFalse);
    });

    test('toMap and fromMap serialize and deserialize properly', () {
      final original = UserProfile(
        name: 'Wisnu Pratama',
        username: 'wisnu99',
        avatarId: 'avatar_hero',
        customAvatarPath: '/path/to/avatar.png',
        createdAt: DateTime(2026, 10, 27),
        isConfigured: true,
      );

      final map = original.toMap();
      final restored = UserProfile.fromMap(map);

      expect(restored.name, 'Wisnu Pratama');
      expect(restored.username, 'wisnu99');
      expect(restored.avatarId, 'avatar_hero');
      expect(restored.customAvatarPath, '/path/to/avatar.png');
      expect(restored.isConfigured, isTrue);
    });

    test('copyWith updates specified fields and supports clearing custom avatar', () {
      final base = UserProfile.defaultProfile().copyWith(
        avatarId: 'custom',
        customAvatarPath: '/path/to/img.png',
      );

      final updated = base.copyWith(
        avatarId: 'avatar_cyber',
        clearCustomAvatar: true,
      );

      expect(updated.avatarId, 'avatar_cyber');
      expect(updated.customAvatarPath, isNull);
    });
  });

  group('AvatarCatalog Tests', () {
    test('contains exactly 10 cinematic presets', () {
      expect(AvatarCatalog.presets.length, 10);
    });

    test('getById returns matching preset or fallback', () {
      final hero = AvatarCatalog.getById('avatar_hero');
      expect(hero.name, 'Superhero Mask');

      final unknown = AvatarCatalog.getById('unknown_avatar');
      expect(unknown.id, 'avatar_popcorn');
    });
  });

  group('ProfileService Persistence Tests', () {
    test('getProfile returns default when storage is empty', () {
      expect(ProfileService.hasConfiguredProfile(), isFalse);
      final profile = ProfileService.getProfile();
      expect(profile.name, 'Penikmat Film');
    });

    test('saveProfile persists to Hive and retrieves accurately', () async {
      final toSave = UserProfile(
        name: 'Alex Cine',
        username: 'alexcine',
        avatarId: 'avatar_director',
        customAvatarPath: null,
        createdAt: DateTime.now(),
        isConfigured: true,
      );

      await ProfileService.saveProfile(toSave);
      expect(ProfileService.hasConfiguredProfile(), isTrue);

      final retrieved = ProfileService.getProfile();
      expect(retrieved.name, 'Alex Cine');
      expect(retrieved.username, 'alexcine');
      expect(retrieved.avatarId, 'avatar_director');
    });
  });

  group('UserProfileNotifier Riverpod Tests', () {
    test('updates name and username reactively', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProfileProvider.notifier);
      notifier.updateName('Dian');
      notifier.updateUsername('@dian_movie');

      final current = container.read(userProfileProvider);
      expect(current.name, 'Dian');
      expect(current.username, 'dian_movie');
    });

    test('selectPresetAvatar clears custom avatar path', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProfileProvider.notifier);
      notifier.setCustomAvatar('/local/file.png');
      expect(container.read(userProfileProvider).customAvatarPath, '/local/file.png');

      notifier.selectPresetAvatar('avatar_vip');
      expect(container.read(userProfileProvider).avatarId, 'avatar_vip');
      expect(container.read(userProfileProvider).customAvatarPath, isNull);
    });

    test('save commits and marks profile configured', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProfileProvider.notifier);
      await notifier.save(
        name: 'Sultan Film',
        username: 'sultan',
        avatarId: 'avatar_vip',
      );

      final current = container.read(userProfileProvider);
      expect(current.isConfigured, isTrue);
      expect(current.name, 'Sultan Film');
      expect(ProfileService.hasConfiguredProfile(), isTrue);
    });

    test('skipOnboarding marks configured as true with defaults', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProfileProvider.notifier);
      await notifier.skipOnboarding();

      final current = container.read(userProfileProvider);
      expect(current.isConfigured, isTrue);
      expect(ProfileService.hasConfiguredProfile(), isTrue);
    });
  });

  group('Language Selection & Profile Localization Tests', () {
    test('AppStrings contains distinct Indonesian and English strings for splash and profile', () {
      const stringsId = AppStrings(AppLanguage.id);
      const stringsEn = AppStrings(AppLanguage.en);

      expect(stringsId.splashSelectLanguage, 'Pilih Bahasa');
      expect(stringsEn.splashSelectLanguage, 'Select Language');

      expect(stringsId.splashStartWatching, 'Mulai Menonton');
      expect(stringsEn.splashStartWatching, 'Start Watching');

      expect(stringsId.profileCreateTitle, 'Buat Profil Cineva Anda');
      expect(stringsEn.profileCreateTitle, 'Create Your Cineva Profile');

      expect(stringsId.profileSkip, 'Lewati');
      expect(stringsEn.profileSkip, 'Skip');

      expect(stringsId.cropTitle, 'Sesuaikan Avatar');
      expect(stringsEn.cropTitle, 'Adjust Avatar');

      expect(stringsId.profileSaveAndEnter, 'Lanjut');
      expect(stringsEn.profileSaveAndEnter, 'Continue');

      expect(stringsId.legalAgreeButton, 'Setuju');
      expect(stringsEn.legalAgreeButton, 'Agree');
      expect(stringsId.legalAgreementTitle, 'Ketentuan Hukum & Privasi');
      expect(stringsEn.legalAgreementTitle, 'Terms & Privacy Policy');
    });

    test('SettingsService legal acceptance flags works correctly', () async {
      await SettingsService.setLegalAccepted(false);
      expect(SettingsService.hasAcceptedLegal(), isFalse);

      await SettingsService.setLegalAccepted(true);
      expect(SettingsService.hasAcceptedLegal(), isTrue);
    });

    test('appLanguageProvider reactively switches language and affects appStringsProvider', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en);
      expect(container.read(appLanguageProvider), AppLanguage.en);
      expect(container.read(appStringsProvider).splashStartWatching, 'Start Watching');
      expect(container.read(appStringsProvider).legalAgreeButton, 'Agree');

      await container.read(appLanguageProvider.notifier).setLanguage(AppLanguage.id);
      expect(container.read(appLanguageProvider), AppLanguage.id);
      expect(container.read(appStringsProvider).splashStartWatching, 'Mulai Menonton');
      expect(container.read(appStringsProvider).legalAgreeButton, 'Setuju');
    });
  });
}

