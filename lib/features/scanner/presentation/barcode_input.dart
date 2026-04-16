// lib/features/scanner/presentation/barcode_input.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum BarcodeInputTab { camera, keyboard }

class BarcodeInput extends StatefulWidget {
  final void Function(String barcode) onBarcode;
  final BarcodeInputTab initialTab;

  const BarcodeInput({
    super.key,
    required this.onBarcode,
    this.initialTab = BarcodeInputTab.camera,
  });

  @override
  State<BarcodeInput> createState() => _BarcodeInputState();
}

class _BarcodeInputState extends State<BarcodeInput>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == BarcodeInputTab.keyboard ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _submitKeyboard() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onBarcode(text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt), text: 'Cámara'),
            Tab(icon: Icon(Icons.keyboard), text: 'Teclado'),
          ],
        ),
        SizedBox(
          height: 280,
          child: TabBarView(
            controller: _tab,
            children: [
              _cameraTab(),
              _keyboardTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cameraTab() {
    // Do not instantiate MobileScanner when initial tab is keyboard
    // (avoids camera permission issues in tests)
    if (widget.initialTab == BarcodeInputTab.keyboard) {
      return const Center(child: Text('Cámara inactiva'));
    }
    if (kIsWeb) {
      // On Web, MobileScanner requires HTTPS or localhost — handled internally
    }
    return MobileScanner(
      onDetect: (capture) {
        final code = capture.barcodes.firstOrNull?.rawValue;
        if (code != null && code.isNotEmpty) {
          widget.onBarcode(code);
        }
      },
    );
  }

  Widget _keyboardTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ingresa el código de barras',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submitKeyboard(),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _submitKeyboard, child: const Text('Usar')),
        ],
      ),
    );
  }
}
