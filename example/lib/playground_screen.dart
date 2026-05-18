import 'dart:convert';

import 'package:digital_assets_moamalat_pay/digital_assets_moamalat_pay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  // Default sandbox credentials for development
  static const _defaultMerchantId = '10081014649';
  static const _defaultTerminalId = '99179395';
  static const _defaultSecureHash = '';
  static const _defaultCardNumber = '6395043835180860';
  static const _defaultCardHolder = 'moamalat pay';
  static const _defaultExpiry = '0127';

  // Environment variables (can be overridden with --dart-define)
  static const _envMerchantId = String.fromEnvironment(
    'MOAMALAT_MERCHANT_ID',
    defaultValue: _defaultMerchantId,
  );
  static const _envTerminalId = String.fromEnvironment(
    'MOAMALAT_TERMINAL_ID',
    defaultValue: _defaultTerminalId,
  );
  static const _envSecureHash = String.fromEnvironment(
    'MOAMALAT_SECURE_HASH',
    defaultValue: _defaultSecureHash,
  );

  // Demo card data (loaded from .env for production)
  String _demoCardNumber = _defaultCardNumber;
  String _demoCardHolder = _defaultCardHolder;
  String _demoExpiry = _defaultExpiry;

  final TextEditingController _merchantIdCtrl = TextEditingController(
    text: _envMerchantId,
  );
  late final TextEditingController _terminalIdCtrl = TextEditingController(
    text: _envTerminalId,
  );
  late final TextEditingController _secureHashCtrl = TextEditingController(
    text: _envSecureHash,
  );
  final TextEditingController _amountCtrl = TextEditingController(text: '250');
  final TextEditingController _transactionDateCtrl = TextEditingController(
    text: "",
  );
  final TextEditingController _merchantReferenceCtrl = TextEditingController();

  MoamalatEnvironment _environment = MoamalatEnvironment.testing;
  String? _resultLabel;
  String? _resultBody;
  Color? _resultColor;

  @override
  void initState() {
    super.initState();
    _loadEnvFile();
  }

  Future<void> _loadEnvFile() async {
    try {
      final envFileName = _environment == MoamalatEnvironment.production
          ? '.env.prod'
          : '.env.dev';
      await dotenv.load(fileName: envFileName);
      if (mounted) {
        setState(() {
          _demoCardNumber =
              dotenv.env['DEMO_CARD_NUMBER'] ?? _defaultCardNumber;
          _demoCardHolder =
              dotenv.env['DEMO_CARD_HOLDER'] ?? _defaultCardHolder;
          _demoExpiry = dotenv.env['DEMO_EXPIRY'] ?? _defaultExpiry;
          _merchantIdCtrl.text =
              dotenv.env['MOAMALAT_MERCHANT_ID'] ?? _envMerchantId;
          _terminalIdCtrl.text =
              dotenv.env['MOAMALAT_TERMINAL_ID'] ?? _envTerminalId;
          _secureHashCtrl.text =
              dotenv.env['MOAMALAT_SECURE_HASH'] ?? _envSecureHash;
        });
      }
    } catch (e) {
      // If .env file is not found or has errors, use defaults
      // Silently fall back to default values
    }
  }

  @override
  void dispose() {
    _merchantIdCtrl.dispose();
    _terminalIdCtrl.dispose();
    _secureHashCtrl.dispose();
    _amountCtrl.dispose();
    _transactionDateCtrl.dispose();
    _merchantReferenceCtrl.dispose();
    super.dispose();
  }

  MoamalatPaymentConfig? _buildConfig() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (_merchantIdCtrl.text.trim().isEmpty ||
        _terminalIdCtrl.text.trim().isEmpty ||
        _secureHashCtrl.text.trim().isEmpty ||
        amount == null) {
      _setResult(
        'Invalid config',
        'Fill in merchant id, terminal id, secure hash, amount.',
        isError: true,
      );
      return null;
    }
    return MoamalatPaymentConfig(
      environment: _environment,
      merchantId: _merchantIdCtrl.text.trim(),
      terminalId: _terminalIdCtrl.text.trim(),
      secureHash: _secureHashCtrl.text.trim(),
      amount: amount,
      transactionDate: _transactionDateCtrl.text.trim(),
      currencyCode: 434,
      merchantReference: _merchantReferenceCtrl.text.trim().isEmpty
          ? null
          : _merchantReferenceCtrl.text.trim(),
    );
  }

  void _setResult(String label, String body, {bool isError = false}) {
    setState(() {
      _resultLabel = label;
      _resultBody = body;
      _resultColor = isError ? Colors.red.shade50 : Colors.green.shade50;
    });
  }

  Future<void> _showSheet() async {
    final config = _buildConfig();
    if (config == null) return;
    try {
      final response = await showMoamalatPaymentSheet(
        context,
        config: config,
        cvvRequired: false,
        initialCardNumber: _demoCardNumber,
        initialCardHolderName: _demoCardHolder,
        initialExpiryDate: _demoExpiry,
      );
      if (!mounted) return;
      if (response == null) {
        _setResult('Cancelled', 'User dismissed the sheet.', isError: true);
      } else {
        _setResult('Success', _pretty(response.rawJson));
      }
    } on MoamalatPaymentError catch (e) {
      if (mounted) _setResult('Error', e.toString(), isError: true);
    }
  }

  void _pushInlineForm() {
    final config = _buildConfig();
    if (config == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Inline form demo')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: MoamalatCardPaymentForm(
                config: config,
                cvvRequired: false,
                initialCardNumber: _demoCardNumber,
                initialCardHolderName: _demoCardHolder,
                initialExpiryDate: _demoExpiry,
                onSuccess: (response) {
                  Navigator.of(context).pop();
                  if (!mounted) return;
                  _setResult('Success (inline)', _pretty(response.rawJson));
                },
                onError: (error) {
                  Navigator.of(context).pop();
                  if (!mounted) return;
                  _setResult('Error (inline)', error.toString(), isError: true);
                },
                onCancel: () {
                  Navigator.of(context).pop();
                  if (!mounted) return;
                  _setResult(
                    'Cancelled (inline)',
                    'User backed out of 3DS.',
                    isError: true,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _pretty(Map<String, dynamic> json) =>
      const JsonEncoder.withIndent('  ').convert(json);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moamalat Pay Playground')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<MoamalatEnvironment>(
                segments: const [
                  ButtonSegment(
                    value: MoamalatEnvironment.testing,
                    label: Text('Testing'),
                  ),
                  ButtonSegment(
                    value: MoamalatEnvironment.production,
                    label: Text('Production'),
                  ),
                ],
                selected: {_environment},
                onSelectionChanged: (s) {
                  setState(() {
                    _environment = s.first;
                  });
                  _loadEnvFile();
                },
              ),
              const SizedBox(height: 16),
              _input(_merchantIdCtrl, 'Merchant ID'),
              _input(_terminalIdCtrl, 'Terminal ID'),
              _input(_secureHashCtrl, 'Secure hash (hex)'),
              _input(_amountCtrl, 'Amount'),
              _input(_transactionDateCtrl, 'Transaction date'),
              _input(_merchantReferenceCtrl, 'Merchant reference (optional)'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _showSheet,
                icon: const Icon(Icons.payment),
                label: const Text('Show payment sheet'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pushInlineForm,
                icon: const Icon(Icons.credit_card),
                label: const Text('Show inline card form'),
              ),
              const SizedBox(height: 16),
              if (_resultLabel != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _resultColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _resultLabel!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _resultBody ?? '',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
