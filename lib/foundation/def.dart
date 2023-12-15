typedef ActionFunc = void Function();

enum ComicType {
  picacg,
  ehentai,
  jm,
  hitomi,
  htManga,
  htFavorite,
  nhentai;

  bool get hasEps => [0, 2].contains(index);
}

const String webUA =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36";

//App版本
const appVersion = "2.3.2";

//定义宽屏设备的临界值
const changePoint = 600;
const changePoint2 = 1300;

const List<int> colors = [
  0X42A5F5,
  0X29B6F6,
  0X5C6BC0,
  0XAB47BC,
  0XEC407A,
  0X26C6DA,
  0X26A69A,
  0XFFEE58,
  0X8D6E63
];

const serverDomain = "https://api.wgh136.xyz";
