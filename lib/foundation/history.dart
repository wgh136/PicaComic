import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/network/webdav.dart';
import 'package:sqlite3/sqlite3.dart';

part "image_favorites.dart";

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

  int? maxPage;

  History(this.type, this.time, this.title, this.subtitle, this.cover, this.ep,
      this.page, this.target,
      [this.readEpisode = const <int>{}, this.maxPage]);

  Map<String, dynamic> toMap() => {
        "type": type.value,
        "time": time.millisecondsSinceEpoch,
        "title": title,
        "subtitle": subtitle,
        "cover": cover,
        "ep": ep,
        "page": page,
        "target": target,
        "readEpisode": readEpisode.toList(),
        "max_page": maxPage
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
            (map["readEpisode"] as List<dynamic>?)?.toSet() ?? const <int>{}),
        maxPage = map["max_page"];

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
                .map((e) => int.parse(e))),
        maxPage = row["max_page"];
}

class HistoryManager {
  static HistoryManager? cache;

  HistoryManager.create();

  factory HistoryManager() =>
      cache == null ? (cache = HistoryManager.create()) : cache!;

  List<dynamic> toJson() => getAll().map((h) => h.toMap()).toList();

  late Database _db;

  int get length => _db.select("select count(*) from history;").first[0] as int;

  Future<void> tryUpdateDb() async{
    var file = File("${App.dataPath}/history_temp.db");
    if(file.existsSync()){
      _db.dispose();
      file.renameSync("${App.dataPath}/history.db");
      await init();
    }
  }

  Future<void> init() async {
    _db = sqlite3.open("${App.dataPath}/history.db");

    _db.execute("""
        create table if not exists history  (
          target text primary key,
          title text,
          subtitle text,
          cover text,
          time int,
          type int,
          ep int,
          page int,
          readEpisode text,
          max_page int
        );
      """);

    // 检查是否有max_page字段, 如果没有则添加
    var res = _db.select("""
      PRAGMA table_info(history);
    """);
    if (res.every((row) => row["name"] != "max_page")) {
      _db.execute("""
        alter table history
        add column max_page int;
      """);
    }

    // 迁移早期版本的数据
    var file = File("${App.dataPath}/history.json");
    if(file.existsSync()){
      readDataFromJson(jsonDecode(file.readAsStringSync()));
      file.deleteSync();
    }

    ImageFavoriteManager.init();
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
    vacuum();
  }

  void saveData() async {
    Webdav.uploadData();
  }

  /// add history. if exists, update time.
  ///
  /// This function would be called when user start reading.
  Future<void> addHistory(History newItem) async {
    var res = _db.select("""
      select * from history
      where target == ?;
    """, [newItem.target]);
    if(res.isEmpty){
      _db.execute("""
        insert into history (target, title, subtitle, cover, time, type, ep, page, readEpisode, max_page)
        values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      """, [newItem.target, newItem.title, newItem.subtitle, newItem.cover,
        newItem.time.millisecondsSinceEpoch, newItem.type.index, newItem.ep,
        newItem.page, newItem.readEpisode.join(','), newItem.maxPage]);
    } else {
      _db.execute("""
        update history
        set time = ${DateTime.now().millisecondsSinceEpoch}
        where target == ?;
      """, [newItem.target]);
    }
    saveData();
  }

  ///退出阅读器时调用此函数, 修改阅读位置
  Future<void> saveReadHistory(History history) async {
    _db.execute("""
        update history
        set time = ${DateTime.now().millisecondsSinceEpoch}, ep = ?, page = ?, readEpisode = ?, max_page = ?
        where target == ?;
    """, [history.ep, history.page, history.readEpisode.join(','), history.maxPage, history.target]);
    scheduleMicrotask(() {
      StateController.findOrNull(tag: "me_page")?.update();
    });
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
    var res = _db.select("""
      select * from history
      where target == ?;
    """, [target]);
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

  void vacuum(){
    _db.execute("""
      vacuum;
    """);
  }

  /// 获取最近一周的阅读数据, 用于生成图表, List中的元素是当天阅读的漫画数量
  List<int> getWeekData(){
    var res = _db.select("""
      select * from history
      where time > ${DateTime.now().add(const Duration(days: -6)).millisecondsSinceEpoch}
      order by time ASC;
    """);
    var data = List<int>.filled(7, 0);
    for(var element in res){
      var time = DateTime.fromMillisecondsSinceEpoch(element["time"] as int);
      data[DateTime.now().difference(time).inDays]++;
    }
    return data.reversed.toList();
  }
}
