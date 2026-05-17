import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:digital_assets_moamalat_pay/src/utils/date_formatter.dart';

void main() {
  group('DateFormatter.format', () {
    test('formats UTC as yyMMddHHmmssSSS', () {
      final dt = DateTime.utc(2024, 3, 7, 9, 5, 1, 23);
      expect(DateFormatter.format(dt), '240307090501023');
    });

    test('converts non-UTC inputs to UTC first', () {
      final dt = DateTime.utc(2024, 12, 31, 23, 59, 59, 999);
      expect(DateFormatter.format(dt), '241231235959999');
    });

    test('pads single-digit components', () {
      final dt = DateTime.utc(2025, 1, 2, 3, 4, 5, 6);
      expect(DateFormatter.format(dt), '250102030405006');
    });
  });
}
