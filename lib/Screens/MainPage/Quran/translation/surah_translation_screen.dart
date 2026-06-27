import "package:flutter/material.dart";
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../../../Models/aya_list_model.dart';
import '../../../../components/tranlation_card_section.dart';
import '../../../../Provider/audio_provider.dart';
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

class _SurahTranslationScreenState extends State<SurahTranslationScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _lastIndex;
  AudioProvider? _audioProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioProvider = Provider.of<AudioProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _audioProvider?.stopPlayback();
    _scrollController.dispose();
    super.dispose();
  }

  List<Aya> get _displayAyats =>
      widget.ayatList?.where((a) => a.ayatNumber != "0").toList() ?? [];

  double _estimatedCardHeight(ThemeProvider bloc) =>
      bloc.arabicFontSize + bloc.urduFontSize + 160;

  void _scrollToIndex(int index, ThemeProvider bloc) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      index * _estimatedCardHeight(bloc),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<ThemeProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final ayats = _displayAyats;

    if (audioProvider.currentAyahIndex != null &&
        audioProvider.currentAyahIndex != _lastIndex) {
      _lastIndex = audioProvider.currentAyahIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToIndex(_lastIndex!, bloc);
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
                return TranlationCardSection(
                  provider: bloc,
                  ayats: ayats,
                  index: i,
                  isHighlighted: audioProvider.currentAyahIndex == i,
                );
              },
            ),
            const QuranAudioOverlay(),
          ],
        ),
      ),
    );
  }
}
