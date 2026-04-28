class Locale {
  final String language;
  final String country;

  const Locale({
    required this.language,
    required this.country,
  });

  static const english = Locale(language: 'en', country: '');
  static const us = Locale(language: 'en', country: 'US');
  static const uk = Locale(language: 'en', country: 'GB');
}
