enum PerformanceRating {
  excellent("優異"),
  good("良好"),
  average("一般"),
  poor("不佳"),
  terrible("極差");

  final String label;

  const PerformanceRating(this.label);

  factory PerformanceRating.fromString(String ratingStr) {
    return PerformanceRating.values
        .where((rating) => rating.name == ratingStr)
        .first;
  }
} 