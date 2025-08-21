import 'package:uuid/uuid.dart';

class ViewPreset {
  final String id;
  final String name;
  final int sort;
  final String? tagFilter;
  final int mistakeFilter;
  final String? heroPosFilter;
  final String search;

  ViewPreset({
    String? id,
    required this.name,
    required this.sort,
    this.tagFilter,
    required this.mistakeFilter,
    this.heroPosFilter,
    required this.search,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sort': sort,
    'tag': tagFilter,
    'mistake': mistakeFilter,
    'hero': heroPosFilter,
    'search': search,
  };

  factory ViewPreset.fromJson(Map<String, dynamic> json) => ViewPreset(
    id: json['id'] as String?,
    name: json['name'] as String? ?? '',
    sort: (json['sort'] as num?)?.toInt() ?? 0,
    tagFilter: json['tag'] as String?,
    mistakeFilter: (json['mistake'] as num?)?.toInt() ?? 0,
    heroPosFilter: json['hero'] as String?,
    search: json['search'] as String? ?? '',
  );

  ViewPreset copyWith({String? name}) => ViewPreset(
    id: id,
    name: name ?? this.name,
    sort: sort,
    tagFilter: tagFilter,
    mistakeFilter: mistakeFilter,
    heroPosFilter: heroPosFilter,
    search: search,
  );
}
