part of pica_reader;

typedef ReadingType = ComicType;

enum ReadingMethod {
  leftToRight,
  rightToLeft,
  topToBottom,
  topToBottomContinuously,
  twoPage,
  twoPageReversed;

  bool get useComicImage => this == ReadingMethod.topToBottomContinuously ||
      this == ReadingMethod.twoPage || this == ReadingMethod.twoPageReversed;
}