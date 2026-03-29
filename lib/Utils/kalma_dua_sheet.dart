import 'package:flutter/material.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:iqra/Utils/share_kalma_dua.dart';

class KDSData {
  final String title;
  final String? subtitle;
  final String arabic;
  final String translation;

  KDSData({
    required this.title,
    this.subtitle,
    required this.arabic,
    required this.translation,
  });
}

class KalmaDuaSHEET {
  static show(BuildContext context, List<KDSData> items, int initialIndex,
      String typeTitle) {
    return showModalBottomSheet<void>(
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return _KDSBottomSheetContent(
            items: items,
            initialIndex: initialIndex,
            typeTitle: typeTitle,
          );
        });
  }

  static Widget _actionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      required Color color}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _KDSBottomSheetContent extends StatefulWidget {
  final List<KDSData> items;
  final int initialIndex;
  final String typeTitle;

  const _KDSBottomSheetContent({
    required this.items,
    required this.initialIndex,
    required this.typeTitle,
  });

  @override
  State<_KDSBottomSheetContent> createState() => _KDSBottomSheetContentState();
}

class _KDSBottomSheetContentState extends State<_KDSBottomSheetContent> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<ThemeProvider>(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: bloc.selectedSecondary,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: item.subtitle == null
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: bloc.selectedTheme.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.title,
                                  // overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: bloc.selectedTheme,
                                    fontFamily: bloc.urduFontFamily,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            if (item.subtitle != null) ...[
                              const SizedBox(width: 10),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: bloc.selectedTheme.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item.subtitle!,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: bloc.urduFontFamily,
                                      fontSize: 25,
                                      color: bloc.selectedTheme,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Divider(height: 40),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                item.arabic,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: bloc.arabicFontSize - 2,
                                  fontFamily: bloc.arabicFontFamily,
                                  color: Colors.black,
                                  height: 1.8,
                                ),
                              ),
                              const SizedBox(height: 30),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                  border: Border.all(
                                      color:
                                          bloc.selectedTheme.withOpacity(0.05)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Translation",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: bloc.selectedTheme,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      item.translation,
                                      style: TextStyle(
                                        fontSize: bloc.urduFontSize - 3,
                                        fontFamily: bloc.urduFontFamily,
                                        color: Colors.black87,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            KalmaDuaSHEET._actionButton(
                              context,
                              icon: Icons.share,
                              label: "Share",
                              onTap: () {
                                KalmaDuaShare.image(
                                  context: context,
                                  bloc: bloc,
                                  title:
                                      item.subtitle == null ? "" : item.title,
                                  arabicTitle: item.subtitle ?? item.title,
                                  arabicText: item.arabic,
                                  translationText: item.translation,
                                  translatorName: "IQRA QURAN",
                                );
                              },
                              color: bloc.selectedTheme,
                            ),
                            // KalmaDuaSHEET._actionButton(
                            //   context,
                            //   icon: Icons.text_snippet_outlined,
                            //   label: "Share Text",
                            //   onTap: () {
                            //     AppShare.text(
                            //       title: item.title,
                            //       arabicText: item.arabic,
                            //       translationText: item.translation,
                            //     );
                            //   },
                            //   color: bloc.selectedTheme,
                            // ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: _currentIndex < widget.items.length - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                          );
                        }
                      : null,
                  color: bloc.selectedTheme,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.typeTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      "${_currentIndex + 1} / ${widget.items.length}",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: bloc.selectedTheme,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                _navButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  onPressed: _currentIndex > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                          );
                        }
                      : null,
                  color: bloc.selectedTheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _navButton(
      {required IconData icon,
      required VoidCallback? onPressed,
      required Color color}) {
    return Material(
      color: onPressed == null ? Colors.grey[100] : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(15),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon,
            color: onPressed == null ? Colors.grey[400] : color, size: 18),
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
