import "package:flutter/material.dart";
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../../../Models/aya_list_model.dart';
import '../../../../Models/para_model.dart' hide Aya;
import '../../../../components/tranlation_card_section.dart';
import '../../../../Provider/audio_provider.dart';
import '../../../../Widgets/audio_controller_overlay.dart';

class ParahTranslationScreen extends StatefulWidget {
  ParahTranslationScreen({
    super.key,
    this.para,
    this.ayatInPara,
    this.parahCount,
    this.parahname,
    this.ayatList,
  });
  final String? parahCount;
  final int? ayatInPara;
  final Para? para;
  final String? parahname;
  final List<Aya>? ayatList;

  @override
  State<ParahTranslationScreen> createState() => _ParahTranslationScreenState();
}

class _ParahTranslationScreenState extends State<ParahTranslationScreen> {
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
          "${widget.parahname} Translation",
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
            widget.ayatList == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 100),
                    itemCount: widget.ayatList!.length,
                    itemBuilder: (context, i) {
                      return TranlationCardSection(
                        provider: bloc,
                        ayats: widget.ayatList!,
                        index: i,
                        isHighlighted: audioProvider.currentAyahIndex != null &&
                            audioProvider.currentAyahIndex ==
                                i -
                                    (widget.ayatList![0].ayatNumber == "0"
                                        ? 1
                                        : 0),
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
