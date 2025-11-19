import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quran_myapp/core/config.dart';
import 'package:quran_myapp/models/surahs.dart';
import 'package:quran_myapp/screen/surah_details_screen.dart';
import 'package:quran_myapp/widgets/quran_title.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Surahs>> data;

  Future<List<Surahs>> _fetchChapters() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseApiUrl}/surah.json'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        final List<Surahs> chapters = json.map((e) => Surahs.fromJson(e)).toList();
        return chapters;
      } else {
        throw Exception('Failed to load chapters');
      }
    } catch (e) {
      log(e.toString());
      throw Exception('Failed to load chapters');
    }
  }

  @override
  void initState() {
    super.initState();
    data = _fetchChapters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2832), // Dark background
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
          'QUR\'AN',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            try {
              final newData = await _fetchChapters();
              setState(() {
                data = Future.value(newData);
              });
            } catch (e) {
              print('Error saat refresh data: $e');
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Last Read Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4A76A), Color(0xFFE8C68A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.menu_book_rounded, color: Color(0xFF5C4A3A), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Last Read',
                              style: TextStyle(
                                color: Color(0xFF5C4A3A),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Surah',
                          style: TextStyle(
                            color: Color(0xFF5C4A3A),
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          'Al - Fatihah',
                          style: TextStyle(
                            color: Color(0xFF2C2416),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2416),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Back to reading',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Image.asset(
                      'assets/images/urr.png',
                      height: 110,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tab Bar
              DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    TabBar(
                      indicatorColor: const Color(0xFFD4A76A),
                      labelColor: const Color(0xFFD4A76A),
                      unselectedLabelColor: Colors.white54,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'Surah'),
                        Tab(text: 'Para'),
                        Tab(text: 'Page'),
                        Tab(text: 'Hijb'),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Surah List
              FutureBuilder<List<Surahs>>(
                future: data,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD4A76A),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  } else if (snapshot.hasData) {
                    return ListView.separated(
                      separatorBuilder: (context, index) {
                        return const Divider(
                          height: 1,
                          color: Color(0xFF2C3540),
                        );
                      },
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final Surahs surah = snapshot.data![index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              SurahDetailsScreen.routeName,
                              arguments: index + 1,
                            );
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C3540),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: const Color(0xFFD4A76A).withOpacity(0.3),
                                    size: 35,
                                  ),
                                  Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          title: Text(
                            surah.surahName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${surah.revelationPlace!} - ${surah.totalAyah} Ayat',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                surah.surahNameArabic!,
                                style: const TextStyle(
                                  color: Color(0xFFD4A76A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD4A76A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Color(0xFF1E2832),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}