import 'dart:math';

/// Profiles for different exercise speeds
enum OneEuroProfile {
  /// Yoga, Pilates, Stretching, Plank (high smoothing, low responsiveness)
  slowStatic,

  /// Squats, Lunges, Push-ups (balanced)
  controlled,

  /// Jumping Jacks, Running, Mountain Climbers (moderate smoothing, high responsiveness)
  rhythmic,

  /// Boxing, Burpees, Jump Squats (minimal smoothing, maximal responsiveness)
  explosive,
}

/// AdaptiveOneEuroFilter - Automatically adjusts parameters based on movement speed.
/// Uses specific profiles based on exercise categories.
class AdaptiveOneEuroFilter {
  static const Map<OneEuroProfile, Map<String, double>> _profiles = {
    OneEuroProfile.slowStatic: {
      'min_cutoff': 0.5,
      'beta': 0.01,
      'd_cutoff': 1.0,
    },
    OneEuroProfile.controlled: {
      'min_cutoff': 0.5, // Increased smoothing for UI jitter reduction
      'beta': 0.1,
      'd_cutoff': 1.0,
    },
    OneEuroProfile.rhythmic: {'min_cutoff': 1.5, 'beta': 1.5, 'd_cutoff': 1.0},
    OneEuroProfile.explosive: {'min_cutoff': 2.0, 'beta': 2.0, 'd_cutoff': 1.0},
  };

  /// Mapping from exercise category to smoothing profile
  static const Map<String, String> categoryToProfile = {
    // Lower Body
    "SQUAT": "CONTROLLED",
    "JUMP_SQUAT": "EXPLOSIVE",
    "LUNGE": "CONTROLLED",
    "JUMP_LUNGE": "EXPLOSIVE",
    "DEADLIFT": "CONTROLLED",
    "GLUTE_BRIDGE": "CONTROLLED",

    // Upper Body
    "PUSH_UP": "CONTROLLED",
    "PULL_UP": "CONTROLLED",
    "SHOULDER_PRESS": "CONTROLLED",
    "ARMS": "CONTROLLED",
    "DIPS": "CONTROLLED",

    // Core
    "PLANK": "SLOW_STATIC",
    "AB_CRUNCH": "CONTROLLED",
    "ROTATION": "CONTROLLED",
    "MOUNTAIN_CLIMBER": "RHYTHMIC",

    // Cardio / HIIT
    "JUMPING_JACK": "RHYTHMIC",
    "BURPEE": "EXPLOSIVE",
    "HIGH_KNEES": "RHYTHMIC",
    "BOX_JUMP": "EXPLOSIVE",
    "RUNNING": "RHYTHMIC",

    // Combat
    "BOXING": "EXPLOSIVE",
    "KICKBOXING": "EXPLOSIVE",
    "MARTIAL_ARTS": "EXPLOSIVE",

    // Mind-Body
    "YOGA": "SLOW_STATIC",
    "PILATES": "SLOW_STATIC",
    "STRETCHING": "SLOW_STATIC",
    "BALANCE": "SLOW_STATIC",

    // Default
    "OTHER": "CONTROLLED",
  };

  static OneEuroProfile profileFromString(String? value) {
    if (value == null) return OneEuroProfile.controlled;
    final normalized = value.toUpperCase();
    switch (normalized) {
      case 'SLOW_STATIC':
        return OneEuroProfile.slowStatic;
      case 'RHYTHMIC':
        return OneEuroProfile.rhythmic;
      case 'EXPLOSIVE':
        return OneEuroProfile.explosive;
      case 'CONTROLLED':
      default:
        return OneEuroProfile.controlled;
    }
  }

  static OneEuroProfile profileFromCategory(String? category) {
    if (category == null) return OneEuroProfile.controlled;
    final normalized = category.toUpperCase();
    final profileStr = categoryToProfile[normalized] ?? "CONTROLLED";
    return profileFromString(profileStr);
  }

  final OneEuroProfile profile;
  final bool adaptive;
  final int historySize;

  late double _minCutoffBase;
  late double _betaBase;
  late double _dCutoff;

  late double _minCutoff;
  late double _beta;

  List<double>? _xPrev;
  List<double>? _dxPrev;
  double? _tPrev;

  final List<double> _speedHistory = [];

  AdaptiveOneEuroFilter({
    this.profile = OneEuroProfile.controlled,
    this.adaptive = true,
    this.historySize = 10,
  }) {
    final params = _profiles[profile]!;
    _minCutoffBase = params['min_cutoff']!;
    _betaBase = params['beta']!;
    _dCutoff = params['d_cutoff']!;

    _minCutoff = _minCutoffBase;
    _beta = _betaBase;
  }

  /// Filters a new value [x] at time [t] (usually timestamp in seconds).
  /// [x] can be a single value (as a list of length 1) or a vector (e.g. 3D coordinates).
  List<double> filter(double t, List<double> x) {
    if (_tPrev == null || _xPrev == null) {
      _tPrev = t;
      _xPrev = List.from(x);
      _dxPrev = List.filled(x.length, 0.0);
      return List.from(x);
    }

    final double dt = t - _tPrev!;
    if (dt <= 1e-6) {
      return List.from(_xPrev!);
    }

    // dx = (x - x_prev) / dt
    final List<double> dx = List.generate(
      x.length,
      (i) => (x[i] - _xPrev![i]) / dt,
    );

    // Calculate speed (L2 norm)
    final double speed = _norm(dx);

    // Adaptive parameter adjustment
    if (adaptive) {
      _speedHistory.add(speed);
      if (_speedHistory.length > historySize) {
        _speedHistory.removeAt(0);
      }

      final double avgSpeed =
          _speedHistory.reduce((a, b) => a + b) / _speedHistory.length;

      // Dynamic adjustment based on speed
      if (avgSpeed < 0.5) {
        // Slow movement
        _minCutoff = _minCutoffBase * 0.7;
        _beta = _betaBase * 0.5;
      } else if (avgSpeed > 2.0) {
        // Fast movement
        _minCutoff = _minCutoffBase * 1.5;
        _beta = _betaBase * 2.0;
      } else {
        // Normal
        _minCutoff = _minCutoffBase;
        _beta = _betaBase;
      }
    }

    // Apply One Euro Filter logic
    final double alphaD = _smoothingFactor(dt, _dCutoff);

    for (int i = 0; i < x.length; i++) {
      _dxPrev![i] = (1.0 - alphaD) * _dxPrev![i] + alphaD * dx[i];
    }
    final double dxNorm = _norm(_dxPrev!);

    final double cutoff = _minCutoff + _beta * dxNorm;
    final double alpha = _smoothingFactor(dt, cutoff);

    for (int i = 0; i < x.length; i++) {
      _xPrev![i] = (1.0 - alpha) * _xPrev![i] + alpha * x[i];
    }

    _tPrev = t;
    return List.from(_xPrev!);
  }

  double _norm(List<double> v) {
    double sum = 0.0;
    for (var val in v) {
      sum += val * val;
    }
    return sqrt(sum);
  }

  double _smoothingFactor(double dt, double cutoff) {
    final double r = 2 * pi * cutoff * dt;
    return r / (r + 1);
  }

  /// Reset filter state
  void reset() {
    _xPrev = null;
    _dxPrev = null;
    _tPrev = null;
    _speedHistory.clear();
  }
}
