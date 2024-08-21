
import 'dart:ui';

import 'package:easy_wallet/model/chart_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartData Tests', () {
    test('Constructor assigns properties correctly', () {
      const color = Color(0xFF42A5F5);
      final chartData = ChartData('Example Label', 100, color);

      expect(chartData.label, equals('Example Label'));
      expect(chartData.value, equals(100));
      expect(chartData.color, equals(color));
    });

    test('Value supports different types', () {
      final chartDataInt = ChartData('Int Value', 100, const Color(0xFF42A5F5));
      final chartDataDouble = ChartData('Double Value', 100.5, const Color(0xFF42A5F5));
      final chartDataString = ChartData('String Value', 'One Hundred', const Color(0xFF42A5F5));

      expect(chartDataInt.value, isA<int>());
      expect(chartDataDouble.value, isA<double>());
      expect(chartDataString.value, isA<String>());
    });

    test('Color property is set correctly', () {
      const color = Color(0xFF42A5F5);
      final chartData = ChartData('Example Label', 100, color);

      expect(chartData.color, equals(color));
      expect(chartData.color.alpha, equals(255));
      expect(chartData.color.red, equals(66));
      expect(chartData.color.green, equals(165));
      expect(chartData.color.blue, equals(245));
    });
  });
}
