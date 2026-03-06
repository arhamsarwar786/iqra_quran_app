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

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      index * 220.0, // rough estimate of card height
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ThemeProvider>();
    final audioProvider = context.watch<AudioProvider>();

    if (audioProvider.currentAyahIndex != null &&
        audioProvider.currentAyahIndex != _lastIndex) {
      _lastIndex = audioProvider.currentAyahIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToIndex(_lastIndex!);
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
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 100),
              itemCount: widget.ayatList?.length ?? 0,
              itemBuilder: (context, i) {
                return TranlationCardSection(
                  provider: bloc,
                  ayats: widget.ayatList!,
                  index: i,
                  isHighlighted: audioProvider.currentAyahIndex != null &&
                      audioProvider.currentAyahIndex ==
                          i - (widget.ayatList![0].ayatNumber == "0" ? 1 : 0),
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
