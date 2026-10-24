enum AppLanguage {
  id('id', 'Bahasa Indonesia', 'ID', 'Indonesia'),
  en('en', 'English (US)', 'US', 'English');

  final String code;
  final String displayName;
  final String flagCountryCode;
  final String label;

  const AppLanguage(this.code, this.displayName, this.flagCountryCode, this.label);

  static AppLanguage fromCode(String? code) {
    if (code == 'en') return AppLanguage.en;
    return AppLanguage.id;
  }
}
