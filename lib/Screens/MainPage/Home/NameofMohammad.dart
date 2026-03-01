import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../Models/name_of_muhammad_model.dart';
import '../../../Provider/theme_provider.dart';

class NameofMohammad extends StatefulWidget {
  const NameofMohammad({Key? key}) : super(key: key);

  @override
  State<NameofMohammad> createState() => _NameofMohammadState();
}

class _NameofMohammadState extends State<NameofMohammad> {
  List<NameOfMuhammadModel> namesOfMuhammad = [];
  bool isLoading = true;
  final CardSwiperController controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    loadNames();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> loadNames() async {
    try {
      final String response =
          await rootBundle.loadString('assets/json_data/name_of_Muh.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        namesOfMuhammad =
            data.map((json) => NameOfMuhammadModel.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading names: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    var bloc = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: appBar(bloc),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: bloc.selectedTheme,
                ),
              )
            : Container(
                height: size.height,
                width: size.width,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/BgImage.png"),
                    fit: BoxFit.cover,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bloc.selectedSecondary,
                      Colors.white,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: CardSwiper(
                          controller: controller,
                          cardsCount: namesOfMuhammad.length,
                          isLoop: true,
                          numberOfCardsDisplayed: 2,
                          backCardOffset: const Offset(0, 40),
                          padding: const EdgeInsets.all(24.0),
                          duration: const Duration(milliseconds: 300),
                          cardBuilder: (context,
                              index,
                              horizontalThresholdPercentage,
                              verticalThresholdPercentage) {
                            return buildNameCard(
                                namesOfMuhammad[index], size, bloc);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => controller.undo(),
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              size: 40,
                              color: bloc.selectedTheme,
                            ),
                          ),
                          const SizedBox(width: 40),
                          IconButton(
                            onPressed: () =>
                                controller.swipe(CardSwiperDirection.right),
                            icon: Icon(
                              Icons.arrow_forward_rounded,
                              size: 40,
                              color: bloc.selectedTheme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  AppBar appBar(ThemeProvider bloc) {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/BgImage.png"),
            fit: BoxFit.cover,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        iconSize: 20,
        color: bloc.selectedTheme,
        icon: const Icon(Icons.arrow_back),
      ),
      centerTitle: true,
      title: Text(
        "NAMES OF MUHAMMAD (PBUH)",
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: bloc.selectedTheme,
        ),
      ),
    );
  }

  Widget buildNameCard(
      NameOfMuhammadModel name, Size size, ThemeProvider bloc) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bloc.selectedTheme,
              bloc.selectedTheme.withOpacity(0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative corners
            // Positioned(
            //   top: 0,
            //   right: 0,
            //   child: Container(
            //     height: 60,
            //     width: 60,
            //     decoration: const BoxDecoration(
            //       image: DecorationImage(
            //         image: AssetImage("assets/images/cornertop.png"),
            //         fit: BoxFit.fill,
            //       ),
            //     ),
            //   ),
            // ),
            // Positioned(
            //   bottom: 0,
            //   left: 0,
            //   child: Container(
            //     height: 60,
            //     width: 60,
            //     decoration: const BoxDecoration(
            //       image: DecorationImage(
            //         image: AssetImage("assets/images/cornerbottom.png"),
            //         fit: BoxFit.fill,
            //       ),
            //     ),
            //   ),
            // ),
            // Content
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Number badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${name.no}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: bloc.selectedTheme,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Arabic name
                    Text(
                      name.nameArabic,
                      style: TextStyle(
                        fontSize: 70,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: bloc.arabicFontFamily,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Transliteration
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        name.transliteration,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Divider
                    Container(
                      height: 2,
                      width: size.width * 0.5,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    // English meaning
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        name.meaningEnglish,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Urdu meaning
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        name.meaningUrdu,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: bloc.urduFontFamily,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
