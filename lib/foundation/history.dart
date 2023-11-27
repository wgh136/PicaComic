import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/network/webdav.dart';
import 'package:sqlite3/sqlite3.dart';

enum HistoryType {
  picacg(0),
  ehentai(1),
  jmComic(2),
  hitomi(3),
  htmanga(4),
  nhentai(5);

  final int value;
  const HistoryType(this.value);
}

base class History extends LinkedListEntry<History> {
  HistoryType type;

  DateTime time;

  String title;

  String subtitle;

  String cover;

  /// 标记为0表示没有阅读位置记录
  int ep;

  int page;

  String target;

  Set<int> readEpisode;

  History(this.type, this.time, this.title, this.subtitle, this.cover, this.ep,
      this.page, this.target,
      [this.readEpisode = const <int>{}]);

  Map<String, dynamic> toMap() => {
        "type": type.value,
        "time": time.millisecondsSinceEpoch,
        "title": title,
        "subtitle": subtitle,
        "cover": cover,
        "ep": ep,
        "page": page,
        "target": target,
        "readEpisode": readEpisode.toList()
      };

  History.fromMap(Map<String, dynamic> map)
      : type = HistoryType.values[map["type"]],
        time = DateTime.fromMillisecondsSinceEpoch(map["time"]),
        title = map["title"],
        subtitle = map["subtitle"],
        cover = map["cover"],
        ep = map["ep"],
        page = map["page"],
        target = map["target"],
        readEpisode = Set<int>.from(
            (map["readEpisode"] as List<dynamic>?)?.toSet() ?? const <int>{});

  @override
  String toString() {
    return 'NewHistory{type: $type, time: $time, title: $title, subtitle: $subtitle, cover: $cover, ep: $ep, page: $page, target: $target}';
  }

  History.fromRow(Row row)
      : type = HistoryType.values[row["type"]],
        time = DateTime.fromMillisecondsSinceEpoch(row["time"]),
        title = row["title"],
        subtitle = row["subtitle"],
        cover = row["cover"],
        ep = row["ep"],
        page = row["page"],
        target = row["target"],
        readEpisode = Set<int>.from(
            (row["readEpisode"] as String).split(',').where((element) => element != "")
                .map((e) => int.parse(e)));
}

extension SQL on String{
  String get toParam => replaceAll('\'', "''").replaceAll('"', "\"\"");
}

class HistoryManager {
  static HistoryManager? cache;

  HistoryManager.create();

  factory HistoryManager() =>
      cache == null ? (cache = HistoryManager.create()) : cache!;

  List<dynamic> toJson() => getAll().map((h) => h.toMap()).toList();

  late Database _db;

  Future<void> init() async {
    _db = sqlite3.open("${App.dataPath}/history.db");
    var res = _db.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='history';");
    if (res.isEmpty) {
      var file = File("${App.dataPath}/history.json");
      _db.execute("""
        create table history (
          target text primary key,
          title text,
          subtitle text,
          cover text,
          time int,
          type int,
          ep int,
          page int,
          readEpisode text
        );
      """);
      if(file.existsSync()){
        readDataFromJson(jsonDecode(file.readAsStringSync()));
        file.deleteSync();
      }
    }
  }

  void readDataFromJson(List<dynamic> json) {
    var history = LinkedList<History>();
    for (var h in json) {
      history.add(History.fromMap((h as Map<String, dynamic>)));
    }
    clearHistory();
    for(var element in history){
      addHistory(element);
    }
  }

  void saveData() async {
    Webdav.uploadData();
  }

  Future<void> readData() async {

  }

  /// add history. if exists, update read history.
  Future<void> addHistory(History newItem) async {
    print("add");
    var res = _db.select("""
      select * from history
      where target == '${newItem.target.toParam}';
    """);
    if(res.isEmpty){
      _db.execute("""
        insert into history (target, title, subtitle, cover, time, type, ep, page, readEpisode)
        values ('${newItem.target.toParam}', '${newItem.title.toParam}', 
        '${newItem.subtitle.toParam}', '${newItem.cover.toParam}', 
        ${newItem.time.millisecondsSinceEpoch}, ${newItem.type.index}, 
        ${newItem.ep}, ${newItem.page}, '${newItem.readEpisode.join(',')}');
      """);
    } else {
      _db.execute("""
        update history
        set time = ${DateTime.now().millisecondsSinceEpoch}
        where target == '${newItem.target.toParam}';
      """);
    }
    saveData();
  }

  ///退出阅读器时调用此函数, 修改阅读位置
  Future<void> saveReadHistory(String target, int ep, int page) async {
    print("save $ep $page");
    _db.execute("""
        update history
        set time = ${DateTime.now().millisecondsSinceEpoch}, ep = $ep, page = $page
        where target == '${target.toParam}';
    """);
  }

  void clearHistory() {
    _db.execute("delete from history;");
  }

  void remove(String id) async {
    _db.execute("""
      delete from history
      where target == '$id';
    """);
  }

  Future<History?> find(String target) async {
    return findSync(target);
  }

  History? findSync(String target) {
    print("find");
    var res = _db.select("""
      select * from history
      where target == '${target.toParam}';
    """);
    if(res.isEmpty){
      return null;
    }
    return History.fromRow(res.first);
  }

  List<History> getAll(){
    var res = _db.select("""
      select * from history
      order by time DESC;
    """);
    return res.map((element) => History.fromRow(element)).toList();
  }
}
