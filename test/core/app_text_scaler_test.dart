import 'package:calibre_web_companion/core/utils/app_text_scaler.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTextScaler', () {
    test('keeps the system font size when the in-app factor is 1.0', () {
      // Regression: the app used to replace the system scaler with
      // TextScaler.linear(appFactor), so a user with large system text got
      // 100% text inside the app.
      const scaler = AppTextScaler(
        system: TextScaler.linear(1.5),
        appFactor: 1.0,
      );

      expect(scaler.scale(14), 21);
    });

    test('multiplies the system scale by the in-app factor', () {
      const scaler = AppTextScaler(
        system: TextScaler.linear(1.3),
        appFactor: 1.2,
      );

      expect(scaler.scale(10), closeTo(15.6, 1e-9));
    });

    test('preserves a nonlinear system scaler instead of flattening it', () {
      // Android 14+ scales large fonts less than small ones.
      const scaler = AppTextScaler(
        system: _HalvingAboveTwentyScaler(),
        appFactor: 2.0,
      );

      expect(scaler.scale(10), 40); // 10 * 2 (system) * 2 (app)
      expect(scaler.scale(30), 90); // 30 * 1.5 (system) * 2 (app)
    });

    test(
      'equal inputs produce equal scalers so MediaQuery does not rebuild',
      () {
        expect(
          const AppTextScaler(system: TextScaler.linear(1.1), appFactor: 1.2),
          const AppTextScaler(system: TextScaler.linear(1.1), appFactor: 1.2),
        );
      },
    );
  });
}

class _HalvingAboveTwentyScaler extends TextScaler {
  const _HalvingAboveTwentyScaler();

  @override
  double scale(double fontSize) => fontSize * (fontSize > 20 ? 1.5 : 2.0);

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => 2.0;
}
