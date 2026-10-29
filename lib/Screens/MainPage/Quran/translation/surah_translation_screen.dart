import "package:flutter/material.dart";
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../../../Models/aya_list_model.dart';
import '../../../../components/tranlation_card_section.dart';
import '../../../../Provider/audio_provider.dart';
import '../../../../Utils/recitation_reveal.dart';
import '../../../../Widgets/audio_controller_overlay.dart';

class SurahTranslationScreen extends StatefulWidget {
  SurahTranslationScreen(
      {super.key,
      this.ayatList,
      this.ayatCount,
      this.suratNumber,
      this.surahName});
  final String? ayatCount;
  final List<Aya>? ayatList;
  final int? suratNumber;
  final String? surahName;

  @override
  State<SurahTranslationScreen> createState() => _SurahTranslationScreenState();
}

class _SurahTranslationScreenState extends State<SurahTranslationScreen>
    with RecitationReaderScreen {
  final ScrollController _scrollController = ScrollController();
  int? _lastIndex;
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Aya> get _displayAyats =>
      widget.ayatList?.where((a) => a.ayatNumber != "0").toList() ?? [];

  GlobalKey _keyFor(int index) => _itemKeys.putIfAbsent(index, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<ThemeProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final ayats = _displayAyats;

    final playingId = audioProvider.currentAyahId;
    final playingIndex =
        playingId == null ? -1 : ayats.indexWhere((a) => a.ayatId == playingId);
    if (playingIndex < 0) {
      _lastIndex = null;
    } else if (playingIndex != _lastIndex) {
      _lastIndex = playingIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        revealLazyRecitation(
          controller: _scrollController,
          keys: _itemKeys,
          index: playingIndex,
          count: ayats.length,
        );
      });
    }

    return Scaffold(
      backgroundColor: bloc.selectedSecondary,
      appBar: AppBar(
        title: Text(
          "${widget.surahName} Translation",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: bloc.selectedTheme,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView.builder(
              key: ValueKey(
                'surah_tr_${bloc.arabicFontSize}_${bloc.urduFontSize}_'
                '${bloc.arabicFontFamily}_${bloc.urduFontFamily}',
              ),
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 100),
              itemCount: ayats.length,
              itemBuilder: (context, i) {
                return KeyedSubtree(
                  key: _keyFor(i),
                  child: TranlationCardSection(
                    provider: bloc,
                    ayats: ayats,
                    index: i,
                    isHighlighted: audioProvider.isReciting(ayats[i].ayatId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
