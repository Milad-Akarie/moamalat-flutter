import 'check_transaction_status.dart';
import 'pay_by_card.dart';

class ThreeDSChallengeResult {
  final PayByCardResponse redirectResponse;
  final CheckTransactionStatusResponse? transactionStatus;

  const ThreeDSChallengeResult({
    required this.redirectResponse,
    this.transactionStatus,
  });

  bool get success {
    if (redirectResponse.success != true) return false;
    final paid = transactionStatus?.isPaid;
    return paid == null || paid == true;
  }
}
