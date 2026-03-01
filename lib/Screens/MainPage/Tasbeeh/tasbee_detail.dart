import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iqra/Provider/form_validate.dart';
import 'package:iqra/Screens/MainPage/Tasbeeh/tasbee.dart';
import 'package:iqra/Screens/MainPage/Tasbeeh/tasheeh_list_screen.dart';
import 'package:iqra/widgets.dart';
import 'package:provider/provider.dart';
import '../../../Provider/tasbih_count.dart';
import 'package:iqra/Models/tasbeeh_model.dart';
import 'package:iqra/Provider/tasbeeh_provider.dart';
import 'package:iqra/main.dart';

class TasbeeDetail extends StatefulWidget {
  const TasbeeDetail({super.key});

  @override
  State<TasbeeDetail> createState() => _TasbeeDetailState();
}

class _TasbeeDetailState extends State<TasbeeDetail> {
  var countController = TextEditingController();

  var nameController = TextEditingController();
  @override
  void dispose() {
    super.dispose();
    countController.dispose();
    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tasbihProvider = Provider.of<TasbeeCount>(context, listen: false);
    var size = MediaQuery.of(context).size;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          isExtended: true,
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TasheehListScreen()));
          }),
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
              // push(context, Home());
            },
            icon: const Icon(Icons.arrow_back_outlined)),
        title: const Text(
          "Tasbih",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Time to count tasbih",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Divider(
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                "Title Tasbih",
                style: TextStyle(),
              ),
              PhysicalModel(
                shadowColor: Colors.white,
                color: Colors.white,
                elevation: 10.0,
                borderRadius: BorderRadius.circular(10),
                child: TextField(
                  controller: nameController,
                  keyboardType: TextInputType.text,
                  cursorColor: Theme.of(context).primaryColor,
                  autofocus: false,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(left: 10),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                "Count",
                style: TextStyle(),
              ),
              PhysicalModel(
                shadowColor: Colors.white,
                color: Colors.white,
                elevation: 10.0,
                borderRadius: BorderRadius.circular(10),
                child: Consumer<FormValidate>(builder: (context, value, child) {
                  return TextField(
                    controller: countController,
                    keyboardType: TextInputType.number,
                    cursorColor: Theme.of(context).primaryColor,
                    autofocus: false,
                    decoration: InputDecoration(
                      errorText: value.validateValue == true
                          ? "Enter correct value"
                          : null,
                      contentPadding: const EdgeInsets.only(left: 10.0),
                      fillColor: Colors.white,
                      filled: true,
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                height: 50,
                child: Align(
                  alignment: Alignment.center,
                  child:
                      Consumer<FormValidate>(builder: (context, value, child) {
                    return CupertinoButton(
                      minSize: size.width,
                      color: Theme.of(context).primaryColor,
                      onPressed: () {
                        if (nameController.text.isEmpty ||
                            countController.text.isEmpty) {
                          value.checkValidate(true);
                        } else {
                          value.checkValidate(false);

                          var tasbeehProv = context.read<TasbeehProvider>();
                          var tasbihCountProv = context.read<TasbeeCount>();

                          // Check if we are opening an existing custom one by title
                          var previous = objectbox
                              .getTodayTasbih(nameController.text.trim());

                          // Convert to TasbeehModel (Session runner struct)
                          TasbeehModel customTasbeeh = TasbeehModel(
                            arabic: nameController.text.trim(),
                            urduMeaning: "Custom Tasbeeh",
                          );

                          tasbeehProv.setSelectedTasbeeh(customTasbeeh);

                          // Set starting count for the session
                          int requestedCount =
                              int.tryParse(countController.text) ?? 0;

                          if (previous != null && requestedCount == 0) {
                            tasbihCountProv.setValue(previous.count ?? 0);
                          } else {
                            tasbihCountProv.setValue(requestedCount);
                          }

                          push(
                            context,
                            Tasbih(),
                          );
                        }
                      },
                      child: const Text(
                        "Start",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
