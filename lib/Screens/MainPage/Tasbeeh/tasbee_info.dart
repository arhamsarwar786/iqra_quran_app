import 'package:flutter/material.dart';
import 'package:iqra/Provider/tasbih_count.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Tasbeeh/tasbee.dart';
import 'package:iqra/Utils/utils.dart';
import 'package:iqra/widgets.dart';
import 'package:provider/provider.dart';
import 'package:iqra/Provider/tasbeeh_provider.dart';
import 'package:iqra/Models/tasbeeh_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Models/tasbih_model.dart';
import '../../../main.dart';

class TasbihInfo extends StatefulWidget {
  const TasbihInfo({super.key});

  @override
  State<TasbihInfo> createState() => _TasbihInfoState();
}

class _TasbihInfoState extends State<TasbihInfo> {
  late Stream<List<TasbihModel>> streamUsers;
  SharedPreferences? _prefs;
  DateTime? _selectedDate = DateTime.now(); // default to Today

  @override
  void initState() {
    super.initState();
    streamUsers = objectbox.getUsers();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    objectbox.closedStore();
  }

  bool _isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDateFilter(DateTime? date, {bool isCustom = false}) {
    if (date == null) return "All";

    if (isCustom) {
      return "${date.day}/${date.month}";
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showDeleteDialog(
      int userId, String virdhName, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Delete Tasbeeh"),
          content: Text(
              "Are you sure you want to permanently delete your progress for:\n\n$virdhName?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.selectedTheme),
              onPressed: () {
                objectbox.deletetUser(userId);
                Navigator.pop(dialogContext);
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(
                //       content: Text('Tasbeeh deleted'),
                //       backgroundColor: Colors.redAccent),
                // );
              },
              child:
                  const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var tasbihProvider = Provider.of<TasbeeCount>(context, listen: false);
    final themeProvider = context.read<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              // Navigator.of(context).push(MaterialPageRoute(builder: (contex){
              // return TasbeeDetail();
              // }));
              pop(context);
            },
            icon: const Icon(Icons.arrow_back_outlined)),
        title: const Text(
          "Saved Tasbeeh",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: _prefs == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<List<TasbihModel>>(
                stream: streamUsers,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final users = snapshot.data!;

                  // 1. Process users with dates and sort them
                  List<Map<String, dynamic>> processedUsers = [];
                  for (var user in users) {
                    DateTime recordDate =
                        DateTime.fromMillisecondsSinceEpoch(0);

                    if (user.date != null && user.date!.isNotEmpty) {
                      try {
                        recordDate = DateTime.parse(user.date!);
                      } catch (e) {}
                    } else {
                      String dateString =
                          _prefs!.getString('tasbeeh_date_${user.virdh}') ?? "";
                      if (dateString.isNotEmpty) {
                        try {
                          recordDate = DateTime.parse(dateString);
                        } catch (e) {}
                      }
                    }

                    processedUsers.add({
                      'user': user,
                      'date': recordDate,
                    });
                  }

                  // Sort descending by date
                  processedUsers.sort((a, b) =>
                      (b['date'] as DateTime).compareTo(a['date'] as DateTime));

                  // 2. Generate weekly dates for filter ribbon
                  List<DateTime?> filterOptions = [
                    null
                  ]; // null represents "All"
                  DateTime now = DateTime.now();
                  int currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
                  DateTime startOfWeek =
                      now.subtract(Duration(days: currentWeekday - 1));
                  for (int i = 0; i < 7; i++) {
                    filterOptions.add(startOfWeek.add(Duration(days: i)));
                  }

                  bool selectedDateIsCustom = false;
                  if (_selectedDate != null &&
                      !filterOptions.any((d) => _isSameDay(d, _selectedDate))) {
                    filterOptions.insert(1, _selectedDate);
                    selectedDateIsCustom = true;
                  }

                  // 3. Filter users by currently selected date
                  List<Map<String, dynamic>> filteredUsers = processedUsers;
                  if (_selectedDate != null) {
                    filteredUsers = processedUsers.where((item) {
                      return _isSameDay(item['date'], _selectedDate);
                    }).toList();
                  }

                  return Column(
                    children: [
                      // Dates Scroller Ribbon
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => _selectDate(context),
                              icon: Icon(Icons.calendar_month,
                                  color: themeProvider.selectedTheme),
                            ),
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 0),
                                itemCount: filterOptions.length,
                                itemBuilder: (context, index) {
                                  DateTime? filterDate = filterOptions[index];
                                  bool isSelected = (_selectedDate == null &&
                                          filterDate == null) ||
                                      (_isSameDay(_selectedDate, filterDate));
                                  bool isCustom = selectedDateIsCustom &&
                                      index == 1 &&
                                      filterDate != null;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: ChoiceChip(
                                      label: Text(_formatDateFilter(filterDate,
                                          isCustom: isCustom)),
                                      selected: isSelected,
                                      onSelected: (bool selected) {
                                        setState(() {
                                          _selectedDate = filterDate;
                                        });
                                      },
                                      selectedColor:
                                          themeProvider.selectedTheme,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      backgroundColor: Colors.grey.shade200,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide.none,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1, thickness: 1),

                      // Users List
                      Expanded(
                        child: filteredUsers.isEmpty
                            ? const Center(
                                child: Text("No Tasbeeh for this selection",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey)))
                            : ListView.builder(
                                itemCount: filteredUsers.length,
                                itemBuilder: ((context, index) {
                                  final userMap = filteredUsers[index];
                                  final TasbihModel user = userMap['user'];
                                  final DateTime dt = userMap['date'];

                                  String formattedDate = "Recently Saved";
                                  if (dt.year > 2000) {
                                    formattedDate =
                                        "Last updated: ${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0, vertical: 10.0),
                                    child: InkWell(
                                      onTap: () {
                                        tasbihProvider
                                            .setValue(user.count ?? 0);
                                        var tasbeehToLoad = TasbeehModel(
                                            arabic: user.virdh,
                                            transliteration: '',
                                            urduMeaning: '');
                                        context
                                            .read<TasbeehProvider>()
                                            .setSelectedTasbeeh(tasbeehToLoad);
                                        push(context, Tasbih());
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(15.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.2),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: const Offset(0,
                                                  3), // changes position of shadow
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      user.virdh.toString(),
                                                      textDirection:
                                                          TextDirection.rtl,
                                                      style: TextStyle(
                                                        fontFamily: themeProvider
                                                            .arabicFontFamily,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 22,
                                                        color: themeProvider
                                                            .selectedTheme,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      _showDeleteDialog(
                                                          user.id,
                                                          user.virdh.toString(),
                                                          themeProvider);
                                                    },
                                                    icon: const Icon(
                                                        Icons.delete_outline),
                                                    color: Colors.redAccent,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: themeProvider
                                                          .selectedTheme
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Text(
                                                      "Count: ${user.count}",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: themeProvider
                                                            .selectedTheme,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    formattedDate,
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                      ),
                    ],
                  );
                }),
      ),
    );
  }
}
