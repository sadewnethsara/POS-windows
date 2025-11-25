import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class BarcodeListener extends StatefulWidget {
  final Widget child;
  final Function(String) onBarcodeScanned;

  const BarcodeListener({
    super.key,
    required this.child,
    required this.onBarcodeScanned,
  });

  @override
  State<BarcodeListener> createState() => _BarcodeListenerState();
}

class _BarcodeListenerState extends State<BarcodeListener> {
  final FocusNode _focusNode = FocusNode();
  String _buffer = '';
  DateTime _lastKeyTime = DateTime.now();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final now = DateTime.now();
      // If keys are pressed too slowly, it's likely manual typing, not a scanner.
      // Reset buffer if gap is > 100ms (scanners are fast).
      if (now.difference(_lastKeyTime).inMilliseconds > 100) {
        _buffer = '';
      }
      _lastKeyTime = now;

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_buffer.isNotEmpty) {
          widget.onBarcodeScanned(_buffer);
          _buffer = '';
        }
      } else {
        // Only append printable characters
        if (event.character != null && event.character!.isNotEmpty) {
          _buffer += event.character!;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}
