import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/saved_hand.dart';
import 'saved_hand_manager_service.dart';
import 'player_style_service.dart';

class ProgressEntry {
  final DateTime date;
  final double accuracy;
  final double ev;
  final double icm;
  final String position;
  final String? tag;
  ProgressEntry({
    required this.date,
    required this.accuracy,
    required this.ev,
    required this.icm,
    required this.position,
    this.tag,
  });
}

class ProgressForecast {
  final double accuracy;
  final double ev;
  final double icm;
  ProgressForecast({
    required this.accuracy,
    required this.ev,
    required this.icm,
  });
}

class ProgressForecastService extends ChangeNotifier {
  final SavedHandManagerService hands;
  final PlayerStyleService style;
  List<ProgressEntry> _history = const [];
  Map<String, List<ProgressEntry>> _positionHistory = {};
  Map<String, List<ProgressEntry>> _tagHistory = {};
  ProgressForecast _forecast = const ProgressForecast(
    accuracy: 0,
    ev: 0,
    icm: 0,
  );

  List<ProgressEntry> get history => List.unmodifiable(_history);
  Iterable<String> get positions => _positionHistory.keys;
  Iterable<String> get tags => _tagHistory.keys;
  ProgressForecast get forecast => _forecast;
  List<MapEntry<DateTime, double>> get evSeries => [
    for (final e in _history) MapEntry(e.date, e.ev),
  ];
  List<MapEntry<DateTime, double>> get icmSeries => [
    for (final e in _history) MapEntry(e.date, e.icm),
  ];
  List<MapEntry<DateTime, double>> get accuracySeries => [
    for (final e in _history) MapEntry(e.date, e.accuracy),
  ];
  List<ProgressEntry> get evIcmSeries => List.unmodifiable(_history);
  List<ProgressEntry> positionSeries(String pos) =>
      List.unmodifiable(_positionHistory[pos] ?? const []);
  List<ProgressEntry> tagSeries(String tag) =>
      List.unmodifiable(_tagHistory[tag] ?? const []);

  MapEntry<double, double> avgPrevEvIcm([int sessions = 5]) {
    if (_history.length <= 1) return const MapEntry(0, 0);
    final end = _history.length - 1;
    var start = end - sessions;
    if (start < 0) start = 0;
    final slice = _history.sublist(start, end);
    if (slice.isEmpty) return const MapEntry(0, 0);
    double ev = 0;
    double icm = 0;
    for (final e in slice) {
      ev += e.ev;
      icm += e.icm;
    }
    final c = slice.length;
    return MapEntry(ev / c, icm / c);
  }

  ProgressForecastService({required this.hands, required this.style}) {
    _update();
    hands.addListener(_update);
    style.addListener(_update);
  }

  void _update() {
    final map = <DateTime, List<SavedHand>>{};
    final posMap = <String, Map<DateTime, List<SavedHand>>>{};
    final tagMap = <String, Map<DateTime, List<SavedHand>>>{};
    for (final h in hands.hands) {
      final day = DateTime(h.date.year, h.date.month, h.date.day);
      map.putIfAbsent(day, () => []).add(h);
      posMap
          .putIfAbsent(h.heroPosition, () => {})
          .putIfAbsent(day, () => [])
          .add(h);
      for (final t in h.tags) {
        tagMap.putIfAbsent(t, () => {}).putIfAbsent(day, () => []).add(h);
      }
    }

    List<ProgressEntry> build(
      Map<DateTime, List<SavedHand>> source, {
      String position = '',
      String? tag,
    }) {
      final entries = source.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final list = <ProgressEntry>[];
      for (final e in entries) {
        int correct = 0;
        int total = 0;
        double ev = 0;
        double icm = 0;
        int evCount = 0;
        for (final h in e.value) {
          final exp = h.expectedAction?.trim().toLowerCase();
          final gto = h.gtoAction?.trim().toLowerCase();
          if (exp != null && gto != null) {
            total++;
            if (exp == gto) correct++;
          }
          final hev = h.heroEv;
          if (hev != null) {
            ev += hev;
            evCount++;
          }
          final hicm = h.heroIcmEv;
          if (hicm != null) icm += hicm;
        }
        final acc = total > 0 ? correct / total : 0;
        final avgEv = evCount > 0 ? ev / evCount : 0;
        final avgIcm = evCount > 0 ? icm / evCount : 0;
        list.add(
          ProgressEntry(
            date: e.key,
            accuracy: acc,
            ev: avgEv,
            icm: avgIcm,
            position: position,
            tag: tag,
          ),
        );
      }
      return list;
    }

    _history = build(map);
    _positionHistory = {
      for (final e in posMap.entries) e.key: build(e.value, position: e.key),
    };
    _tagHistory = {
      for (final e in tagMap.entries) e.key: build(e.value, tag: e.key),
    };

    var f = _calcForecast(_history);
    switch (style.style) {
      case PlayerStyle.aggressive:
        f = ProgressForecast(
          accuracy: (f.accuracy - 0.05).clamp(0.0, 1.0),
          ev: f.ev - 0.5,
          icm: f.icm - 0.5,
        );
        break;
      case PlayerStyle.passive:
        f = ProgressForecast(
          accuracy: (f.accuracy - 0.02).clamp(0.0, 1.0),
          ev: f.ev - 0.2,
          icm: f.icm - 0.2,
        );
        break;
      case PlayerStyle.neutral:
        break;
    }
    _forecast = f;
    notifyListeners();
  }

  ProgressForecast _calcForecast(List<ProgressEntry> data) {
    if (data.isEmpty) return const ProgressForecast(accuracy: 0, ev: 0, icm: 0);
    if (data.length == 1) {
      return ProgressForecast(
        accuracy: data.last.accuracy,
        ev: data.last.ev,
        icm: data.last.icm,
      );
    }
    final n = data.length;
    final xs = [for (var i = 0; i < n; i++) i + 1];
    final sumX = xs.reduce((a, b) => a + b);
    final sumX2 = xs.map((e) => e * e).reduce((a, b) => a + b);
    double sumAcc = 0, sumEv = 0, sumIcm = 0;
    double sumXAcc = 0, sumXEv = 0, sumXIcm = 0;
    for (var i = 0; i < n; i++) {
      final x = xs[i].toDouble();
      final d = data[i];
      sumAcc += d.accuracy;
      sumEv += d.ev;
      sumIcm += d.icm;
      sumXAcc += x * d.accuracy;
      sumXEv += x * d.ev;
      sumXIcm += x * d.icm;
    }
    final denom = n * sumX2 - sumX * sumX;
    double slopeAcc = 0, slopeEv = 0, slopeIcm = 0;
    if (denom != 0) {
      slopeAcc = (n * sumXAcc - sumX * sumAcc) / denom;
      slopeEv = (n * sumXEv - sumX * sumEv) / denom;
      slopeIcm = (n * sumXIcm - sumX * sumIcm) / denom;
    }
    return ProgressForecast(
      accuracy: (data.last.accuracy + slopeAcc).clamp(0.0, 1.0),
      ev: data.last.ev + slopeEv,
      icm: data.last.icm + slopeIcm,
    );
  }

  Future<File> exportForecastCsv() async {
    final rows = <List<dynamic>>[];
    rows.add(['Date', 'Accuracy', 'EV', 'ICM']);
    for (final e in _history) {
      rows.add([
        e.date.toIso8601String().split('T').first,
        (e.accuracy * 100).toStringAsFixed(1),
        e.ev.toStringAsFixed(2),
        e.icm.toStringAsFixed(3),
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows, eol: '\r\n');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/progress_forecast.csv');
    await file.writeAsString(csv, encoding: utf8);
    return file;
  }

  @override
  void dispose() {
    hands.removeListener(_update);
    style.removeListener(_update);
    super.dispose();
  }
}
