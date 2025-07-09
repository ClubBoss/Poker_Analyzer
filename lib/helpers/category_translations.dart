const Map<String, String> kCategoryTranslations = {
  'Push/Fold': 'Пуш/Фолд',
  'Postflop': 'Постфлоп',
  'ICM': 'ICM',
};

String translateCategory(String? category) {
  if (category == null) return '';
  return kCategoryTranslations[category] ?? category;
}
