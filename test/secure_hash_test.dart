import 'package:flutter_test/flutter_test.dart';
import 'package:digital_assets_moamalat_pay/digital_assets_moamalat_pay.dart';
// ignore: implementation_imports
import 'package:digital_assets_moamalat_pay/src/utils/secure_hash.dart';

void main() {
  group('secureHashHex', () {
    test('matches RFC 4231 HMAC-SHA-256 test case 1', () {
      // Key: 0x0b * 20, message: "Hi There"
      // Expected MAC (lowercase): b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7
      final key = '0B' * 20;
      final mac = secureHashHex('Hi There', key);
      expect(
        mac,
        'B0344C61D8DB38535CA8AFCEAF0BF12B881DC200C9833DA726E9376C2E32CFF7',
      );
    });

    test('rejects odd-length keys', () {
      expect(
        () => secureHashHex('msg', 'ABC'),
        throwsA(isA<MoamalatPaymentError>()),
      );
    });

    test('rejects non-hex characters in key', () {
      expect(
        () => secureHashHex('msg', 'ZZ'),
        throwsA(isA<MoamalatPaymentError>()),
      );
    });

    test('matches the gateway secure-hash recipe', () {
      // Realistic shape used by PayByCardParameters.fromConfig:
      //   "DateTimeLocalTrxn=...&MerchantId=...&TerminalId=..."
      const input = 'DateTimeLocalTrxn=240307090501023'
          '&MerchantId=10081014649'
          '&TerminalId=99179395';
      final mac = secureHashHex(input, '0B' * 20);
      expect(mac.length, 64);
      expect(mac, mac.toUpperCase());
    });
  });
}
