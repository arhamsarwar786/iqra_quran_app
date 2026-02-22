import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final bloc = context.read<ThemeProvider>();

    return Scaffold(
      appBar: mainScreenAppBarPush(context, "About Us"),
      body: Stack(
        children: [
          bgImage(context, size),
          Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      isUrdu ? "English" : "اردو",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: bloc.selectedTheme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: isUrdu,
                      activeColor: bloc.selectedTheme,
                      onChanged: (value) {
                        setState(() {
                          isUrdu = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                                    color: Colors.black.withOpacity(0.1),
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
                        isUrdu
                            ? "السلام علیکم و رحمتہ اللہ و برکاتہ"
                            : "Assalamu Alaikum wa Rahmatullahi wa Barakatuh",
                        textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                        style: isUrdu
                            ? MyTextStyle.heading2.copyWith(
                                color: bloc.selectedTheme,
                                fontFamily: bloc.urduFontFamily,
                                fontSize: 24)
                            : MyTextStyle.heading2
                                .copyWith(color: bloc.selectedTheme),
                      ),
                      const SizedBox(height: 20),
                      _contentSection(
                        isUrdu: isUrdu,
                        bloc: bloc,
                        english:
                            "Welcome to IQRA QURAN, an Islamic mobile application designed to provide essential religious content in a structured, accessible, and easy-to-use digital format. The app is inspired by the Qur’anic command:",
                        urdu:
                            "اقراء قرآن میں خوش آمدید، ایک اسلامی موبائل ایپلی کیشن جو ضروری مذہبی مواد کو ایک منظم، قابل رسائی اور استعمال میں آسان ڈیجیٹل فارمیٹ میں فراہم کرنے کے لیے بنائی گئی ہے۔ یہ ایپلی کیشن قرآنی حکم سے متاثر ہے:",
                      ),
                      const SizedBox(height: 10),
                      _quoteSection(
                        isUrdu: isUrdu,
                        bloc: bloc,
                        englishQuote:
                            "“Read in the name of your Lord who created.”",
                        englishRef: "(Qur’an 96:1)",
                        urduQuote: "“پڑھ اپنے رب کے نام سے جس نے پیدا کیا۔”",
                        urduRef: "(القرآن 96:1)",
                      ),
                      const SizedBox(height: 15),
                      _contentSection(
                        isUrdu: isUrdu,
                        bloc: bloc,
                        english:
                            "IQRA QURAN brings together commonly used Islamic resources in one place to support daily learning, reflection, and worship. The application is carefully designed to serve users who are seeking organized Islamic content for personal reference and practice.",
                        urdu:
                            "اقراء قرآن روزانہ سیکھنے، غور و فکر اور عبادت میں مدد کے لیے عام طور پر استعمال ہونے والے اسلامی وسائل کو ایک جگہ جمع کرتا ہے۔ ایپلی کیشن کو ان صارفین کے لیے احتیاط سے ڈیزائن کیا گیا ہے جو ذاتی حوالہ اور مشق کے لیے منظم اسلامی مواد کے خواہاں ہیں۔",
                      ),
                      const SizedBox(height: 25),
                      _contentHeader(
                          isUrdu: isUrdu,
                          bloc: bloc,
                          english: "User-Friendly Interface",
                          urdu: "صارف دوست انٹرفیس"),
                      _contentSection(
                        isUrdu: isUrdu,
                        bloc: bloc,
                        english:
                            "A key focus of IQRA QURAN is its user-friendly interface. The app features a clean layout, simple navigation, and clearly labeled sections so users of all age groups can use it comfortably without technical difficulty. The design prioritizes ease of access and readability, helping users find relevant content quickly and efficiently.",
                        urdu:
                            "اقراء قرآن کی ایک اہم توجہ اس کا صارف دوست انٹرفیس ہے۔ ایپلیکیشن میں ایک صاف ستھرا ڈیزائن، سادہ نیویگیشن، اور واضح طور پر لیبل والے سیکشنز شامل ہیں تاکہ تمام عمر کے صارفین اسے تکنیکی دشواری کے بغیر آرام سے استعمال کر سکیں۔ ڈیزائن رسائی اور پڑھنے کی آسانی کو ترجیح دیتا ہے، جس سے صارفین کو متعلقہ مواد جلدی اور مؤثر طریقے سے تلاش کرنے میں مدد ملتی ہے۔",
                      ),
                      const SizedBox(height: 25),
                      _contentHeader(
                          isUrdu: isUrdu,
                          bloc: bloc,
                          english: "100% Offline Access",
                          urdu: "100% آف لائن رسائی"),
                      _contentSection(
                        isUrdu: isUrdu,
                        bloc: bloc,
                        english:
                            "IQRA QURAN works 100% offline, allowing users to access its core features without an internet connection. This makes the app practical for use while traveling or in areas with limited connectivity, reflecting the principle of ease mentioned in the Qur’an:",
                        urdu:
                            "اقراء قرآن 100% آف لائن کام کرتا ہے، جس سے صارفین انٹرنیٹ کنکشن کے بغیر اس کی بنیادی خصوصیات تک رسائی حاصل کر سکتے ہیں۔ یہ ایپ سفر کے دوران یا محدود کنیکٹیویٹی والے علاقوں میں استعمال کے لیے عملی بناتی ہے، جو قرآن میں ذکر کردہ آسانی کے اصول کی عکاسی کرتی ہے:",
                      ),
                      const SizedBox(height: 10),
                      _quoteSection(
                        isUrdu: isUrdu,
                        bloc: bloc,
                        englishQuote:
                            "“Allah intends for you ease and does not intend for you hardship.”",
                        englishRef: "(Qur’an 2:185)",
                        urduQuote:
                            "“اللہ تمہارے لیے آسانی چاہتا ہے اور تمہارے لیے سختی نہیں چاہتا۔”",
                        urduRef: "(القرآن 2:185)",
                      ),
                      const SizedBox(height: 25),
                      _contentHeader(
                          isUrdu: isUrdu,
                          bloc: bloc,
                          english: "Core Features",
                          urdu: "بنیادی خصوصیات"),
                      _contentSection(
                        isUrdu: isUrdu,
                        bloc: bloc,
                        english:
                            "The app includes Qur’an translations to assist users in understanding the meaning of the verses and reflecting upon them, as mentioned:",
                        urdu:
                            "ایپ میں قرآن کے تراجم شامل ہیں تاکہ صارفین کو آیات کے معنی سمجھنے اور ان پر غور کرنے میں مدد ملے، جیسا کہ ذکر کیا گیا ہے:",
                      ),
                      _quoteSection(
                        isUrdu: isUrdu,
                        bloc: bloc,
                        englishQuote:
                            "“This is a Book We have revealed to you so that people may reflect upon its verses.”",
                        englishRef: "(Qur’an 38:29)",
                        urduQuote:
                            "“یہ ایک ایسی کتاب ہے جو ہم نے آپ کی طرف نازل کی ہے تاکہ لوگ اس کی آیات پر غور کریں۔”",
                        urduRef: "(القرآن 38:29)",
                      ),
                      const SizedBox(height: 10),
                      _contentSection(
                        isUrdu: isUrdu,
                        bloc: bloc,
                        english:
                            "IQRA QURAN also provides the Names of Allah (Asma-ul-Husna) and the Names and attributes of Prophet Muhammad ﷺ, presented for educational and remembrance purposes, in line with:",
                        urdu:
                            "اقراء قرآن اللہ کے نام (اسماء الحسنیٰ) اور حضرت محمد ﷺ کے نام اور صفات بھی فراہم کرتا ہے، جو تعلیمی اور ذکر کے مقاصد کے لیے پیش کیے گئے ہیں، اس کے مطابق:",
                      ),
                      _quoteSection(
                        isUrdu: isUrdu,
                        bloc: bloc,
                        englishQuote:
                            "“And to Allah belong the most beautiful names, so call upon Him by them.”",
                        englishRef: "(Qur’an 7:180)",
                        urduQuote:
                            "“اور اللہ ہی کے لیے بہترین نام ہیں، پس اسے ان کے ذریعے پکارو۔”",
                        urduRef: "(القرآن 7:180)",
                      ),
                      const SizedBox(height: 10),
                      _contentSection(
                        isUrdu: isUrdu,
                        bloc: bloc,
                        english:
                            "To support daily religious routines, IQRA QURAN offers prayer time information, a structured Namaz section, a collection of daily and Masnoon Duas, and a Tasbih feature for dhikr. These tools are designed to help users stay organized and consistent in their personal practices:",
                        urdu:
                            "روزانہ کی مذہبی روٹین کو سہارا دینے کے لیے، اقراء قرآن نماز کے اوقات کی معلومات، ایک منظم نماز کا سیکشن، روزانہ اور مسنون دعاؤں کا مجموعہ، اور ذکر کے لیے تسبیح کی خصوصیت پیش کرتا ہے۔ یہ ٹولز صارفین کو ان کے ذاتی اعمال میں باقاعدگی برقرار رکھنے میں مدد دینے کے لیے بنائے گئے ہیں:",
                      ),
                      _quoteSection(
                        isUrdu: isUrdu,
                        bloc: bloc,
                        englishQuote: "“Establish prayer for My remembrance.”",
                        englishRef: "(Qur’an 20:14)",
                        urduQuote: "“میری یاد کے لیے نماز قائم کرو۔”",
                        urduRef: "(القرآن 20:14)",
                      ),
                      const SizedBox(height: 15),
                      _contentSection(
                        isUrdu: isUrdu,
                        bloc: bloc,
                        english:
                            "All content within IQRA QURAN is presented respectfully and clearly, with the intention of being informative, supportive, and easy to reference.",
                        urdu:
                            "اقراء قرآن کے اندر تمام مواد احترام اور واضح طور پر پیش کیا گیا ہے، جس کا مقصد معلوماتی، معاون اور حوالہ دینے میں آسان ہونا ہے۔",
                      ),
                      const SizedBox(height: 30),
                      Divider(color: bloc.selectedTheme.withOpacity(0.3)),
                      const SizedBox(height: 15),
                      _contentHeader(
                          isUrdu: isUrdu,
                          bloc: bloc,
                          english: "Our Mission",
                          urdu: "ہمارا مشن"),
                      _contentSection(
                        isUrdu: isUrdu,
                        bloc: bloc,
                        english:
                            "Our mission is to provide reliable Islamic content in a simple and accessible digital form, making it easier for users to engage with daily religious practices. IQRA QURAN aims to support learning, remembrance, and consistency by offering essential features in one offline-ready application with a user-friendly design.",
                        urdu:
                            "ہمارا مشن ایک سادہ اور قابل رسائی ڈیجیٹل فارمیٹ میں قابل اعتماد اسلامی مواد فراہم کرنا ہے، جس سے صارفین کے لیے روزانہ کے مذہبی اعمال کے ساتھ جڑنا آسان ہو جائے۔ اقراء قرآن صارف دوست ڈیزائن کے ساتھ ایک آف لائن ایپلی کیشن میں ضروری خصوصیات پیش کر کے سیکھنے، ذکر اور مستقل مزاجی میں مدد کرنا چاہتا ہے۔",
                      ),
                      const SizedBox(height: 25),
                      _contentHeader(
                          isUrdu: isUrdu,
                          bloc: bloc,
                          english: "Our Vision",
                          urdu: "ہمارا وژن"),
                      _contentSection(
                        isUrdu: isUrdu,
                        bloc: bloc,
                        english:
                            "Our vision is to become a trusted Islamic companion app that serves users globally by combining authenticity, simplicity, and accessibility. We aim to continuously improve IQRA QURAN by enhancing usability, expanding beneficial features, and maintaining respect for Islamic values while meeting modern app standards.",
                        urdu:
                            "ہمارا وژن ایک قابل اعتماد اسلامی ایپلی کیشن بننا ہے جو سچائی، سادگی اور رسائی کو یکجا کر کے عالمی سطح پر صارفین کی خدمت کرے۔ ہمارا مقصد استعمال میں آسانی کو بہتر بنا کر، فائدہ مند خصوصیات کو بڑھا کر، اور جدید ایپ کے معیار کو پورا کرتے ہوئے اسلامی اقدار کے احترام کو برقرار رکھتے ہوئے اقراء قرآن کو مسلسل بہتر بنانا ہے۔",
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
                              "Version 1.0.0",
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
    );
  }

  Widget _contentHeader(
      {required bool isUrdu,
      required ThemeProvider bloc,
      required String english,
      required String urdu}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        isUrdu ? urdu : english,
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
      required String english,
      required String urdu}) {
    return Text(
      isUrdu ? urdu : english,
      textAlign: isUrdu ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: isUrdu ? bloc.urduFontSize - 2 : 15,
        fontFamily: isUrdu ? bloc.urduFontFamily : null,
        height: 1.6,
        color: Colors.black.withOpacity(0.8),
      ),
    );
  }

  Widget _quoteSection(
      {required bool isUrdu,
      required ThemeProvider bloc,
      required String englishQuote,
      required String englishRef,
      required String urduQuote,
      required String urduRef}) {
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
            isUrdu ? urduQuote : englishQuote,
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
            isUrdu ? urduRef : englishRef,
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
}
