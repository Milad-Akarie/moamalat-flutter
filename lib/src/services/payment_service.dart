import 'dart:convert';
import 'dart:developer' as developer;

import '../config.dart';
import '../models/check_transaction_status.dart';
import '../models/pay_by_card.dart';
import '../models/three_ds_result.dart';
import '../utils/json_coercion.dart';
import 'api_endpoint.dart';
import 'payment_http_client.dart';

/// High-level facade over the Moamalat PayLink REST endpoints.
///
/// Use this directly for headless integrations, or let
/// `MoamalatCardPaymentForm` drive it for you.
class MoamalatPaymentService {
  static const _logName = 'MoamalatPaymentService';

  final MoamalatPaymentConfig config;
  final MoamalatHttpClient _httpClient;
  final bool _ownsClient;

  MoamalatPaymentService(this.config, {MoamalatHttpClient? httpClient})
      : _httpClient = httpClient ?? MoamalatHttpClient(timeout: config.timeout),
        _ownsClient = httpClient == null {
    developer.log(
      'MoamalatPaymentService initialized (environment=${config.environment}, merchantId=${config.merchantId}, terminalId=${config.terminalId}, amount=${config.amount}, returnUrl=${config.resolvedReturnUrl})',
      name: _logName,
    );
  }

  void _debug(String message) => developer.log(message, name: _logName);

  Future<PayByCardResponse> payByCard({
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
    required String secureHash,
    bool isSaveCard = false,
    bool isDefaultCard = false,
    String? tokenCustomerSession,
  }) async {
    _debug(
        'payByCard called (cardHolderName=$cardHolderName, expiryDate=$expiryDate, isSaveCard=$isSaveCard, isDefaultCard=$isDefaultCard, hasTokenCustomerSession=${tokenCustomerSession != null})');
    final parameters = PayByCardParameters.fromConfig(
      config: config,
      cardNumber: cardNumber,
      cardHolderName: cardHolderName,
      expiryDate: expiryDate,
      cvv: cvv,
      secureHash: secureHash,
      isSaveCard: false,
      isDefaultCard: isDefaultCard,
      tokenCustomerSession: tokenCustomerSession,
    );
    final uri = config.uriFor(ApiEndpoint.payByCard);
    _debug('payByCard request uri=$uri parameters=${parameters.toMap()}');
    final json = await _httpClient.postJson(
      uri,
      parameters.toMap(),
    );

    final prettyString = const JsonEncoder.withIndent('  ').convert(json);
    developer.log(prettyString);

    _debug('payByCard response json=$json');
    final response = PayByCardResponse.fromJson(json);
    _debug(
        'payByCard parsed response (success=${response.success}, actionCode=${response.actionCode}, merchantReference=${response.merchantReference}, challengeRequired=${response.challengeRequired})');
    return response;
  }

  Future<CheckTransactionStatusResponse> checkTransactionStatus({
    bool isNaps = true,
    bool isOoredoo = false,
    String extraInfo = '',
    required String secureHash,
  }) async {
    _debug(
        'checkTransactionStatus called (isNaps=$isNaps, isOoredoo=$isOoredoo, extraInfo=$extraInfo)');
    final parameters = CheckTransactionStatusParameters.fromConfig(
      config: config,
      secureHash: secureHash,
      isNaps: isNaps,
      isOoredoo: isOoredoo,
      extraInfo: extraInfo,
    );
    final uri = config.uriFor(ApiEndpoint.checkTransactionStatus);
    _debug(
        'checkTransactionStatus request uri=$uri parameters=${parameters.toMap()}');
    final json = await _httpClient.postJson(
      uri,
      parameters.toMap(),
    );
    _debug('checkTransactionStatus response json=$json');
    final response = CheckTransactionStatusResponse.fromJson(json);
    _debug(
        'checkTransactionStatus parsed response (success=${response.success}, isPaid=${response.isPaid}, referenceId=${response.referenceId}, transactionId=${response.transactionId})');
    return response;
  }

  /// Whether the given navigation URL is the gateway redirecting back to the
  /// merchant return URL after a 3DS challenge.
  bool shouldHandleThreeDSRedirect(Uri redirectUri) {
    final url = redirectUri.toString();
    final shouldHandle = url.contains(config.resolvedReturnUrl) &&
        redirectUri.queryParameters.containsKey('Success');
    _debug(
        'shouldHandleThreeDSRedirect called (redirectUri=$redirectUri) => $shouldHandle');
    return shouldHandle;
  }

  /// Decodes a 3DS-redirect URL into a `PayByCardResponse`. Returns `null` if
  /// the URL is not the expected return URL.
  PayByCardResponse? parseThreeDSRedirect(Uri redirectUri) {
    _debug('parseThreeDSRedirect called (redirectUri=$redirectUri)');
    if (!shouldHandleThreeDSRedirect(redirectUri)) {
      _debug(
          'parseThreeDSRedirect returning null because redirectUri is not handled');
      return null;
    }
    final query = redirectUri.queryParameters;
    _debug('parseThreeDSRedirect queryParameters=$query');
    final responseJson = <String, dynamic>{
      'Message': query['Message'] ?? '',
      'ActionCode': query['ActionCode'] ?? '',
      'AuthCode': query['AuthCode'] ?? '',
      'MerchantReference': query['MerchantReference'] ?? '',
      'NetworkReference': query['NetworkReference'] ?? '',
      'ReceiptNumber': query['ReceiptNumber'] ?? '',
      'SystemReference': int.tryParse(query['SystemReference'] ?? '0') ?? 0,
      'Success': jsonBool(query['Success']) ?? false,
    };
    if (config.customerId != null) {
      responseJson['TokenCustomerId'] = config.customerId;
    }
    final response = PayByCardResponse.fromJson(responseJson);
    _debug(
        'parseThreeDSRedirect parsed redirectResponse (success=${response.success}, actionCode=${response.actionCode}, merchantReference=${response.merchantReference})');
    return response;
  }

  /// End-to-end 3DS-redirect handling: parses the return URL, optionally calls
  /// `CheckTxnStatus` to confirm payment, and returns a typed result. Returns
  /// `null` if the URL is not a 3DS redirect.
  Future<ThreeDSChallengeResult?> handleThreeDSRedirect(
    Uri redirectUri, {
    bool verifyTransactionStatus = true,
    bool isNaps = true,
    bool isOoredoo = false,
    String extraInfo = '',
    required String secureHash,
  }) async {
    _debug(
        'handleThreeDSRedirect called (redirectUri=$redirectUri, verifyTransactionStatus=$verifyTransactionStatus, isNaps=$isNaps, isOoredoo=$isOoredoo, extraInfo=$extraInfo)');
    final redirectResponse = parseThreeDSRedirect(redirectUri);
    if (redirectResponse == null) {
      _debug(
          'handleThreeDSRedirect returning null because parseThreeDSRedirect returned null');
      return null;
    }
    if (redirectResponse.success != true || !verifyTransactionStatus) {
      _debug(
          'handleThreeDSRedirect returning without transaction status check (success=${redirectResponse.success}, verifyTransactionStatus=$verifyTransactionStatus)');
      return ThreeDSChallengeResult(redirectResponse: redirectResponse);
    }
    final status = await checkTransactionStatus(
      isNaps: isNaps,
      isOoredoo: isOoredoo,
      extraInfo: extraInfo,
      secureHash: secureHash,
    );
    _debug(
        'handleThreeDSRedirect checkTransactionStatus returned (success=${status.success}, isPaid=${status.isPaid}, transactionId=${status.transactionId})');
    return ThreeDSChallengeResult(
      redirectResponse: redirectResponse,
      transactionStatus: status,
    );
  }

  void close() {
    if (_ownsClient) {
      _debug('close called; closing owned HTTP client');
      _httpClient.close();
    } else {
      _debug('close called; HTTP client is externally owned, not closing');
    }
  }
}
