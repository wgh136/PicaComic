typedef ActionFunc = void Function();

enum ComicType{
  picacg, ehentai, jm, hitomi, htmanga, nhentai;

  bool get hasEps => [0,2].contains(index);
}