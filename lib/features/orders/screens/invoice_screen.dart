import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/loading.dart';
import '../../../shared/widgets.dart';
import '../providers/orders_providers.dart';
import 'invoice_download.dart';

/// In-app viewer for an order's invoice PDF, with download/share actions.
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

  String get _fileName => 'factuur-${widget.id}.pdf';

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
      if (!mounted) return;
      setState(() => _bytes = Uint8List.fromList(bytes));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = describeError(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download() async {
    final bytes = _bytes;
    if (bytes == null) return;
    try {
      await downloadInvoicePdf(bytes, _fileName);
      if (mounted && !kIsWeb) {
        showAppSnack(context, context.l10n.orderDetailDownloadInvoice);
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, describeError(context, e), error: true);
      }
    }
  }

  Future<void> _share() async {
    final bytes = _bytes;
    if (bytes == null) return;
    try {
      await Printing.sharePdf(bytes: bytes, filename: _fileName);
    } catch (e) {
      if (mounted) {
        showAppSnack(context, describeError(context, e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderDetailOpenInvoice),
        actions: [
          if (_bytes != null) ...[
            IconButton(
              tooltip: l10n.orderDetailDownloadInvoice,
              onPressed: _download,
              icon: const Icon(Icons.download_rounded),
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).shareButtonLabel,
              onPressed: _share,
              icon: const Icon(Icons.ios_share_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
      body: AnimatedSwitcher(
        duration: 250.ms,
        child: _buildBody(context, l10n, scheme),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    dynamic l10n,
    ColorScheme scheme,
  ) {
    if (_loading) {
      return KeyedSubtree(
        key: const ValueKey('loading'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _fileName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Expanded(child: AppSkeletonList(itemCount: 4, height: 120)),
            ],
          ),
        ).animate().fadeIn(duration: 200.ms),
      );
    }

    if (_error != null || _bytes == null) {
      return KeyedSubtree(
        key: const ValueKey('error'),
        child: ErrorView(
          message: _error ?? l10n.orderDetailOpenInvoiceFailed,
          onRetry: _load,
        ),
      );
    }

    return KeyedSubtree(
      key: const ValueKey('viewer'),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.description_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _fileName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.05, end: 0),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: PdfPreview(
                build: (_) async => _bytes!,
                allowPrinting: false,
                allowSharing: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                useActions: false,
                scrollViewDecoration: BoxDecoration(color: scheme.surfaceContainer),
                pdfPreviewPageDecoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                pdfFileName: _fileName,
                loadingWidget: const Center(child: CircularProgressIndicator()),
                onError: (context, error) => ErrorView(
                  message: describeError(context, error),
                  onRetry: _load,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
