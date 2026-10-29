import "package:flutter/material.dart";
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../../../Models/aya_list_model.dart';
import '../../../../Models/para_model.dart' hide Aya;
import '../../../../components/tranlation_card_section.dart';
import '../../../../Provider/audio_provider.dart';
import '../../../../Utils/recitation_reveal.dart';
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

class _ParahTranslationScreenState extends State<ParahTranslationScreen>
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
                    key: ValueKey(
                      'para_tr_${bloc.arabicFontSize}_${bloc.urduFontSize}_'
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
                          isHighlighted:
                              audioProvider.isReciting(ayats[i].ayatId),
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
