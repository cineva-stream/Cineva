/// Model representing a subtitle language with its ISO-639 code and country flag.
class SubtitleLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String countryCode;
  final bool isOff;

  const SubtitleLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.countryCode,
    this.isOff = false,
  });

  /// Label shown in minimal subtitle listings
  String get displayName => isOff ? name : '$name ($nativeName)';
}

/// Comprehensive catalog of 65+ world languages for subtitles.
class SubtitleLanguageCatalog {
  static const List<SubtitleLanguage> languages = [
    SubtitleLanguage(
      code: 'id',
      name: 'Indonesia',
      nativeName: 'Bahasa Indonesia',
      countryCode: 'ID',
    ),
    SubtitleLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English (US)',
      countryCode: 'US',
    ),
    SubtitleLanguage(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      countryCode: 'ES',
    ),
    SubtitleLanguage(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      countryCode: 'FR',
    ),
    SubtitleLanguage(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      countryCode: 'DE',
    ),
    SubtitleLanguage(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      countryCode: 'JP',
    ),
    SubtitleLanguage(
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
      countryCode: 'KR',
    ),
    SubtitleLanguage(
      code: 'zh',
      name: 'Chinese (Simplified)',
      nativeName: '简体中文',
      countryCode: 'CN',
    ),
    SubtitleLanguage(
      code: 'zh-TW',
      name: 'Chinese (Traditional)',
      nativeName: '繁體中文',
      countryCode: 'TW',
    ),
    SubtitleLanguage(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      countryCode: 'SA',
    ),
    SubtitleLanguage(
      code: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
      countryCode: 'RU',
    ),
    SubtitleLanguage(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      countryCode: 'BR',
    ),
    SubtitleLanguage(
      code: 'it',
      name: 'Italian',
      nativeName: 'Italiano',
      countryCode: 'IT',
    ),
    SubtitleLanguage(
      code: 'tr',
      name: 'Turkish',
      nativeName: 'Türkçe',
      countryCode: 'TR',
    ),
    SubtitleLanguage(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      countryCode: 'IN',
    ),
    SubtitleLanguage(
      code: 'th',
      name: 'Thai',
      nativeName: 'ไทย',
      countryCode: 'TH',
    ),
    SubtitleLanguage(
      code: 'vi',
      name: 'Vietnamese',
      nativeName: 'Tiếng Việt',
      countryCode: 'VN',
    ),
    SubtitleLanguage(
      code: 'nl',
      name: 'Dutch',
      nativeName: 'Nederlands',
      countryCode: 'NL',
    ),
    SubtitleLanguage(
      code: 'pl',
      name: 'Polish',
      nativeName: 'Polski',
      countryCode: 'PL',
    ),
    SubtitleLanguage(
      code: 'sv',
      name: 'Swedish',
      nativeName: 'Svenska',
      countryCode: 'SE',
    ),
    SubtitleLanguage(
      code: 'da',
      name: 'Danish',
      nativeName: 'Dansk',
      countryCode: 'DK',
    ),
    SubtitleLanguage(
      code: 'fi',
      name: 'Finnish',
      nativeName: 'Suomi',
      countryCode: 'FI',
    ),
    SubtitleLanguage(
      code: 'no',
      name: 'Norwegian',
      nativeName: 'Norsk',
      countryCode: 'NO',
    ),
    SubtitleLanguage(
      code: 'el',
      name: 'Greek',
      nativeName: 'Ελληνικά',
      countryCode: 'GR',
    ),
    SubtitleLanguage(
      code: 'he',
      name: 'Hebrew',
      nativeName: 'עברית',
      countryCode: 'IL',
    ),
    SubtitleLanguage(
      code: 'cs',
      name: 'Czech',
      nativeName: 'Čeština',
      countryCode: 'CZ',
    ),
    SubtitleLanguage(
      code: 'hu',
      name: 'Hungarian',
      nativeName: 'Magyar',
      countryCode: 'HU',
    ),
    SubtitleLanguage(
      code: 'ro',
      name: 'Romanian',
      nativeName: 'Română',
      countryCode: 'RO',
    ),
    SubtitleLanguage(
      code: 'uk',
      name: 'Ukrainian',
      nativeName: 'Українська',
      countryCode: 'UA',
    ),
    SubtitleLanguage(
      code: 'ms',
      name: 'Malay',
      nativeName: 'Bahasa Melayu',
      countryCode: 'MY',
    ),
    SubtitleLanguage(
      code: 'tl',
      name: 'Filipino / Tagalog',
      nativeName: 'Tagalog',
      countryCode: 'PH',
    ),
    SubtitleLanguage(
      code: 'bn',
      name: 'Bengali',
      nativeName: 'বাংলা',
      countryCode: 'BD',
    ),
    SubtitleLanguage(
      code: 'fa',
      name: 'Persian',
      nativeName: 'فارسی',
      countryCode: 'IR',
    ),
    SubtitleLanguage(
      code: 'ur',
      name: 'Urdu',
      nativeName: 'اردو',
      countryCode: 'PK',
    ),
    SubtitleLanguage(
      code: 'ta',
      name: 'Tamil',
      nativeName: 'தமிழ்',
      countryCode: 'IN',
    ),
    SubtitleLanguage(
      code: 'te',
      name: 'Telugu',
      nativeName: 'తెలుగు',
      countryCode: 'IN',
    ),
    SubtitleLanguage(
      code: 'mr',
      name: 'Marathi',
      nativeName: 'मराठी',
      countryCode: 'IN',
    ),
    SubtitleLanguage(
      code: 'gu',
      name: 'Gujarati',
      nativeName: 'ગુજરાતી',
      countryCode: 'IN',
    ),
    SubtitleLanguage(
      code: 'pa',
      name: 'Punjabi',
      nativeName: 'ਪੰਜਾਬੀ',
      countryCode: 'IN',
    ),
    SubtitleLanguage(
      code: 'ml',
      name: 'Malayalam',
      nativeName: 'മലയാളം',
      countryCode: 'IN',
    ),
    SubtitleLanguage(
      code: 'kn',
      name: 'Kannada',
      nativeName: 'ಕನ್ನಡ',
      countryCode: 'IN',
    ),
    SubtitleLanguage(
      code: 'my',
      name: 'Burmese',
      nativeName: 'ဗမာစာ',
      countryCode: 'MM',
    ),
    SubtitleLanguage(
      code: 'km',
      name: 'Khmer',
      nativeName: 'ភាសាខ្មែរ',
      countryCode: 'KH',
    ),
    SubtitleLanguage(
      code: 'lo',
      name: 'Lao',
      nativeName: 'ພາສາລາວ',
      countryCode: 'LA',
    ),
    SubtitleLanguage(
      code: 'hr',
      name: 'Croatian',
      nativeName: 'Hrvatski',
      countryCode: 'HR',
    ),
    SubtitleLanguage(
      code: 'sr',
      name: 'Serbian',
      nativeName: 'Srpski',
      countryCode: 'RS',
    ),
    SubtitleLanguage(
      code: 'sk',
      name: 'Slovak',
      nativeName: 'Slovenčina',
      countryCode: 'SK',
    ),
    SubtitleLanguage(
      code: 'bg',
      name: 'Bulgarian',
      nativeName: 'Български',
      countryCode: 'BG',
    ),
    SubtitleLanguage(
      code: 'sl',
      name: 'Slovenian',
      nativeName: 'Slovenščina',
      countryCode: 'SI',
    ),
    SubtitleLanguage(
      code: 'lt',
      name: 'Lithuanian',
      nativeName: 'Lietuvių',
      countryCode: 'LT',
    ),
    SubtitleLanguage(
      code: 'lv',
      name: 'Latvian',
      nativeName: 'Latviešu',
      countryCode: 'LV',
    ),
    SubtitleLanguage(
      code: 'et',
      name: 'Estonian',
      nativeName: 'Eesti',
      countryCode: 'EE',
    ),
    SubtitleLanguage(
      code: 'is',
      name: 'Icelandic',
      nativeName: 'Íslenska',
      countryCode: 'IS',
    ),
    SubtitleLanguage(
      code: 'sq',
      name: 'Albanian',
      nativeName: 'Shqip',
      countryCode: 'AL',
    ),
    SubtitleLanguage(
      code: 'ka',
      name: 'Georgian',
      nativeName: 'ქართული',
      countryCode: 'GE',
    ),
    SubtitleLanguage(
      code: 'hy',
      name: 'Armenian',
      nativeName: 'Հայերեն',
      countryCode: 'AM',
    ),
    SubtitleLanguage(
      code: 'az',
      name: 'Azerbaijani',
      nativeName: 'Azərbaycan',
      countryCode: 'AZ',
    ),
    SubtitleLanguage(
      code: 'kk',
      name: 'Kazakh',
      nativeName: 'Қазақ',
      countryCode: 'KZ',
    ),
    SubtitleLanguage(
      code: 'uz',
      name: 'Uzbek',
      nativeName: 'Oʻzbek',
      countryCode: 'UZ',
    ),
    SubtitleLanguage(
      code: 'mn',
      name: 'Mongolian',
      nativeName: 'Монгол',
      countryCode: 'MN',
    ),
    SubtitleLanguage(
      code: 'sw',
      name: 'Swahili',
      nativeName: 'Kiswahili',
      countryCode: 'KE',
    ),
    SubtitleLanguage(
      code: 'af',
      name: 'Afrikaans',
      nativeName: 'Afrikaans',
      countryCode: 'ZA',
    ),
    SubtitleLanguage(
      code: 'ca',
      name: 'Catalan',
      nativeName: 'Català',
      countryCode: 'ES',
    ),
    SubtitleLanguage(
      code: 'ga',
      name: 'Irish',
      nativeName: 'Gaeilge',
      countryCode: 'IE',
    ),
    SubtitleLanguage(
      code: 'cy',
      name: 'Welsh',
      nativeName: 'Cymraeg',
      countryCode: 'GB',
    ),
    SubtitleLanguage(
      code: 'off',
      name: 'Nonaktif / Off',
      nativeName: 'Matikan Subtitle Bawaan',
      countryCode: '',
      isOff: true,
    ),
  ];

  static const Map<String, String> _indonesianAliases = {
    'jepang': 'ja',
    'inggris': 'en',
    'jerman': 'de',
    'prancis': 'fr',
    'korea': 'ko',
    'spanyol': 'es',
    'arab': 'ar',
    'rusia': 'ru',
    'tiongkok': 'zh',
    'cina': 'zh',
    'belanda': 'nl',
    'italia': 'it',
    'turki': 'tr',
    'vietnam': 'vi',
    'thailand': 'th',
    'portugis': 'pt',
    'yunani': 'el',
    'swedia': 'sv',
    'norwegia': 'no',
    'filipina': 'tl',
    'tagalog': 'tl',
    'indonesia': 'id',
  };

  static SubtitleLanguage findByCode(String code) {
    return languages.firstWhere(
      (lang) => lang.code.toLowerCase() == code.toLowerCase(),
      orElse: () => languages.first, // defaults to Indonesian
    );
  }

  static List<SubtitleLanguage> search(String query) {
    if (query.trim().isEmpty) return languages;
    final q = query.trim().toLowerCase();
    final aliasCode = _indonesianAliases[q];
    return languages.where((lang) {
      if (aliasCode != null && lang.code.toLowerCase() == aliasCode) {
        return true;
      }
      return lang.name.toLowerCase().contains(q) ||
          lang.nativeName.toLowerCase().contains(q) ||
          lang.code.toLowerCase() == q ||
          lang.countryCode.toLowerCase() == q;
    }).toList();
  }
}
