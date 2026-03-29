// S-CURVE

class SCurvePoint {
  final String period;
  final double planned;
  final double actual;
  final double cumPlanned;
  final double cumActual;

  SCurvePoint({
    required this.period,
    required this.planned,
    required this.actual,
    required this.cumPlanned,
    required this.cumActual,
  });
}