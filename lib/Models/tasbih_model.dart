import 'package:objectbox/objectbox.dart';

@Entity()
class TasbihModel {
  int id;
  String? virdh;
  int? count;
  String? date;

  TasbihModel({this.id = 0, this.virdh, this.count, this.date});
}
