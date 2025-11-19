import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:quran_myapp/core/config.dart';
import 'package:quran_myapp/models/surah_details.dart';
import 'package:quran_myapp/widgets/surah_card.dart';

class SurahDetailsScreen extends StatefulWidget {
  final int surahNumber;
  const SurahDetailsScreen({super.key, required this.surahNumber});

  static const String routeName = '/surah_details';

  @override
  State<SurahDetailsScreen> createState() => _SurahDetailsScreenState();
}

class _SurahDetailsScreenState extends State<SurahDetailsScreen> {
  late Future<SurahDetails> data;
  final AudioPlayer player = AudioPlayer();

  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Stream Subscriptions
  late StreamSubscription<PlayerState> _playerStateSubscription;
  late StreamSubscription<Duration?> _durationSubscription;
  late StreamSubscription<Duration> _positionSubscription;

  @override
  void initState() {
    super.initState();
    data = _fetchSurah();

    // Listen player state changes
    _playerStateSubscription = player.playerStateStream.listen((state) {
      final playing = state.playing;
      final processingState = state.processingState;
      if (processingState == ProcessingState.completed) {
        player.seek(Duration.zero);
        player.pause();
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      } else {
        setState(() {
          _isPlaying = playing;
        });
      }
    });

    // Listen duration changes
    _durationSubscription = player.durationStream.listen((duration) {
      if (duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen position changes
    _positionSubscription = player.positionStream.listen((position) {
      setState(() {
        _position = position;
      });
    });
  }

  Future<SurahDetails> _fetchSurah() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseApiUrl}/${widget.surahNumber}.json'),
      );
      if (response.statusCode == 200) {
        return surahDetailsFromJson(response.body);
      } else {
        throw Exception('Failed to load surah details');
      }
    } catch (e) {
      log(e.toString());
      throw Exception('Failed to load surah details');
    }
  }

  @override
  void dispose() {
    _playerStateSubscription.cancel();
    _durationSubscription.cancel();
    _positionSubscription.cancel();
    player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2832),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2832),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'SURAH',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<SurahDetails>(
        future: data,
        builder: (context, asyncSnapshot) {
          if (asyncSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4A76A),
              ),
            );
          } else if (asyncSnapshot.hasError) {
            return Center(
              child: Text(
                asyncSnapshot.error.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          } else if (asyncSnapshot.hasData) {
            final surahData = asyncSnapshot.data!;
            final firstReciterAudio =
                (surahData.audio != null && surahData.audio!.isNotEmpty)
                    ? surahData.audio!.values.first
                    : null;

            return Stack(
              children: [
                // Main scroll view with padding for audio player space
                Padding(
                  padding: const EdgeInsets.only(bottom: 140),
                  child: RefreshIndicator(
                    color: const Color(0xFFD4A76A),
                    backgroundColor: const Color(0xFF2C3540),
                    onRefresh: () async {
                      setState(() {
                        data = _fetchSurah();
                      });
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Surah Header Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD4A76A), Color(0xFFE8C68A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(
                                surahData.surahName ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF2C2416),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                surahData.surahNameTranslation ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF5C4A3A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 1,
                                width: 200,
                                color: const Color(0xFF5C4A3A).withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${surahData.revelationPlace ?? ''} • ${surahData.totalAyah ?? 0} Ayat',
                                    style: const TextStyle(
                                      color: Color(0xFF5C4A3A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (surahData.surahNo != 1 && surahData.surahNo != 9) ...[
                          const SizedBox(height: 24),
                          Image.asset(
                            'assets/images/Bismillah.png',
                            height: 80,
                            color: const Color(0xFFD4A76A),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // List of Ayah
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 24),
                          itemCount: surahData.arabic1?.length ?? 0,
                          itemBuilder: (context, index) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C3540),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Verse number with icon
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD4A76A),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E2832),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.share_outlined,
                                              color: Color(0xFFD4A76A),
                                              size: 20,
                                            ),
                                            onPressed: () {},
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.play_circle_outline,
                                              color: Color(0xFFD4A76A),
                                              size: 20,
                                            ),
                                            onPressed: () {},
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.bookmark_border,
                                              color: Color(0xFFD4A76A),
                                              size: 20,
                                            ),
                                            onPressed: () {},
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Arabic verse text
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      surahData.arabic1![index],
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        height: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Divider
                                  Container(
                                    height: 1,
                                    color: const Color(0xFF3A4550),
                                  ),
                                  const SizedBox(height: 16),

                                  // English translation
                                  if (surahData.english != null &&
                                      surahData.english!.length > index)
                                    Text(
                                      surahData.english![index],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                        height: 1.6,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Sticky audio player container at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3540),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 20,
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4A76A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.headset,
                                color: Color(0xFF1E2832),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    firstReciterAudio?.reciter ?? 'No Reciter',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    surahData.surahName ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                if (firstReciterAudio?.url != null) {
                                  try {
                                    if (_isPlaying) {
                                      await player.pause();
                                    } else {
                                      if (player.processingState ==
                                          ProcessingState.idle) {
                                        await player.setUrl(
                                          firstReciterAudio!.url!,
                                        );
                                      }
                                      await player.play();
                                    }
                                  } catch (e) {
                                    log('Audio play error: $e');
                                  }
                                }
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD4A76A),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: const Color(0xFF1E2832),
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Slider and time
                        Row(
                          children: [
                            Text(
                              _formatDuration(_position),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  trackHeight: 4,
                                  activeTrackColor: const Color(0xFFD4A76A),
                                  inactiveTrackColor: const Color(0xFF3A4550),
                                  thumbColor: const Color(0xFFD4A76A),
                                  overlayColor: const Color(0xFFD4A76A).withOpacity(0.2),
                                ),
                                child: Slider(
                                  min: 0,
                                  max: _duration.inMilliseconds.toDouble(),
                                  value: _position.inMilliseconds
                                      .clamp(0, _duration.inMilliseconds)
                                      .toDouble(),
                                  onChanged: (value) async {
                                    await player.seek(
                                      Duration(milliseconds: value.toInt()),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Text(
                              _formatDuration(_duration),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: Text(
                'No data',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
        },
      ),
    );
  }
}