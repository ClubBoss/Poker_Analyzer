const Map<String, String> kMistakeCategoryTranslations = {
  'Overfold': 'Чрезмерный пас',
  'Overcall': 'Слишком широкий колл',
  'Wrong Push': 'Неверный пуш',
  'Wrong Call': 'Неверный колл',
  'Missed Value': 'Упущенное вэлью',
  'Too Passive': 'Слишком пассивно',
  'Too Aggro': 'Слишком агрессивно',
  'Unclassified': 'Без категории',
};

String translateMistakeCategory(String? category) {
  if (category == null) return '';
  return kMistakeCategoryTranslations[category] ?? category;
}
