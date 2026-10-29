import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../Provider/quran_data_provider.dart';
import '../../../Provider/theme_provider.dart';
import '../../../Services/recitation_downloads.dart';
import '../../../Services/recitation_playlist.dart';
import '../../../Widgets/recitation_download_button.dart';
import '../../../widgets.dart';

/// Every surah and para with its download state, for saving or removing
/// recitation in one place.
class RecitationDownloadsScreen extends StatelessWidget {
  const RecitationDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final downloads = context.watch<RecitationDownloads>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.selectedSecondary,
        appBar: AppBar(
          title: const Text('Offline Recitation'),
          actions: [
            if (downloads.savedFiles > 0)
              IconButton(
                tooltip: 'Remove all downloads',
                icon: const Icon(Icons.delete_sweep_rounded),
                onPressed: () => _confirmDeleteAll(context),
              ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [Tab(text: 'Surahs'), Tab(text: 'Paras')],
          ),
        ),
        body: Consumer<QuranDataProvider>(
          builder: (context, quran, _) {
            if (!quran.isLoaded) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => quran.loadQuranData());
              return Center(
                  child: CircularProgressIndicator(color: theme.selectedTheme));
            }
            return NestedScrollView(
              headerSliverBuilder: (context, _) => const [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: QuranDownloadCard(),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
                    itemCount: quran.surahMetadata.length,
                    itemBuilder: (context, index) {
                      final surah = quran.surahMetadata[index];
                      return _DownloadRow(
                        number: surah.surahId,
                        title: surah.surahName,
                        subtitle: surah.romanEngName.isNotEmpty
                            ? surah.romanEngName
                            : surah.romanName,
                        target: DownloadTarget.surah(surah.surahId),
                      );
                    },
                  ),
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
                    itemCount: quran.paraMetadata.length,
                    itemBuilder: (context, index) {
                      final para = quran.paraMetadata[index];
                      final number = para.paraId ?? index + 1;
                      return _DownloadRow(
                        number: number,
                        title: para.paraName ?? 'Para $number',
                        subtitle: 'Para $number',
                        target: DownloadTarget.para(number),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final theme = context.read<ThemeProvider>().selectedTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove all downloads?'),
        content: const Text(
            'All downloaded recitation will be removed from this device to '
            'free up space. You can still listen online.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: theme),
            child: const Text('Remove all',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<RecitationDownloads>().deleteAll();
    }
  }
}

class _DownloadRow extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final DownloadTarget target;

  const _DownloadRow({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final status = context
        .watch<RecitationDownloads>()
        .statusOf(target, context.read<QuranDataProvider>());
    final color = theme.selectedTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            status.isDone ? Border.all(color: color.withOpacity(0.35)) : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color,
                  child: Text('$number',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(_statusText(status),
                          style: TextStyle(
                              fontSize: 12,
                              color: status.isDone || status.isBusy
                                  ? color
                                  : Colors.grey[600])),
                    ],
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: theme.arabicFontFamily,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                RecitationDownloadButton(target: target, size: 28),
              ],
            ),
          ),
          if (status.isBusy ||
              status.state == DownloadState.partial ||
              status.state == DownloadState.paused)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(14)),
              child: LinearProgressIndicator(
                value: status.state == DownloadState.queued
                    ? null
                    : status.progress,
                minHeight: 3,
                color: color,
                backgroundColor: color.withOpacity(0.12),
              ),
            ),
        ],
      ),
    );
  }

  String _statusText(DownloadStatus status) {
    switch (status.state) {
      case DownloadState.done:
        return 'Downloaded · available offline';
      case DownloadState.downloading:
        return 'Downloading ${(status.progress * 100).floor()}% · '
            '${status.saved} of ${status.total}';
      case DownloadState.queued:
        return 'Waiting to download…';
      case DownloadState.paused:
        return 'Paused, waiting for connection';
      case DownloadState.partial:
        return '${(status.progress * 100).floor()}% saved · tap to resume';
      case DownloadState.notDownloaded:
        return 'Not downloaded';
    }
  }
}

/// Progress of the complete Quran download, with what is downloading now
/// and the space used.
class QuranDownloadCard extends StatelessWidget {
  /// Shows a button to [RecitationDownloadsScreen], for use outside it.
  final bool showManage;

  const QuranDownloadCard({super.key, this.showManage = false});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().selectedTheme;
    final deep = Color.lerp(theme, Colors.black, 0.35)!;
    final quran = context.watch<QuranDataProvider>();
    final downloads = context.watch<RecitationDownloads>();
    if (!quran.isLoaded) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => quran.loadQuranData());
    }

    const target = DownloadTarget.quran();
    final status = downloads.statusOf(target, quran);
    final numbers = NumberFormat.decimalPattern();
    final active = downloads.activeTitle;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme, deep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: deep.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.headphones_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Complete Quran',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17)),
                    Text(RecitationPlaylist.reciterName,
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                '${(status.progress * 100).floor()}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: status.progress),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                color: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${numbers.format(status.saved)} of ${numbers.format(status.total)} '
            'files · ${formatBytes(downloads.storageBytes)} on device',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (active != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Downloading $active'
                    '${downloads.queuedCount > 0 ? ' · ${downloads.queuedCount} waiting' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: status.isDone || !quran.isLoaded
                      ? null
                      : () => RecitationDownloadActions.onTap(context, target),
                  icon: Icon(_buttonIcon(status)),
                  label: Text(_buttonLabel(status)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme,
                    disabledBackgroundColor: Colors.white.withOpacity(0.85),
                    disabledForegroundColor: theme,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (showManage) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () =>
                      push(context, const RecitationDownloadsScreen()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Manage'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _buttonIcon(DownloadStatus status) {
    if (status.isDone) return Icons.download_done_rounded;
    if (status.isBusy) return Icons.stop_rounded;
    return Icons.download_rounded;
  }

  String _buttonLabel(DownloadStatus status) {
    switch (status.state) {
      case DownloadState.done:
        return 'Available offline';
      case DownloadState.queued:
      case DownloadState.downloading:
        return 'Stop download';
      case DownloadState.partial:
      case DownloadState.paused:
        return 'Resume download';
      case DownloadState.notDownloaded:
        return 'Download all';
    }
  }
}
