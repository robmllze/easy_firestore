// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// MATH
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

library easy_firestore;

import 'dart:math' show log, pow, ln10;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

double _log10(num x) => log(x) / ln10;

/// Rounds `x` to significant `figures`, e.g. roundAt(5.1234567, 4) returns
/// 5.123.
double roundToFigures(final double x, final int figures) {
  assert(figures >= 0);
  if (x == 0) return 0;
  final double a = _log10(x).truncateToDouble();
  final num y = pow(10, a + 1 - figures);
  return y * (x / y).roundToDouble();
}

/// Rounds `x` at the figure `figures`, e.g. roundAt(5.1234567, 4) returns
/// 5.1235.
double roundAt(final double x, final int figures) {
  assert(figures >= 0);
  if (x == 0) return 0;
  final double y = pow(10, figures).toDouble();
  return (x * y).roundToDouble() / y;
}