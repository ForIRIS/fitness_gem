import 'dart:math';

class OneEuroFilterSimple {
  // Config
  final double frequency;
  final double minCutoff;
  final double beta;
  final double dCutoff;

  // State
  double _prevX = 0.0;
  double _prevDx = 0.0;
  double _prevT = 0.0;
  bool _firstTime = true;

  OneEuroFilterSimple({
    this.frequency = 30.0,
    this.minCutoff = 1.0,
    this.beta = 0.0,
    this.dCutoff = 1.0,
  });

  double process(double t, double x) {
    if (_firstTime) {
      _firstTime = false;
      _prevX = x;
      _prevT = t;
      _prevDx = 0.0;
      return x;
    }

    final te = t - _prevT; // Period

    // Filtering derivative
    // fc_d = dCutoff
    final alphad = _alpha(te, dCutoff);
    final dx = (x - _prevX) / te;
    final smoothedDx = alphad * dx + (1.0 - alphad) * _prevDx;

    // Filtering value
    final cutoff = minCutoff + beta * smoothedDx.abs();
    final alpha = _alpha(te, cutoff);
    final smoothedX = alpha * x + (1.0 - alpha) * _prevX;

    _prevX = smoothedX;
    _prevDx = smoothedDx;
    _prevT = t;

    return smoothedX;
  }

  double _alpha(double te, double cutoff) {
    final tau = 1.0 / (2 * pi * cutoff);
    return 1.0 / (1.0 + tau / te);
  }
}
