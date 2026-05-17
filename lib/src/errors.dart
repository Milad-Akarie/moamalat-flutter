class MoamalatPaymentError implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;

  const MoamalatPaymentError(this.message, {this.statusCode, this.cause});

  @override
  String toString() {
    final status = statusCode == null ? '' : ' (HTTP $statusCode)';
    final reason = cause == null ? '' : ': $cause';
    return 'MoamalatPaymentError$status: $message$reason';
  }
}
