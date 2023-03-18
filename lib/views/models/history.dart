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

  String toString()=>"$id $title $author $time $ep $page";
}