class FootballSeasons {
  static const firstYear = 2009;
  static const lastYear = 2026;

  static List<int> years({bool descending = true}) {
    final list = [for (var year = firstYear; year <= lastYear; year++) year];
    return descending ? list.reversed.toList() : list;
  }

  static String label(int startYear) => '$startYear-${startYear + 1}';

  static int get currentStartYear {
    final now = DateTime.now();
    return now.month >= 8 ? now.year : now.year - 1;
  }

  static bool isComplete(int startYear) => startYear < currentStartYear;
}
