import 'package:objectbox/objectbox.dart';
import '../Models/tasbih_model.dart';
import '../objectbox.g.dart';


class ObjectBox{
late final Store _store;
late final Box<TasbihModel> _tasbihBox;
  ObjectBox._init(_store){
    _tasbihBox= Box<TasbihModel>(_store); 
  }
  static Future<ObjectBox> init()async{
    final open =await openStore();
    return ObjectBox._init(open);
  }
  TasbihModel? getUset(int id)=>_tasbihBox.get(id);
  Stream<List<TasbihModel>> getUsers()=>   _tasbihBox.query().watch(triggerImmediately: true).map((query) => query.find() );
   
  
   insertUser( data){
       _tasbihBox.put(data);}
    
    bool deletetUser( int id)=>
       _tasbihBox.remove(id);
     void  closedStore()=>
         _store.close();
       
    
}