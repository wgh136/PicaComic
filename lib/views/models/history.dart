import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import '../../network/hitomi_network/hitomi_models.dart';
import '../../network/jm_network/jm_models.dart';

/*
为了能够存储eh历史记录, 弃用此类, 重构历史记录功能
class HistoryItem{
  String id;
  String title;
  String author;
  String cover;
  DateTime time;
  int ep;
  int page;
  HistoryItem(this.id,this.title,this.author,this.cover,this.time,this.ep,this.page);

  HistoryItem.fromMap(Map<String, dynamic> map):
      id=map["id"],
      title=map["title"],
      author=map["author"],
      cover=map["cover"],
      time=DateTime.fromMillisecondsSinceEpoch(map["time"]),
      ep=map["ep"],
      page=map["page"];

  Map<String,dynamic> toMap()=>{
    "id": id,
    "title": title,
    "author": author,
    "cover": cover,
    "time": time.millisecondsSinceEpoch,
    "ep": ep,
    "page": page
  };

  @override
  String toString()=>"$id $title $author $time $ep $page";
}
 */
enum HistoryType{
  picacg(0),
  ehentai(1),
  jmComic(2),
  hitomi(3);

  final int value;
  const HistoryType(this.value);
}

class NewHistory extends LinkedListEntry<NewHistory>{
  HistoryType type;
  DateTime time;
  String title;
  String subtitle;  //picacg中为作者, eh中为上传者
  String cover;
  int ep; //标记为0表示没有阅读位置记录
  int page;
  String target;  //picacg中为本子id, eh中为本子链接
  NewHistory(this.type,this.time,this.title,this.subtitle,this.cover,this.ep,this.page,this.target);

  NewHistory.fromComicItemBrief(ComicItemBrief brief, this.time, this.ep, this.page):
    type=HistoryType.picacg,
    title=brief.title,
    subtitle=brief.author,
    cover=brief.path,
    target=brief.id;

  NewHistory.fromGalleryBrief(EhGalleryBrief brief, this.time, this.ep, this.page):
    type=HistoryType.ehentai,
    title=brief.title,
    subtitle=brief.uploader,
    cover=brief.coverPath,
    target=brief.link;

  NewHistory.fromJmComicBrief(JmComicBrief brief, this.time, this.ep, this.page):
     type=HistoryType.jmComic,
     title=brief.name,
     subtitle=brief.author,
     cover="",
     target=brief.id;

  NewHistory.fromHitomiComic(HitomiComic comic, this.cover, this.time, this.ep, this.page):
      type = HistoryType.hitomi,
      title = comic.name,
      subtitle = (comic.artists??[]).isEmpty?"":comic.artists![0],
      target = comic.id;

  Map<String, dynamic> toMap()=>{
    "type": type.value,
    "time": time.millisecondsSinceEpoch,
    "title": title,
    "subtitle": subtitle,
    "cover": cover,
    "ep": ep,
    "page": page,
    "target": target
  };

  NewHistory.fromMap(Map<String, dynamic> map):
    type=HistoryType.values[map["type"]],
    time=DateTime.fromMillisecondsSinceEpoch(map["time"]),
    title=map["title"],
    subtitle=map["subtitle"],
    cover=map["cover"],
    ep=map["ep"],
    page=map["page"],
    target=map["target"];

  @override
  String toString() {
    return 'NewHistory{type: $type, time: $time, title: $title, subtitle: $subtitle, cover: $cover, ep: $ep, page: $page, target: $target}';
  }
}

class HistoryManager{
  //粗略计算, 1000个本子的数据将占据1.38mb左右的内存空间(按照int64位,char8位计算), 显然难以接受, 应该不会有人历史记录超过10000吧?这样硬盘IO的速度可以接受
  //也没必要整数据库, 遍历一遍用时不高(除非历史记录多得离谱)
  //如果因为历史记录过多导致卡顿, 我的建议是注意身体, 卡顿可以帮助戒色

  static HistoryManager? cache;

  HistoryManager.create();

  factory HistoryManager() => cache==null?(cache=HistoryManager.create()):cache!;

  var history = LinkedList<NewHistory>();
  bool _open = false;

  void saveDataAndClose() async{
    //储存数据并且释放内存
    final dataPath = await getApplicationSupportDirectory();
    var file = File("${dataPath.path}${Platform.pathSeparator}history.json");
    if(!(await file.exists())){
      await file.create();
    }
    file.writeAsStringSync(const JsonEncoder().convert(history.map((h)=>h.toMap()).toList()));
    //_open = false;
    //history.clear();
  }

  void close() async{
    saveDataAndClose();
  }

  Future<void> readData() async{
    if(_open) return;
    _open = true;
    final dataPath = await getApplicationSupportDirectory();
    var file = File("${dataPath.path}${Platform.pathSeparator}history.json");
    if(!(await file.exists())){
      return;
    }
    var data = const JsonDecoder().convert(file.readAsStringSync());
    for(var h in data){
      history.add(NewHistory.fromMap((h as Map<String, dynamic>)));
    }
  }

  ///搜索是否存在, 存在则移至最前, 并且转移历史记录
  ///调用此方法不会记录阅读数据, 只是添加历史记录
  Future<void> addHistory(NewHistory newItem) async{
    if(!_open) {
      await readData();
    }
    try {
      var p = history.firstWhere((element) => element.target == newItem.target);
      newItem.page = p.page;
      newItem.ep = p.ep;
      history.remove(p);
      history.addFirst(NewHistory.fromMap(newItem.toMap()));//不知道这里直接传递是复制还是引用, 总之这样写直接消灭问题
    }
    catch(e){
      //没有之前的历史记录
      history.addFirst(NewHistory.fromMap(newItem.toMap()));
      //做一个限制, 避免极端情况
      if(history.length >= 10000){
        history.remove(history.last);
      }
    }
    finally{
      saveDataAndClose();
    }
  }

  ///退出阅读器时调用此函数, 修改阅读位置
  Future<void> saveReadHistory(String target, int ep, int page) async{
    if(!_open) {
      await readData();
    }
    try {
      var p = history.firstWhere((element) => element.target == target);
      p.ep = ep;
      p.page = page;
      saveDataAndClose();
    }
    catch(e){
      //可能存在进入阅读器前添加历史记录失败情况, 此时忽略
    }
  }

  void clearHistory() async{
    //清除历史记录
    final dataPath = await getApplicationSupportDirectory();
    var file = File("${dataPath.path}${Platform.pathSeparator}history.json");
    if(file.existsSync()){
      await file.delete();
    }
  }

  void remove(String id) async{
    await readData();
    history.remove(history.firstWhere((element) => element.target==id));
  }

  Future<NewHistory?> find(String target) async{
    if(!_open) {
      await readData();
    }
    try {
      return history.firstWhere((element) => element.target == target);
    }
    catch(e){
      return null;
    }
  }
}