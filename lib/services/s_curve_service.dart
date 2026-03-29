import '../models/todo.dart';
import '../models/s_curve.dart';


class SCurveService {
  /// Generate list minggu dari start ke end
  List<DateTime> generateWeeks(DateTime start, DateTime end) {
    final weeks = <DateTime>[];
    DateTime current = start;

    while (!current.isAfter(end)) {
      weeks.add(current);
      current = current.add(const Duration(days: 7));
    }

    return weeks;
  }

  /// Distribusi S-Curve (slow → fast → slow)
  List<double> _sCurveDistribution(int totalWeeks) {
    if (totalWeeks <= 1) return [1];

    if (totalWeeks == 2) return [0.5, 0.5];

    if (totalWeeks == 3) return [0.2, 0.6, 0.2];

    if (totalWeeks == 4) return [0.17, 0.33, 0.33, 0.17];

    // fallback: semi S-curve (pakai parabola sederhana)
    List<double> dist = [];
    double sum = 0;

    for (int i = 0; i < totalWeeks; i++) {
      double x = i / (totalWeeks - 1); // 0 → 1
      double value = 4 * x * (1 - x); // parabola
      dist.add(value);
      sum += value;
    }

    // normalize ke 1
    return dist.map((e) => e / sum).toList();
  }

  /// Hitung planned per minggu (pakai distribusi S-curve)
  Map<int, double> calculatePlannedPerWeek(
      List<Todo> todos, List<DateTime> weeks) {
    final planned = <int, double>{};

    for (int i = 0; i < weeks.length; i++) {
      planned[i] = 0;
    }

    for (var todo in todos) {
      if (todo.startDate == null ||
          todo.dueDate == null ||
          todo.weight == null) continue;

      final durationDays =
          todo.dueDate!.difference(todo.startDate!).inDays;

      if (durationDays <= 0) continue;

      final totalWeeks = (durationDays / 7).ceil();
      final dist = _sCurveDistribution(totalWeeks);

      for (int i = 0; i < weeks.length; i++) {
        final weekStart = weeks[i];
        final weekEnd = weekStart.add(const Duration(days: 7));

        if (todo.startDate!.isBefore(weekEnd) &&
            todo.dueDate!.isAfter(weekStart)) {
          
          int index = ((weekStart.difference(todo.startDate!).inDays) / 7)
              .floor()
              .clamp(0, totalWeeks - 1);

          planned[i] =
              planned[i]! + (todo.weight! * dist[index]);
        }
      }
    }

    return _normalize(planned);
  }

  /// Hitung actual (kumulatif sampai minggu itu)
  Map<int, double> calculateActualPerWeek(
      List<Todo> todos, List<DateTime> weeks) {
    final actual = <int, double>{};

    for (int i = 0; i < weeks.length; i++) {
      actual[i] = 0;
    }

    final now = DateTime.now();

    for (var todo in todos) {
      if (todo.weight == null || todo.progress == null) continue;

      final value = (todo.weight! * todo.progress!) / 100;

      for (int i = 0; i < weeks.length; i++) {
        final weekEnd = weeks[i].add(const Duration(days: 7));

        // semua minggu yang sudah lewat
        if (weekEnd.isBefore(now) || weekEnd.isAtSameMomentAs(now)) {
          actual[i] = actual[i]! + value;
        }
      }
    }

    return _normalize(actual);
  }

  /// Build S-Curve (planned + actual + kumulatif)
  List<SCurvePoint> buildSCurve(
    Map<int, double> planned,
    Map<int, double> actual,
    List<DateTime> weeks,
  ) {
    final result = <SCurvePoint>[];

    double cumPlan = 0;
    double cumActual = 0;

    for (int i = 0; i < weeks.length; i++) {
      final p = planned[i] ?? 0;
      final a = actual[i] ?? 0;

      cumPlan += p;
      cumActual += a;

      result.add(
        SCurvePoint(
          period: "W${i + 1}",
          planned: p,
          actual: a,
          cumPlanned: cumPlan,
          cumActual: cumActual,
        ),
      );
    }

    return result;
  }

  /// Normalize supaya total = 100%
  Map<int, double> _normalize(Map<int, double> data) {
    final total = data.values.fold(0.0, (a, b) => a + b);

    if (total == 0) return data;

    return data.map(
      (key, value) => MapEntry(key, (value / total) * 100),
    );
  }
}