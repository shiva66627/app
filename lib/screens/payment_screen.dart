import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final String pdfTitle;
  final int amount; // in paise (₹1 = 100)
  final VoidCallback? onPaymentSuccess; // ✅ Callback to unlock notes

  const PaymentScreen({
    super.key,
    required this.pdfTitle,
    required this.amount, // ✅ always pass from notes.dart
    this.onPaymentSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _openCheckout() {
    var options = {
      'key': 'rzp_test_RGfTAuTohoJpta', // 🔑 replace with your live key
      'amount': widget.amount, // ✅ dynamic subject price
      'name': 'MBBS Freaks',
      'description': widget.pdfTitle,
      'prefill': {
        'contact': '9876543210',
        'email': 'testuser@gmail.com',
      },
      'method': {
        'upi': true,
        'card': true,
        'netbanking': true,
        'wallet': true,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("⚠️ Razorpay error: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Payment Successful: ${response.paymentId}")),
    );

    // ✅ Unlock premium content in NotesPage
    if (widget.onPaymentSuccess != null) {
      widget.onPaymentSuccess!();
    }

    Navigator.pop(context); // go back after success
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ ERROR: ${response.code} - ${response.message}"),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Wallet Selected: ${response.walletName}")),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amountInRupees = widget.amount ~/ 100; // convert paise → ₹
    return Scaffold(
      appBar: AppBar(title: const Text("Unlock Premium")),
      body: Center(
        child: ElevatedButton(
          onPressed: _openCheckout,
          child: Text("Pay Now ₹$amountInRupees"),
        ),
      ),
    );
  }
}
