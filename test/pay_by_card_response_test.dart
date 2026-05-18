import 'package:flutter_test/flutter_test.dart';
import 'package:digital_assets_moamalat_pay/digital_assets_moamalat_pay.dart';

void main() {
  group('PayByCardResponse.fromJson', () {
    test('extracts 3DS challenge fields', () {
      final response = PayByCardResponse.fromJson(<String, dynamic>{
        'Success': true,
        'ChallengeRequired': true,
        'ThreeDSUrl': 'https://acs.example/challenge?id=xyz',
        'Message': 'OTP required',
      });
      expect(response.success, true);
      expect(response.challengeRequired, true);
      expect(response.threeDSUrl, 'https://acs.example/challenge?id=xyz');
      expect(response.message, 'OTP required');
    });

    test('coerces stringified booleans', () {
      final t =
          PayByCardResponse.fromJson(<String, dynamic>{'Success': 'true'});
      final f =
          PayByCardResponse.fromJson(<String, dynamic>{'Success': 'false'});
      final n = PayByCardResponse.fromJson(<String, dynamic>{'Success': 1});
      final z = PayByCardResponse.fromJson(<String, dynamic>{'Success': 0});
      expect(t.success, true);
      expect(f.success, false);
      expect(n.success, true);
      expect(z.success, false);
    });

    test('coerces stringified ints', () {
      final r = PayByCardResponse.fromJson(<String, dynamic>{
        'SystemReference': '1234',
      });
      expect(r.systemReference, 1234);
    });

    test('preserves rawJson for caller introspection', () {
      final r = PayByCardResponse.fromJson(<String, dynamic>{
        'Success': true,
        'CustomVendorField': 'whatever',
      });
      expect(r.rawJson['CustomVendorField'], 'whatever');
    });
  });

  group('MoamalatPaymentService 3DS redirect parsing', () {
    final config = MoamalatPaymentConfig(
      environment: MoamalatEnvironment.testing,
      merchantId: 'M',
      terminalId: 'T',
      amount: 1,
      currencyCode: 434,
      secureHash: '0B' * 20,
      transactionDate: '20240101T000000Z',
      returnUrl: 'https://merchant.example/return',
      merchantReference: 'ref-1',
    );

    test('shouldHandleThreeDSRedirect requires the return URL + Success param',
        () {
      final service = MoamalatPaymentService(config);
      addTearDown(service.close);
      expect(
        service.shouldHandleThreeDSRedirect(
          Uri.parse('https://merchant.example/return?Success=true'),
        ),
        true,
      );
      expect(
        service.shouldHandleThreeDSRedirect(
          Uri.parse('https://merchant.example/return'),
        ),
        false,
      );
      expect(
        service.shouldHandleThreeDSRedirect(
          Uri.parse('https://elsewhere.example/?Success=true'),
        ),
        false,
      );
    });

    test('parseThreeDSRedirect lifts query params into a PayByCardResponse',
        () {
      final service = MoamalatPaymentService(config);
      addTearDown(service.close);
      final parsed = service.parseThreeDSRedirect(
        Uri.parse(
          'https://merchant.example/return'
          '?Success=true'
          '&Message=OK'
          '&MerchantReference=ref-1'
          '&SystemReference=42',
        ),
      );
      expect(parsed, isNotNull);
      expect(parsed!.success, true);
      expect(parsed.message, 'OK');
      expect(parsed.merchantReference, 'ref-1');
      expect(parsed.systemReference, 42);
      expect(parsed.tokenCustomerId, isNull);
    });
  });
}
