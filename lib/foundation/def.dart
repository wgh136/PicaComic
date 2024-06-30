typedef ActionFunc = void Function();

enum ComicType {
  picacg,
  ehentai,
  jm,
  hitomi,
  htManga,
  htFavorite,
  nhentai,
  other;

  @override
  toString() => name;
}

const String webUA =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36";

//App版本
const appVersion = "3.1.4";

//定义宽屏设备的临界值
const changePoint = 600;
const changePoint2 = 1300;

const List<int> colors = [
  0XFF42A5F5,
  0XFF29B6F6,
  0XFF5C6BC0,
  0XFFAB47BC,
  0XFFEC407A,
  0XFF26C6DA,
  0XFF26A69A,
  0XFFFFEE58,
  0XFF8D6E63
];

const serverDomain = "https://api.wgh136.xyz";
