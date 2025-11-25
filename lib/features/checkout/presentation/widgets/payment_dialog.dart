import 'package:fluent_ui/fluent_ui.dart';

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final Function(String method, double tendered) onPaymentConfirmed;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    required this.onPaymentConfirmed,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _selectedMethod = 'Cash';
  final _tenderedController = TextEditingController();
  double _change = 0.0;

  @override
  void initState() {
    super.initState();
    _tenderedController.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _tenderedController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final tendered = double.tryParse(_tenderedController.text) ?? 0.0;
    setState(() {
      _change = tendered - widget.totalAmount;
    });
  }

  void _confirmPayment() {
    final tendered = double.tryParse(_tenderedController.text) ?? 0.0;
    if (_selectedMethod == 'Cash' && tendered < widget.totalAmount) {
      // Show error
      return;
    }
    widget.onPaymentConfirmed(_selectedMethod, tendered);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Amount: \$${widget.totalAmount.toStringAsFixed(2)}',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Payment Method:'),
          const SizedBox(height: 10),
          Row(
            children: [
              RadioButton(
                checked: _selectedMethod == 'Cash',
                content: const Text('Cash'),
                onChanged: (v) => setState(() => _selectedMethod = 'Cash'),
              ),
              const SizedBox(width: 20),
              RadioButton(
                checked: _selectedMethod == 'Card',
                content: const Text('Card'),
                onChanged: (v) => setState(() => _selectedMethod = 'Card'),
              ),
            ],
          ),
          if (_selectedMethod == 'Cash') ...[
            const SizedBox(height: 20),
            TextBox(
              controller: _tenderedController,
              placeholder: 'Amount Tendered',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            Text(
              'Change: \$${_change.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _change >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ],
      ),
      actions: [
        Button(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirmPayment,
          child: const Text('Confirm Payment'),
        ),
      ],
    );
  }
}
