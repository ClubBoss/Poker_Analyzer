import '../models/theory_pack_model.dart';

class TheoryPackAutoFixEngine {
  TheoryPackAutoFixEngine();

  TheoryPackModel autoFix(TheoryPackModel pack) {
    String clean(String v) => v.replaceAll(RegExp(r'\s+'), ' ').trim();

    final title = pack.title.trim().isEmpty ? '(untitled)' : clean(pack.title);
    final sections = <TheorySectionModel>[];
    for (final s in pack.sections) {
      final secTitle = clean(s.title);
      final text = clean(s.text);
      if (secTitle.isEmpty) continue;
      if (text.split(' ').where((w) => w.isNotEmpty).length < 10) continue;
      sections.add(
        TheorySectionModel(title: secTitle, text: text, type: clean(s.type)),
      );
    }
    if (sections.isEmpty) {
      sections.add(
        TheorySectionModel(
          title: 'Placeholder',
          text: 'Content will be added later',
          type: 'info',
        ),
      );
    }
    return TheoryPackModel(
      id: pack.id.trim(),
      title: title,
      sections: sections,
    );
  }
}
