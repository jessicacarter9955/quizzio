class Language {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  static const List<Language> supported = [
    Language(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧'),
    Language(code: 'it', name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
    Language(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    Language(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    Language(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    Language(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      flag: '🇵🇹',
    ),
    Language(code: 'ru', name: 'Russian', nativeName: 'Русский', flag: '🇷🇺'),
    Language(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    Language(code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
    Language(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
    Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    Language(code: 'ko', name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
    Language(code: 'tr', name: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷'),
    Language(code: 'pl', name: 'Polish', nativeName: 'Polski', flag: '🇵🇱'),
    Language(code: 'nl', name: 'Dutch', nativeName: 'Nederlands', flag: '🇳🇱'),
    Language(code: 'sv', name: 'Swedish', nativeName: 'Svenska', flag: '🇸🇪'),
    Language(code: 'no', name: 'Norwegian', nativeName: 'Norsk', flag: '🇳🇴'),
    Language(code: 'da', name: 'Danish', nativeName: 'Dansk', flag: '🇩🇰'),
    Language(code: 'fi', name: 'Finnish', nativeName: 'Suomi', flag: '🇫🇮'),
    Language(code: 'cs', name: 'Czech', nativeName: 'Čeština', flag: '🇨🇿'),
    Language(code: 'hu', name: 'Hungarian', nativeName: 'Magyar', flag: '🇭🇺'),
    Language(code: 'ro', name: 'Romanian', nativeName: 'Română', flag: '🇷🇴'),
    Language(
      code: 'bg',
      name: 'Bulgarian',
      nativeName: 'Български',
      flag: '🇧🇬',
    ),
    Language(
      code: 'hr',
      name: 'Croatian',
      nativeName: 'Hrvatski',
      flag: '🇭🇷',
    ),
    Language(
      code: 'sk',
      name: 'Slovak',
      nativeName: 'Slovenčina',
      flag: '🇸🇰',
    ),
    Language(
      code: 'sl',
      name: 'Slovenian',
      nativeName: 'Slovenščina',
      flag: '🇸🇮',
    ),
    Language(code: 'et', name: 'Estonian', nativeName: 'Eesti', flag: '🇪🇪'),
    Language(code: 'lv', name: 'Latvian', nativeName: 'Latviešu', flag: '🇱🇻'),
    Language(
      code: 'lt',
      name: 'Lithuanian',
      nativeName: 'Lietuvių',
      flag: '🇱🇹',
    ),
    Language(code: 'mt', name: 'Maltese', nativeName: 'Malti', flag: '🇲🇹'),
    Language(code: 'ga', name: 'Irish', nativeName: 'Gaeilge', flag: '🇮🇪'),
    Language(
      code: 'cy',
      name: 'Welsh',
      nativeName: 'Cymraeg',
      flag: '🏴󠁧󠁢󠁷󠁬󠁳󠁿',
    ),
    Language(
      code: 'eu',
      name: 'Basque',
      nativeName: 'Euskara',
      flag: '🏴󠁥󠁳󠁰󠁶󠁿',
    ),
    Language(
      code: 'ca',
      name: 'Catalan',
      nativeName: 'Català',
      flag: '🏴󠁥󠁳󠁣󠁴󠁿',
    ),
    Language(
      code: 'gl',
      name: 'Galician',
      nativeName: 'Galego',
      flag: '🏴󠁥󠁳󠁣󠁴󠁿',
    ),
    Language(
      code: 'is',
      name: 'Icelandic',
      nativeName: 'Íslenska',
      flag: '🇮🇸',
    ),
    Language(
      code: 'mk',
      name: 'Macedonian',
      nativeName: 'Македонски',
      flag: '🇲🇰',
    ),
    Language(code: 'sr', name: 'Serbian', nativeName: 'Српски', flag: '🇷🇸'),
    Language(code: 'bs', name: 'Bosnian', nativeName: 'Bosanski', flag: '🇧🇦'),
    Language(
      code: 'me',
      name: 'Montenegrin',
      nativeName: 'Crnogorski',
      flag: '🇲🇪',
    ),
    Language(code: 'sq', name: 'Albanian', nativeName: 'Shqip', flag: '🇦🇱'),
    Language(
      code: 'uk',
      name: 'Ukrainian',
      nativeName: 'Українська',
      flag: '🇺🇦',
    ),
    Language(
      code: 'be',
      name: 'Belarusian',
      nativeName: 'Беларуская',
      flag: '🇧🇾',
    ),
    Language(code: 'hy', name: 'Armenian', nativeName: 'Հայերեն', flag: '🇦🇲'),
    Language(code: 'ka', name: 'Georgian', nativeName: 'ქართული', flag: '🇬🇪'),
    Language(code: 'he', name: 'Hebrew', nativeName: 'עברית', flag: '🇮🇱'),
    Language(code: 'fa', name: 'Persian', nativeName: 'فارسی', flag: '🇮🇷'),
    Language(code: 'ur', name: 'Urdu', nativeName: 'اردو', flag: '🇵🇰'),
    Language(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', flag: '🇧🇩'),
    Language(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', flag: '🇱🇰'),
    Language(code: 'te', name: 'Telugu', nativeName: 'తెలుగు', flag: '🇮🇳'),
    Language(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം', flag: '🇮🇳'),
    Language(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ', flag: '🇮🇳'),
    Language(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી', flag: '🇮🇳'),
    Language(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ', flag: '🇮🇳'),
    Language(code: 'mr', name: 'Marathi', nativeName: 'मराठी', flag: '🇮🇳'),
    Language(code: 'ne', name: 'Nepali', nativeName: 'नेपाली', flag: '🇳🇵'),
    Language(code: 'si', name: 'Sinhala', nativeName: 'සිංහල', flag: '🇱🇰'),
    Language(code: 'my', name: 'Myanmar', nativeName: 'မြန်မာ', flag: '🇲🇲'),
    Language(code: 'km', name: 'Khmer', nativeName: 'ខ្មែរ', flag: '🇰🇭'),
    Language(code: 'lo', name: 'Lao', nativeName: 'ລາວ', flag: '🇱🇦'),
    Language(code: 'th', name: 'Thai', nativeName: 'ไทย', flag: '🇹🇭'),
    Language(
      code: 'vi',
      name: 'Vietnamese',
      nativeName: 'Tiếng Việt',
      flag: '🇻🇳',
    ),
    Language(
      code: 'id',
      name: 'Indonesian',
      nativeName: 'Bahasa Indonesia',
      flag: '🇮🇩',
    ),
    Language(
      code: 'ms',
      name: 'Malay',
      nativeName: 'Bahasa Melayu',
      flag: '🇲🇾',
    ),
    Language(
      code: 'tl',
      name: 'Filipino',
      nativeName: 'Filipino',
      flag: '🇵🇭',
    ),
    Language(
      code: 'sw',
      name: 'Swahili',
      nativeName: 'Kiswahili',
      flag: '🇰🇪',
    ),
    Language(code: 'zu', name: 'Zulu', nativeName: 'IsiZulu', flag: '🇿🇦'),
    Language(
      code: 'af',
      name: 'Afrikaans',
      nativeName: 'Afrikaans',
      flag: '🇿🇦',
    ),
    Language(code: 'am', name: 'Amharic', nativeName: 'አማርኛ', flag: '🇪🇹'),
    Language(code: 'so', name: 'Somali', nativeName: 'Soomaali', flag: '🇸🇴'),
    Language(code: 'ha', name: 'Hausa', nativeName: 'Hausa', flag: '🇳🇬'),
    Language(code: 'yo', name: 'Yoruba', nativeName: 'Yorùbá', flag: '🇳🇬'),
    Language(code: 'ig', name: 'Igbo', nativeName: 'Igbo', flag: '🇳🇬'),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Language($code, $name)';
}
