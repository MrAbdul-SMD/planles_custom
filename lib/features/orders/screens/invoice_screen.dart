import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../providers/orders_providers.dart';

/// In-app viewer for an order's invoice PDF, with a download/share action.
class InvoiceScreen extends ConsumerStatefulWidget {
  const InvoiceScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  Uint8List? _bytes;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await ref.read(ordersRepositoryProvider).invoice(widget.id);
      if (bytes.isEmpty) {
        throw Exception('empty');
      }
      setState(() => _bytes = Uint8List.fromList(bytes));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _download() async {
    final bytes = _bytes;
    if (bytes == null) return;
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'factuur-${widget.id}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderDetailOpenInvoice),
        actions: [
          if (_bytes != null)
            IconButton(
              tooltip: l10n.orderDetailDownloadInvoice,
              onPressed: _download,
              icon: const Icon(Icons.download_rounded),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(
                  message: l10n.orderDetailOpenInvoiceFailed,
                  onRetry: _load,
                )
              : PdfPreview(
                  build: (_) async => _bytes!,
                  allowPrinting: false,
                  allowSharing: true,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  pdfFileName: 'factuur-${widget.id}.pdf',
                  loadingWidget: const Center(child: CircularProgressIndicator()),
                ),
    );
  }
}
