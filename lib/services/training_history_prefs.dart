/// Enumerations and preference keys for Training History features.

enum SortOption { newest, oldest, position, mistakes, evDiff, icmDiff }

enum RatingFilter { all, pct40, pct60, pct80 }

enum AccuracyRange { all, lt50, pct50to75, pct75plus }

enum ChartMode { daily, weekly, monthly }

enum TagCountFilter { any, one, twoPlus, threePlus }

enum WeekdayFilter { all, mon, tue, wed, thu, fri, sat, sun }

enum SessionLengthFilter { any, oneToFive, sixToTen, elevenPlus }

const sortKey = 'training_history_sort';
const ratingKey = 'training_history_rating';
const tagKey = 'training_history_tags';
const tagColorKey = 'training_history_tag_colors';
const showChartsKey = 'training_history_show_charts';
const showAvgChartKey = 'training_history_show_chart';
const showDistributionKey = 'training_history_show_distribution';
const showTrendChartKey = 'training_history_show_trend_chart';
const dateFromKey = 'training_history_date_from';
const dateToKey = 'training_history_date_to';
const chartModeKey = 'training_history_chart_mode';
const hideEmptyTagsKey = 'hide_empty_tags';
const sortByTagKey = 'training_history_sort_by_tag';
const accuracyRangeKey = 'training_history_accuracy_range';
const tagCountKey = 'training_history_tag_count';
const weekdayKey = 'training_history_weekday';
const lengthKey = 'training_history_length';
const pdfIncludeChartKey = 'training_history_pdf_include_chart';
const exportTags3OnlyKey = 'training_history_export_tags_3plus';
const exportNotesOnlyKey = 'training_history_export_notes_only';

