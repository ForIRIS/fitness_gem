import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_gem/utils/adaptive_one_euro_filter.dart';

void main() {
  group('AdaptiveOneEuroFilter', () {
    test('should smooth a noisy signal', () {
      final filter = AdaptiveOneEuroFilter(profile: OneEuroProfile.controlled);

      // Steady signal at 10.0 with some jitter
      final inputs = [10.0, 10.5, 9.5, 10.2, 9.8];
      final List<double> outputs = [];

      for (int i = 0; i < inputs.length; i++) {
        final val = filter.filter(i * 0.1, [inputs[i]])[0];
        outputs.add(val);
      }

      // The first value should be the same as input
      expect(outputs[0], 10.0);

      // Subsequent values should be damped
      // Input jump 10.0 -> 10.5 (diff 0.5)
      // Filtered jump should be smaller
      expect((outputs[1] - outputs[0]).abs(), lessThan(0.5));
    });

    test('SLOW_STATIC profile should smooth more than RHYTHMIC profile', () {
      final slowFilter = AdaptiveOneEuroFilter(
        profile: OneEuroProfile.slowStatic,
      );
      final fastFilter = AdaptiveOneEuroFilter(
        profile: OneEuroProfile.rhythmic,
      );

      final t = [0.0, 0.1];
      final x = [0.0, 1.0]; // Significant jump

      final slowResult = slowFilter.filter(t[0], [x[0]]);
      final slowResultNext = slowFilter.filter(t[1], [x[1]]);

      final fastResult = fastFilter.filter(t[0], [x[0]]);
      final fastResultNext = fastFilter.filter(t[1], [x[1]]);

      final slowDelta = (slowResultNext[0] - slowResult[0]).abs();
      final fastDelta = (fastResultNext[0] - fastResult[0]).abs();

      // Rhythmic profile should allow more of the signal through
      expect(fastDelta, greaterThan(slowDelta));
    });

    test('adaptive logic should change parameters based on speed', () {
      final filter = AdaptiveOneEuroFilter(
        profile: OneEuroProfile.controlled,
        adaptive: true,
      );

      // 1. Slow movements
      for (int i = 0; i < 10; i++) {
        filter.filter(i * 0.1, [0.0 + i * 0.01]);
      }

      // 2. Fast movements
      final result1 = filter.filter(1.1, [0.1]);
      final result2 = filter.filter(1.2, [2.0]); // Large jump

      final delta = (result2[0] - result1[0]).abs();
      expect(delta, isPositive);
    });

    test('should handle vector inputs (List<double>)', () {
      final filter = AdaptiveOneEuroFilter();
      final result = filter.filter(0.0, [1.0, 2.0, 3.0]);
      expect(result, [1.0, 2.0, 3.0]);

      final resultNext = filter.filter(0.1, [1.1, 2.1, 3.1]);
      expect(resultNext.length, 3);
      expect(resultNext[0], lessThan(1.1));
    });

    test('should map categories to profiles correctly', () {
      expect(
        AdaptiveOneEuroFilter.profileFromCategory('SQUAT'),
        OneEuroProfile.controlled,
      );
      expect(
        AdaptiveOneEuroFilter.profileFromCategory('JUMP_SQUAT'),
        OneEuroProfile.explosive,
      );
      expect(
        AdaptiveOneEuroFilter.profileFromCategory('YOGA'),
        OneEuroProfile.slowStatic,
      );
      expect(
        AdaptiveOneEuroFilter.profileFromCategory('MOUNTAIN_CLIMBER'),
        OneEuroProfile.rhythmic,
      );
      expect(
        AdaptiveOneEuroFilter.profileFromCategory(null),
        OneEuroProfile.controlled,
      );
      expect(
        AdaptiveOneEuroFilter.profileFromCategory('NON_EXISTENT'),
        OneEuroProfile.controlled,
      );
    });
  });
}
