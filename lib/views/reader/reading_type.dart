enum ReadingType {
  picacg,
  ehentai,
  jm ,
  hitomi,
  htmanga,
  nhentai;

  bool get hasEps => [0,2].contains(index);
}

enum ReadingMethod {
  leftToRight,
  rightToLeft,
  topToBottom,
  topToBottomContinuously,
  twoPage,
  twoPageReversed;
}