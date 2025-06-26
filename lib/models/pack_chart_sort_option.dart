enum PackChartSort { progress, lastSession, handsPlayed }

extension PackChartSortLabel on PackChartSort {
  String get label {
    switch (this) {
      case PackChartSort.lastSession:
        return 'Последняя сессия';
      case PackChartSort.handsPlayed:
        return 'Кол-во рук';
      case PackChartSort.progress:
      default:
        return 'Прогресс %';
    }
  }
}
