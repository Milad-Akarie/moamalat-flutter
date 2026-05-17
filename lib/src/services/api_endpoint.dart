enum ApiEndpoint { payByCard, checkTransactionStatus }

extension ApiEndpointPath on ApiEndpoint {
  String get path {
    switch (this) {
      case ApiEndpoint.payByCard:
        return '/PayByCard';
      case ApiEndpoint.checkTransactionStatus:
        return '/CheckTxnStatus';
    }
  }
}
