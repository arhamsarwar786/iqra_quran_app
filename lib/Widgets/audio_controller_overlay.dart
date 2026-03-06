import 'package:flutter/material.dart';
import 'package:iqra/Provider/audio_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';

class QuranAudioOverlay extends StatelessWidget {
  const QuranAudioOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    if (audioProvider.currentAyahIndex == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: themeProvider.selectedTheme.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Loading/Buffering indicator
              if (audioProvider.isBuffering)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                Icon(Icons.mic_none_outlined,
                    color: themeProvider.selectedTheme, size: 28),

              const SizedBox(width: 15),

              // Current Surah & Ayah info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      audioProvider.currentSurahName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: themeProvider.selectedTheme,
                      ),
                    ),
                    Text(
                      "Reciting Verse ${audioProvider.currentAyahIndex! + 1}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Play/Pause
                  IconButton(
                    onPressed: () {
                      if (audioProvider.isPlaying) {
                        audioProvider.pausePlayback();
                      } else {
                        audioProvider.resumePlayback();
                      }
                    },
                    icon: Icon(
                      audioProvider.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      color: themeProvider.selectedTheme,
                      size: 38,
                    ),
                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(width: 5),

                  // Stop
                  IconButton(
                    onPressed: () => audioProvider.stopPlayback(),
                    icon: const Icon(Icons.stop_circle_rounded,
                        color: Colors.redAccent, size: 38),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
