import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Models/aya_list_model.dart';
import 'package:iqra/Screens/MainPage/Quran/verse_detail_screen.dart';
import 'package:iqra/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:developer' as dev;

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isListening = false;
  bool _searchArabic = true;
  bool _searchTranslation = true;
  bool _searchTafseer = true;

  List<Aya> _results = [];
  bool _isSearching = false;
  Timer? _debounce;
  int? _playingIndex;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _requestMicrophonePermission();
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      await Permission.microphone.request();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final query = _searchController.text.trim();
    if (query.length >= 2) {
      if (mounted) {
        setState(() {
          _isSearching = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _results = [];
        });
      }
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  void _performSearch(String query) {
    if (query.trim().length < 2) {
      if (mounted) {
        setState(() {
          _results = [];
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }

    final quranProvider =
        Provider.of<QuranDataProvider>(context, listen: false);
    final results = quranProvider.searchQuran(
      query.trim(),
      searchArabic: _searchArabic,
      searchTranslation: _searchTranslation,
      searchTafseer: _searchTafseer,
    );

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  void _listen() async {
    // Check microphone permission before listening
    var status = await Permission.microphone.status;

    if (status.isPermanentlyDenied) {
      _showSettingsDialog();
      return;
    }

    if (status.isDenied) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        dev.log("Microphone permission denied");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Microphone permission is required for voice search")),
        );
        return;
      }
    }

    // Proactive initialization
    bool available = await _speech.initialize(
      onStatus: (val) => dev.log("Speech status: $val"),
      onError: (val) => dev.log("Speech error: ${val.errorMsg}"),
    );

    if (available) {
      _showVoiceSearchDialog();
    } else {
      dev.log("Speech recognition not available on this device");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Speech recognition is not available or disabled")),
      );
    }
  }

  void _showVoiceSearchDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Voice Search",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _VoiceSearchDialog(
          speech: _speech,
          onSearch: (text) {
            _searchController.text = text;
            _performSearch(text);
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
            "Microphone access is permanently denied. Please enable it in your device settings to use voice search."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  Future<void> _playRecitation(Aya aya, int index) async {
    try {
      dev.log("Attempting to play recitation for Aya ID: ${aya.ayatId}");
      if (_playingIndex == index) {
        await _audioPlayer.stop();
        if (mounted) setState(() => _playingIndex = null);
        return;
      }

      if (mounted) setState(() => _playingIndex = index);

      // Using Alquran.cloud audio CDN (Alafasy reciter)
      // ayatId in our model is global index (1-6236)
      final String audioUrl =
          "https://cdn.islamic.network/quran/audio/128/ar.alafasy/${aya.ayatId}.mp3";

      dev.log("Loading URL: $audioUrl");
      await _audioPlayer.setUrl(audioUrl);
      _audioPlayer.play();

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _playingIndex = null);
        }
      });
    } catch (e) {
      dev.log("Audio playback error: $e");
      if (mounted) {
        setState(() => _playingIndex = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Error playing audio: ${e.toString().split('\n')[0]}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final quranProvider = Provider.of<QuranDataProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: customAppBar(context, "SEARCH QURAN"),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildSearchField(theme),
            _buildFilterChips(theme),
            const SizedBox(height: 10),
            Expanded(
              child: _buildResultsList(theme, quranProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.selectedTheme.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: "Search Arabic or Translation...",
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
            prefixIcon: Icon(Icons.search, color: theme.selectedTheme),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => _searchController.clear(),
                  ),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : theme.selectedTheme),
                  onPressed: _listen,
                ),
              ],
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
          onSubmitted: _performSearch,
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeProvider theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
          _filterChip("Arabic", _searchArabic,
              (val) => setState(() => _searchArabic = val), theme),
          const SizedBox(width: 10),
          _filterChip("Translation", _searchTranslation,
              (val) => setState(() => _searchTranslation = val), theme),
          const SizedBox(width: 10),
          _filterChip("Tafseer", _searchTafseer,
              (val) => setState(() => _searchTafseer = val), theme),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, Function(bool) onSelected,
      ThemeProvider theme) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        onSelected(val);
        _performSearch(_searchController.text);
      },
      selectedColor: theme.selectedTheme.withOpacity(0.2),
      checkmarkColor: theme.selectedTheme,
      labelStyle: TextStyle(
        color: selected ? theme.selectedTheme : Colors.grey[700],
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
            color: selected ? theme.selectedTheme : Colors.grey[300]!),
      ),
    );
  }

  Widget _buildResultsList(
      ThemeProvider theme, QuranDataProvider quranProvider) {
    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(color: theme.selectedTheme),
      );
    }

    if (_results.isEmpty) {
      if (_searchController.text.length < 2) {
        return _buildEmptyState(
            "Type a keyword to search", Icons.search_outlined, theme);
      }
      return _buildEmptyState(
          "No results found for '${_searchController.text}'",
          Icons.sentiment_dissatisfied,
          theme);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Text(
                "Search Results",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    fontSize: 16),
              ),
              const Spacer(),
              Text(
                "${_results.length} found",
                style: TextStyle(
                    color: theme.selectedTheme, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemBuilder: (context, index) {
              final aya = _results[index];
              final surah =
                  quranProvider.getSurahMetadata(int.parse(aya.surahId ?? "1"));
              final isPlaying = _playingIndex == index;

              return _buildResultCard(
                  aya, surah, theme, quranProvider, index, isPlaying);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(Aya aya, var surah, ThemeProvider theme,
      QuranDataProvider quranProvider, int index, bool isPlaying) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              push(
                context,
                VerseDetailScreen(
                  aya: aya,
                  surahMetadata: surah,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.selectedTheme.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${surah?.name ?? ""} : ${aya.ayatNumber}",
                          style: TextStyle(
                            color: theme.selectedTheme,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: theme.selectedTheme,
                          size: 30,
                        ),
                        onPressed: () => _playRecitation(aya, index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    aya.arabicText,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: theme.arabicFontFamily,
                      height: 1.5,
                      color: const Color(0xFF2D3436),
                    ),
                  ),
                  if (_searchTranslation &&
                      (aya.tarjumaIrfan?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 12),
                    Text(
                      aya.tarjumaIrfan!,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: theme.urduFontFamily,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (_searchTafseer &&
                      (aya.withoutHtmlTafseer?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        aya.withoutHtmlTafseer!.length > 150
                            ? "${aya.withoutHtmlTafseer!.substring(0, 150)}..."
                            : aya.withoutHtmlTafseer!,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VoiceSearchDialog extends StatefulWidget {
  final stt.SpeechToText speech;
  final Function(String) onSearch;

  const _VoiceSearchDialog({
    Key? key,
    required this.speech,
    required this.onSearch,
  }) : super(key: key);

  @override
  State<_VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<_VoiceSearchDialog> {
  double _level = 0.0;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: "");
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.speech.stop(); // Stop listening if user starts editing
      }
    });
    _startListening();
  }

  @override
  void dispose() {
    widget.speech.stop();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _startListening() {
    widget.speech.listen(
      localeId: "ur-PK", // Exclusively track Urdu
      onResult: (val) {
        if (!_focusNode.hasFocus) {
          setState(() {
            _controller.text = val.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          });

          // Automatically search when the user completes the sentence
          if (val.finalResult && val.recognizedWords.trim().isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                widget.onSearch(val.recognizedWords.trim());
                Navigator.pop(context);
              }
            });
          }
        }
      },
      onSoundLevelChange: (level) {
        setState(() {
          _level = level;
        });
      },
      listenFor: const Duration(seconds: 30),
      cancelOnError: true,
      partialResults: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Microphone & Waves
            SizedBox(
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated pulse circles
                  _PulseCircle(level: _level, color: theme.selectedTheme),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.selectedTheme,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(15),
                    child: const Icon(Icons.mic, color: Colors.white, size: 40),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "اب بولیں (اردو)...",
              style: TextStyle(
                color: theme.selectedTheme,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: theme.urduFontFamily,
              ),
            ),
            const SizedBox(height: 25),
            // Text Feed (Editable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl, // Right-to-Left for Urdu
                maxLines: 3,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    fontFamily: theme.urduFontFamily),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "آپ کی آواز یہاں نظر آئے گی...",
                  hintTextDirection: TextDirection.rtl,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final searchText = _controller.text.trim();
                      if (searchText.isNotEmpty) {
                        widget.onSearch(searchText);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.selectedTheme,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Search",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseCircle extends StatelessWidget {
  final double level;
  final Color color;

  const _PulseCircle({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    // level is usually between -10 and 10 or 0 and 10 depending on package
    // Normalizing it for scale
    double scale = 1.0 + (level.abs() / 15.0).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: scale),
      duration: const Duration(milliseconds: 100),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80 * value,
              height: 80 * value,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 110 * value,
              height: 110 * value,
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }
}
