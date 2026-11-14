import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_update_service.dart';

class AppUpdatePrompt {
  static final AppUpdateService _service = AppUpdateService();
  static bool _checkedThisSession = false;
  static bool _checking = false;

  /// Checks GitHub Releases once per app session and shows an update dialog
  /// when a newer version with a matching platform asset is available.
  static Future<void> checkAndPrompt(
    BuildContext context, {
    bool force = false,
    bool silent = true,
    bool includePrereleases = false,
  }) async {
    if (_checking) return;
    if (!force && _checkedThisSession) return;
    _checking = true;
    try {
      final info = await _service.checkForUpdate(includePrereleases: includePrereleases);
      _checkedThisSession = true;
      if (!context.mounted) return;

      if (info == null) {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are using the latest version.')),
          );
        }
        return;
      }

      await _showDialog(context, info);
    } finally {
      _checking = false;
    }
  }

  static Future<void> _showDialog(BuildContext context, AppUpdateInfo info) async {
    final hasAsset = info.assetUrl != null && info.assetUrl!.isNotEmpty;
    final notes = info.releaseNotes.trim();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Update available'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A new version of Planles is available.'),
                const SizedBox(height: 8),
                Text('Current: ${info.currentVersion}'),
                Text('Latest: ${info.latestVersion}${info.tagName.isNotEmpty ? ' (${info.tagName})' : ''}'),
                if (info.assetName != null && info.assetName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Download: ${info.assetName}', style: Theme.of(ctx).textTheme.bodySmall),
                ],
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('What\'s new', style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    notes.length > 1200 ? '${notes.substring(0, 1200)}…' : notes,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ] else if (!hasAsset && kIsWeb) ...[
                  const SizedBox(height: 12),
                  const Text('Refresh the page to load the latest web version.'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () async {
                await _openUrl(info.htmlUrl);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Release'),
            ),
            FilledButton(
              onPressed: () async {
                final url = hasAsset ? info.assetUrl! : info.htmlUrl;
                await _openUrl(url);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(hasAsset ? 'Update' : 'Open'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
