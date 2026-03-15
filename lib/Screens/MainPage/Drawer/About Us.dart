import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../Provider/theme_provider.dart';
import '../../../widgets.dart';
import '../../../Utils/customThemes.dart';

class Aboutus extends StatefulWidget {
  const Aboutus({Key? key}) : super(key: key);

  @override
  State<Aboutus> createState() => _AboutusState();
}

class _AboutusState extends State<Aboutus> {
  bool isUrdu = false;
  Map<String, dynamic>? aboutData;
  bool isLoading = true;
  String _version = "";

  @override
  void initState() {
    super.initState();
    loadAboutData();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = "${packageInfo.version}+${packageInfo.buildNumber}";
    });
  }

  Future<void> loadAboutData() async {
    try {
      final String response =
          await rootBundle.loadString('assets/json_data/about_us.json');
      final data = await json.decode(response);
      setState(() {
        aboutData = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading JSON: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final bloc = context.read<ThemeProvider>();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
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
            color: Theme.of(context).primaryColor,
            icon: const Icon(Icons.arrow_back),
          ),
          centerTitle: true,
          title: Text(
            "About Us",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).primaryColor,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: Center(child: _customLanguageSwitch(bloc)),
            ),
          ],
        ),
        body: Stack(
          children: [
            bgImage(context, size),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : aboutData == null
                    ? const Center(child: Text("Error loading content"))
                    : Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: Column(
                                crossAxisAlignment: isUrdu
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Hero(
                                      tag: 'app_logo',
                                      child: Consumer<ThemeProvider>(
                                          builder: (context, provider, child) {
                                        return Container(
                                          padding: const EdgeInsets.all(15),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: Image.asset(
                                            "assets/images/iqra${provider.iconNumber}.png",
                                            height: 100,
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  Text(
                                    aboutData!['greeting']
                                        [isUrdu ? 'ur' : 'en'],
                                    textAlign: isUrdu
                                        ? TextAlign.right
                                        : TextAlign.left,
                                    style: isUrdu
                                        ? MyTextStyle.heading2.copyWith(
                                            color: bloc.selectedTheme,
                                            fontFamily: bloc.urduFontFamily,
                                            fontSize: 24)
                                        : MyTextStyle.heading2.copyWith(
                                            color: bloc.selectedTheme),
                                  ),
                                  const SizedBox(height: 20),
                                  _contentSection(
                                    isUrdu: isUrdu,
                                    bloc: bloc,
                                    text: aboutData!['intro']
                                        [isUrdu ? 'ur' : 'en'],
                                  ),
                                  const SizedBox(height: 10),
                                  _quoteSection(
                                    isUrdu: isUrdu,
                                    bloc: bloc,
                                    quote: aboutData!['quotes'][0]
                                        [isUrdu ? 'ur' : 'en'],
                                    ref: aboutData!['quotes'][0]
                                        [isUrdu ? 'ref_ur' : 'ref_en'],
                                  ),
                                  const SizedBox(height: 15),
                                  _contentSection(
                                    isUrdu: isUrdu,
                                    bloc: bloc,
                                    text: aboutData!['general_content']
                                        [isUrdu ? 'ur' : 'en'],
                                  ),
                                  const SizedBox(height: 25),
                                  _contentHeader(
                                      isUrdu: isUrdu,
                                      bloc: bloc,
                                      header: aboutData!['sections'][0]
                                          [isUrdu ? 'title_ur' : 'title_en']),
                                  _contentSection(
                                    isUrdu: isUrdu,
                                    bloc: bloc,
                                    text: aboutData!['sections'][0]
                                        [isUrdu ? 'content_ur' : 'content_en'],
                                  ),
                                  const SizedBox(height: 25),
                                  _contentHeader(
                                      isUrdu: isUrdu,
                                      bloc: bloc,
                                      header: aboutData!['sections'][1]
                                          [isUrdu ? 'title_ur' : 'title_en']),
                                  _contentSection(
                                    isUrdu: isUrdu,
                                    bloc: bloc,
                                    text: aboutData!['sections'][1]
                                        [isUrdu ? 'content_ur' : 'content_en'],
                                  ),
                                  const SizedBox(height: 10),
                                  _quoteSection(
                                    isUrdu: isUrdu,
                                    bloc: bloc,
                                    quote: aboutData!['quotes'][1]
                                        [isUrdu ? 'ur' : 'en'],
                                    ref: aboutData!['quotes'][1]
                                        [isUrdu ? 'ref_ur' : 'ref_en'],
                                  ),
                                  const SizedBox(height: 25),
                                  _contentHeader(
                                      isUrdu: isUrdu,
                                      bloc: bloc,
                                      header: aboutData!['sections'][2]
                                          [isUrdu ? 'title_ur' : 'title_en']),
                                  _contentSection(
                                    isUrdu: isUrdu,
                                    bloc: bloc,
                                    text: aboutData!['sections'][2][isUrdu
                                        ? 'content_1_ur'
                                        : 'content_1_en'],
                                  ),
                                  _quoteSection(
                                    isUrdu: isUrdu,
                                    bloc: bloc,
                                    quote: aboutData!['quotes'][2]
                                        [isUrdu ? 'ur' : 'en'],
                                    ref: aboutData!['quotes'][2]
                                        [isUrdu ? 'ref_ur' : 'ref_en'],
                                  ),
                                  const SizedBox(height: 10),
                                  _contentSection(
                                    isUrdu: isUrdu,
                                    bloc: bloc,
                                    text: aboutData!['sections'][2][isUrdu
                                        ? 'content_2_ur'
                                        : 'content_2_en'],
                                  ),
                                  _quoteSection(
                                    isUrdu: isUrdu,
                                    bloc: bloc,
                                    quote: aboutData!['quotes'][3]
                                        [isUrdu ? 'ur' : 'en'],
                                    ref: aboutData!['quotes'][3]
                                        [isUrdu ? 'ref_ur' : 'ref_en'],
                                  ),
                                  const SizedBox(height: 10),
                                  _contentSection(
                                    isUrdu: isUrdu,
                                    bloc: bloc,
                                    text: aboutData!['sections'][2][isUrdu
                                        ? 'content_3_ur'
                                        : 'content_3_en'],
                                  ),
                                  _quoteSection(
                                    isUrdu: isUrdu,
                                    bloc: bloc,
                                    quote: aboutData!['quotes'][4]
                                        [isUrdu ? 'ur' : 'en'],
                                    ref: aboutData!['quotes'][4]
                                        [isUrdu ? 'ref_ur' : 'ref_en'],
                                  ),
                                  const SizedBox(height: 15),
                                  _contentSection(
                                    isUrdu: isUrdu,
                                    bloc: bloc,
                                    text: aboutData!['footer']
                                        [isUrdu ? 'ur' : 'en'],
                                  ),
                                  const SizedBox(height: 30),
                                  Divider(
                                      color:
                                          bloc.selectedTheme.withOpacity(0.3)),
                                  const SizedBox(height: 15),
                                  _contentHeader(
                                      isUrdu: isUrdu,
                                      bloc: bloc,
                                      header: aboutData!['mission']
                                          [isUrdu ? 'title_ur' : 'title_en']),
                                  _contentSection(
                                    isUrdu: isUrdu,
                                    bloc: bloc,
                                    text: aboutData!['mission']
                                        [isUrdu ? 'content_ur' : 'content_en'],
                                  ),
                                  const SizedBox(height: 25),
                                  _contentHeader(
                                      isUrdu: isUrdu,
                                      bloc: bloc,
                                      header: aboutData!['vision']
                                          [isUrdu ? 'title_ur' : 'title_en']),
                                  _contentSection(
                                    isUrdu: isUrdu,
                                    bloc: bloc,
                                    text: aboutData!['vision']
                                        [isUrdu ? 'content_ur' : 'content_en'],
                                  ),
                                  const SizedBox(height: 40),
                                  // Social Media Section
                                  Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          isUrdu
                                              ? "ہم سے جڑیں"
                                              : "Connect With Us",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: bloc.selectedTheme,
                                            fontFamily: isUrdu
                                                ? bloc.urduFontFamily
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Wrap(
                                          spacing: 20,
                                          runSpacing: 20,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            _socialIcon(
                                              icon: FontAwesomeIcons.youtube,
                                              color: const Color(0xFFFF0000),
                                              url:
                                                  "https://www.youtube.com/channel/UCLbonUX0SC9KU7bXx0wqCSQ",
                                            ),
                                            _socialIcon(
                                              icon: FontAwesomeIcons.facebook,
                                              color: const Color(0xFF1877F2),
                                              url:
                                                  "https://www.facebook.com/THEIQRAQURANOFFICIAL/",
                                            ),
                                            _socialIcon(
                                              icon: FontAwesomeIcons.instagram,
                                              color: const Color(0xFFE4405F),
                                              url:
                                                  "https://www.instagram.com/theiqraquranofficial/",
                                            ),
                                            _socialIcon(
                                              icon: FontAwesomeIcons.whatsapp,
                                              color: const Color(0xFF25D366),
                                              url:
                                                  "https://whatsapp.com/channel/0029Vb6rYwPEKyZH8LlJqm2l",
                                            ),
                                            _socialIcon(
                                              icon: FontAwesomeIcons.twitter,
                                              color: Colors.black,
                                              url: "https://x.com/IqraThe91544",
                                            ),
                                            _socialIcon(
                                              icon: FontAwesomeIcons.tiktok,
                                              color: Colors.black,
                                              url:
                                                  "https://www.tiktok.com/@theiqraquranofficial",
                                            ),
                                            _socialIcon(
                                              icon: FontAwesomeIcons.globe,
                                              color: bloc.selectedTheme,
                                              url: "https://www.theiqraquran.com/",
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 30),
                                        // Website Button
                                        ElevatedButton.icon(
                                          onPressed: () => _launchURL(
                                              "https://www.theiqraquran.com/"),
                                          icon: const Icon(
                                              FontAwesomeIcons.globe,
                                              size: 18),
                                          label: Text(
                                            isUrdu
                                                ? "ہماری ویب سائٹ دیکھیں"
                                                : "Visit Our Website",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: isUrdu
                                                  ? bloc.urduFontFamily
                                                  : null,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: bloc.selectedTheme,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 30, vertical: 15),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            elevation: 8,
                                            shadowColor: bloc.selectedTheme
                                                .withOpacity(0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 50),
                                  Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          "IQRA QURAN",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: bloc.selectedTheme,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Version $_version",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
          ],
        ),
      ),
    );
  }

  Widget _customLanguageSwitch(ThemeProvider bloc) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isUrdu = !isUrdu;
        });
      },
      child: Container(
        width: 76,
        height: 34,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "EN",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "UR",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              alignment: isUrdu ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 36,
                height: 30,
                decoration: BoxDecoration(
                  color: bloc.selectedTheme,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: bloc.selectedTheme.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isUrdu ? "UR" : "EN",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentHeader(
      {required bool isUrdu,
      required ThemeProvider bloc,
      required String header}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        header,
        style: isUrdu
            ? MyTextStyle.heading2.copyWith(
                color: bloc.selectedTheme,
                fontFamily: bloc.urduFontFamily,
                fontSize: 20)
            : MyTextStyle.heading2
                .copyWith(color: bloc.selectedTheme, fontSize: 18),
      ),
    );
  }

  Widget _contentSection(
      {required bool isUrdu,
      required ThemeProvider bloc,
      required String text}) {
    return Text(
      text,
      textAlign: isUrdu ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: isUrdu ? bloc.urduFontSize - 2 : 15,
        fontFamily: isUrdu ? bloc.urduFontFamily : null,
        height: 1.6,
        color: Colors.black.withOpacity(0.8),
      ),
    );
  }

  Widget _quoteSection({
    required bool isUrdu,
    required ThemeProvider bloc,
    required String quote,
    required String ref,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bloc.selectedTheme.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: isUrdu
              ? BorderSide.none
              : BorderSide(color: bloc.selectedTheme, width: 5),
          right: isUrdu
              ? BorderSide(color: bloc.selectedTheme, width: 5)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            quote,
            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: isUrdu ? bloc.urduFontSize : 16,
              fontWeight: FontWeight.bold,
              fontStyle: isUrdu ? FontStyle.normal : FontStyle.italic,
              fontFamily: isUrdu ? bloc.urduFontFamily : null,
              color: bloc.selectedTheme,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ref,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: bloc.selectedTheme.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialIcon({
    required IconData icon,
    required Color color,
    required String url,
  }) {
    return GestureDetector(
      onTap: () => _launchURL(url),
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1), width: 1.5),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      // Using launchUrl directly as canLaunchUrl often returns false
      // on newer Android versions without complex manifest queries.
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }
}
