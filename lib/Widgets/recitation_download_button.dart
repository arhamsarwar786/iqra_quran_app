import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Provider/audio_provider.dart';
import '../Provider/quran_data_provider.dart';
import '../Provider/theme_provider.dart';
import '../Services/recitation_downloads.dart';

/// What tapping a download button does: start or resume the download,
/// cancel it while it runs, or offer to remove it once saved.
class RecitationDownloadActions {
  static Future<void> onTap(BuildContext context, DownloadTarget target) async {
    final downloads = context.read<RecitationDownloads>();
    final quran = context.read<QuranDataProvider>();
    if (!quran.isLoaded) return;
    final status = downloads.statusOf(target, quran);
    final title = target.titleFrom(quran);

    if (status.isBusy) {
      downloads.cancel(target);
      _message(context, 'Download of $title stopped. Saved ayahs are kept.');
      return;
    }
    if (status.isDone) {
      if (await _confirmDelete(context, title)) {
        await downloads.delete(target, quran);
        if (context.mounted) _message(context, '$title removed from device');
      }
      return;
    }
    if (target.kind == DownloadKind.quran &&
        !await _confirmQuranDownload(context)) {
      return;
    }
    if (!context.mounted) return;
    if (!await context.read<AudioProvider>().checkConnection()) {
      if (context.mounted) {
        _message(context, 'No internet connection. Connect to download.');
      }
      return;
    }
    if (!context.mounted) return;
    if (downloads.download(target, quran)) {
      _message(
          context,
          Platform.isAndroid
              ? 'Downloading $title. Follow progress in the notification bar.'
              : 'Downloading $title…');
    }
  }

  /// Short label for the state, e.g. under a bottom bar icon.
  static String labelFor(DownloadStatus status) {
    switch (status.state) {
      case DownloadState.notDownloaded:
        return 'Download';
      case DownloadState.partial:
        return 'Resume';
      case DownloadState.queued:
        return 'Queued';
      case DownloadState.downloading:
        return '${(status.progress * 100).floor()}%';
      case DownloadState.paused:
        return 'Paused';
      case DownloadState.done:
        return 'Offline';
    }
  }

  static void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2500),
      ));
  }

  static Future<bool> _confirmDelete(BuildContext context, String title) async {
    final theme = context.read<ThemeProvider>().selectedTheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove download?'),
        content: Text(
            '$title will be removed from this device. You can still listen '
            'to it online or download it again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: theme),
            child: const Text('Remove',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<bool> _confirmQuranDownload(BuildContext context) async {
    final theme = context.read<ThemeProvider>().selectedTheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.download_for_offline_rounded, color: theme),
            const SizedBox(width: 10),
            const Expanded(child: Text('Download complete Quran?')),
          ],
        ),
        content: const Text(
            'The full recitation by Mishary Rashid Alafasy is about 1 GB. '
            'We recommend Wi-Fi.\n\nAyahs you have already downloaded are '
            'skipped, and you can stop at any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// Download control for a surah, para or the whole Quran. Shows a progress
/// ring while downloading and a check once the recitation is on the device.
class RecitationDownloadButton extends StatelessWidget {
  final DownloadTarget target;
  final double size;

  /// Icon and ring colour; defaults to the theme colour.
  final Color? color;

  /// Icon colour on the filled "downloaded" badge.
  final Color onColor;

  const RecitationDownloadButton({
    super.key,
    required this.target,
    this.size = 24,
    this.color,
    this.onColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final quran = context.watch<QuranDataProvider>();
    if (!quran.isLoaded) return SizedBox(width: size, height: size);
    final status = context.watch<RecitationDownloads>().statusOf(target, quran);
    final color = this.color ?? context.watch<ThemeProvider>().selectedTheme;

    return Semantics(
      button: true,
      label: _semanticLabel(status),
      child: InkResponse(
        onTap: () => RecitationDownloadActions.onTap(context, target),
        radius: size,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: RecitationDownloadIcon(
              status: status, size: size, color: color, onColor: onColor),
        ),
      ),
    );
  }

  String _semanticLabel(DownloadStatus status) {
    switch (status.state) {
      case DownloadState.done:
        return 'Downloaded. Remove download';
      case DownloadState.queued:
      case DownloadState.downloading:
        return 'Downloading ${(status.progress * 100).floor()} percent. '
            'Stop download';
      default:
        return 'Download for offline listening';
    }
  }
}

/// The icon of [RecitationDownloadButton], without the tap handling.
class RecitationDownloadIcon extends StatelessWidget {
  final DownloadStatus status;
  final double size;
  final Color color;
  final Color onColor;

  const RecitationDownloadIcon({
    super.key,
    required this.status,
    required this.size,
    required this.color,
    this.onColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: _icon(),
      ),
    );
  }

  Widget _icon() {
    switch (status.state) {
      case DownloadState.done:
        return Container(
          key: const ValueKey('done'),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(Icons.download_done_rounded,
              color: onColor, size: size * 0.7),
        );
      case DownloadState.queued:
        return _ring(
          key: const ValueKey('busy'),
          value: null,
          icon: Icons.stop_rounded,
        );
      case DownloadState.downloading:
        return _ring(
          key: const ValueKey('busy'),
          value: status.progress,
          icon: Icons.stop_rounded,
        );
      case DownloadState.partial:
      case DownloadState.paused:
        return _ring(
          key: const ValueKey('partial'),
          value: status.progress,
          icon: Icons.download_rounded,
        );
      case DownloadState.notDownloaded:
        return Icon(Icons.download_for_offline_outlined,
            key: const ValueKey('idle'), color: color, size: size);
    }
  }

  Widget _ring(
      {required Key key, required double? value, required IconData icon}) {
    return Stack(
      key: key,
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: value == null
              ? CircularProgressIndicator(
                  strokeWidth: size * 0.1,
                  color: color,
                  backgroundColor: color.withOpacity(0.2),
                )
              // Eases between updates instead of jumping file by file.
              : TweenAnimationBuilder<double>(
                  tween: Tween(end: value),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: size * 0.1,
                    color: color,
                    backgroundColor: color.withOpacity(0.2),
                  ),
                ),
        ),
        Icon(icon, color: color, size: size * 0.55),
      ],
    );
  }
}
