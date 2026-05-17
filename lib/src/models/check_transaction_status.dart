import '../config.dart';
import '../utils/json_coercion.dart';

class CheckTransactionStatusParameters {
  final String merchantId;
  final String terminalId;
  final String secureHash;
  final String dateTimeLocalTrxn;
  final String extraInfo;
  final bool isNaps;
  final bool isMobileSDK;
  final bool isOoredoo;

  const CheckTransactionStatusParameters({
    required this.merchantId,
    required this.terminalId,
    required this.secureHash,
    required this.dateTimeLocalTrxn,
    this.extraInfo = '',
    this.isNaps = true,
    this.isMobileSDK = true,
    this.isOoredoo = false,
  });

  factory CheckTransactionStatusParameters.fromConfig({
    required MoamalatPaymentConfig config,
    bool isNaps = true,
    required String secureHash,
    bool isOoredoo = false,
    String extraInfo = '',
  }) {
    return CheckTransactionStatusParameters(
      merchantId: config.merchantId,
      terminalId: config.terminalId,
      secureHash: secureHash,
      dateTimeLocalTrxn: config.transactionDate,
      extraInfo: extraInfo,
      isNaps: isNaps,
      isOoredoo: isOoredoo,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'MerchantId': merchantId,
      'TerminalId': terminalId,
      'SecureHash': secureHash,
      'DateTimeLocalTrxn': dateTimeLocalTrxn,
      'ExtraInfo': extraInfo,
      'IsNaps': isNaps,
      'IsMobileSDK': isMobileSDK,
      'IsOoredoo': isOoredoo,
    };
  }
}

class CheckTransactionStatusResponse {
  final bool? success;
  final String? message;
  final bool? isPaid;
  final String? referenceId;
  final String? transactionId;
  final int? amountTrxn;
  final String? systemTxnId;
  final String? txnDate;
  final int? systemReference;
  final Map<String, dynamic> rawJson;

  const CheckTransactionStatusResponse({
    required this.rawJson,
    this.success,
    this.message,
    this.isPaid,
    this.referenceId,
    this.transactionId,
    this.amountTrxn,
    this.systemTxnId,
    this.txnDate,
    this.systemReference,
  });

  factory CheckTransactionStatusResponse.fromJson(Map<String, dynamic> json) {
    return CheckTransactionStatusResponse(
      rawJson: Map<String, dynamic>.from(json),
      success: jsonBool(json['Success']),
      message: jsonString(json['Message']),
      isPaid: jsonBool(json['IsPaid']),
      referenceId: jsonString(json['ReferenceId']),
      transactionId: jsonString(json['TransactionId']),
      amountTrxn: jsonInt(json['AmountTrxn']),
      systemTxnId: jsonString(json['SystemTxnId']),
      txnDate: jsonString(json['TxnDate']),
      systemReference: jsonInt(json['SystemReference']),
    );
  }
}
