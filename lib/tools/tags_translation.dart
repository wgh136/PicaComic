// The purpose of this file is to translate tags

// Thanks:
// https://github.com/scooderic/exhentai-tags-chinese-translation
// https://www.wikipedia.org/
// https://ehwiki.org/
// https://hitomi.la/alltags-a.html
// https://translate.google.com/
// https://poe.com/
// https://nhentai.net/tags/
// https://github.com/EhTagTranslation/Database/tree/master/database

// 此翻译的目标是实现 **常见** tags的翻译, 冷门词语, 画师名, 团队名和角色名不在考虑之中
// 为了确保UI布局良好, 翻译会尽可能简短, 可能导致表意不准确

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';

extension TagsTranslation on String{
  static Map<String, Map<String, String>> _data = {};

  static Future<void> readData() async{
    var data = await rootBundle.load("assets/tags.json");
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    const JsonDecoder().convert(const Utf8Decoder().convert(bytes)).forEach((key, value){
      _data[key] = {};
      value.forEach((key1, value1){
        _data[key]?[key1] = value1;
      });
    });
  }


  /// 静态方法, 需要传入参数, 因为需要递归
  ///
  /// 对tag进行处理后进行翻译: 代表'或'的分割符'|', 修饰词'low','focus'.
  static String _translateTags(String tag){
    if(tag.contains('|')){
      var splits = tag.split(' | ');
      return enTagsTranslations[splits[0]]??enTagsTranslations[splits[1]]??tag;
    }else if(tag.contains("low ")){
      return "弱存在${_translateTags(tag.replaceFirst("low ", ""))}";
    }else if(tag.contains("focus ")){
      return "专注${_translateTags(tag.replaceFirst("focus ", ""))}";
    }else{
      return enTagsTranslations[tag]??tag;
    }
  }
  /// translate tag's text to chinese
  String get translateTagsToCN => _translateTags(this);

  String _categoryTextDynamic(String c){
    if(PlatformDispatcher.instance.locale.languageCode == "zh"){
      return translateTagsCategoryToCN;
    }else{
      return this;
    }
  }

  String get categoryTextDynamic => _categoryTextDynamic(this);

  String get translateTagsCategoryToCN => tagsCategoryTranslations[this]??this;

  static const tagsCategoryTranslations = {
    "language": "语言",
    "artist": "画师",
    "male": "男性",
    "female": "女性",
    "mixed": "混合",
    "other": "其它",
    "parody": "原作",
    "character": "角色",
    "group": "团队",
    "cosplayer": "Coser",
    "reclass": "重新分类",
    "Languages": "语言",
    "Artists": "画师",
    "Characters": "角色",
    "Groups": "团队",
    "Tags": "标签",
    "Parodies": "原作",
    "Categories": "分类",
    "Time": "时间"
  };

  static Map<String, String> get maleTags => _data["male"] ?? const {};

  static Map<String, String> get femaleTags => _data["female"] ?? const {};

  static Map<String, String> get languageTranslations => _data["language"] ?? const {};

  static Map<String, String> get parodyTags => _data["parody"] ?? const {};

  static Map<String, String> get characterTranslations => _data["character"] ?? const {};

  static Map<String, String> get otherTags => _data["other"] ?? const {};

  static Map<String, String> get mixedTags => _data["mixed"] ?? const {};

  static Map<String, String> get characterTags => _data["character"] ?? const {};

  /// English to chinese translations
  static MultipleMap<String, String> get enTagsTranslations => MultipleMap([
    maleTags, femaleTags, languageTranslations, parodyTags, characterTranslations,
    otherTags
  ]);
}

extension MapExtensions<S,T> on Map<S,T>{
  Map<S,T> operator+(Map<S,T> another){
    Map<S,T> newMap = {};
    newMap.addAll(this);
    newMap.addAll(another);
    return newMap;
  }
}

enum TranslationType{
  female, male, mixed, language, other, group, artist, cosplayer, parody,
  character, reclass
}

class MultipleMap<S, T>{
  final List<Map<S, T>> maps;

  MultipleMap(this.maps);

  T? operator[](S key) {
    for (var map in maps){
      var value = map[key];
      if(value != null){
        return value;
      }
    }
    return null;
  }
}