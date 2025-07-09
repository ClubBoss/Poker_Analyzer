const Map<String, String> kCategoryTranslations = {
  'Push/Fold': 'Пуш/Фолд',
  'Postflop': 'Постфлоп',
  'ICM': 'ICM',
  '3bet': '3-бет',
};

String translateCategory(String? category) {
  if (category == null) return '';
  return kCategoryTranslations[category] ?? category;
}
