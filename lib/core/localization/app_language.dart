enum AppLanguage {
  id('id', 'Bahasa Indonesia', 'ID', 'Indonesia'),
  en('en', 'English (US)', 'US', 'English'),
  hi('hi', 'हिन्दी (India)', 'IN', 'India');

  final String code;
  final String displayName;
  final String flagCountryCode;
  final String label;

  const AppLanguage(this.code, this.displayName, this.flagCountryCode, this.label);

  bool get isIndonesian => this == AppLanguage.id;
  bool get isEnglish => this == AppLanguage.en;
  bool get isHindi => this == AppLanguage.hi;

  /// TMDB API language code corresponding to this app language.
  String get tmdbLanguageCode {
    switch (this) {
      case AppLanguage.id:
        return 'id-ID';
      case AppLanguage.en:
        return 'en-US';
      case AppLanguage.hi:
        return 'hi-IN';
    }
  }

  /// Returns the localized short label of this language according to [activeLanguage]:
  /// - For [AppLanguage.hi]: "India" when active language is Indonesian, "Hindi" when English, "हिन्दी" when Hindi.
  String localizedLabel(AppLanguage activeLanguage) {
    switch (this) {
      case AppLanguage.id:
        if (activeLanguage == AppLanguage.hi) return 'इंडोनेशियाई';
        return 'Indonesia';
      case AppLanguage.en:
        if (activeLanguage == AppLanguage.hi) return 'अंग्रेज़ी';
        return 'English';
      case AppLanguage.hi:
        if (activeLanguage == AppLanguage.id) return 'India';
        if (activeLanguage == AppLanguage.en) return 'Hindi';
        return 'हिन्दी';
    }
  }

  /// Returns the localized full display name for language selection modals according to [activeLanguage].
  String localizedDisplayName(AppLanguage activeLanguage) {
    switch (this) {
      case AppLanguage.id:
        return 'Bahasa Indonesia';
      case AppLanguage.en:
        return 'English (US)';
      case AppLanguage.hi:
        if (activeLanguage == AppLanguage.id) return 'India (हिन्दी)';
        if (activeLanguage == AppLanguage.en) return 'Hindi (हिन्दी)';
        return 'हिन्दी (भारत)';
    }
  }

  static AppLanguage fromCode(String? code) {
    final normalized = code?.trim().toLowerCase();
    if (normalized == 'en') return AppLanguage.en;
    if (normalized == 'hi' || normalized == 'in') return AppLanguage.hi;
    return AppLanguage.id;
  }
}
