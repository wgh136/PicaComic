import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pica_comic/foundation/def.dart';
import '../res.dart';

class HitomiSearch{
  final domain = 'https://ltn.hitomi.la';
  var results = <int>[];
  String? tagIndexVersion;
  final dio = Dio();
  final nozomiExtension = '.nozomi';
  var indexDir = 'galleriesindex';
  var galleriesIndexDir = 'galleriesindex';
  var languagesIndexDir = 'languagesindex';
  var nozomiUrlIndexDir = 'nozomiurlindex';
  final String keyword;

  HitomiSearch(this.keyword);

  Future<Res<List<int>>> search() async{
    await getTagIndexVersion();
    var terms = keyword.toLowerCase().trim().split(RegExp(r"\s+"));
    var negativeTerms = <String>[];
    var positiveTerms = <String>[];
    for(var term in terms){
      term = term.replaceAll('_', ' ');
      if (term.startsWith('-')) {
        negativeTerms.add(term.replaceFirst('-', ''));
      } else {
        positiveTerms.add(term);
      }
    }
    //first results
    if(positiveTerms.isEmpty){
      results = await getGalleryIdsFromNozomi(null, 'index', 'all');
    }else{
      final term = positiveTerms.removeAt(0);
      results = await getGalleryIdsForQuery(term);
    }
    //positive results
    for(var term in positiveTerms){
      var res = await getGalleryIdsForQuery(term);
      var newRes = <int>[];
      for(var c in res){
        if(results.contains(c)){
          newRes.add(c);
        }
      }
      results = newRes;
    }
    //negative results
    for(var term in negativeTerms){
      var res = await getGalleryIdsForQuery(term);
      var newRes = <int>[];
      for(var c in res){
        if(!results.contains(c)){
          newRes.add(c);
        }
      }
      results = newRes;
    }
    return Res(results);
  }

  Future<void> getTagIndexVersion() async{
    var res = await dio.get(
        "$domain/galleriesindex/version?_=${DateTime.now().millisecondsSinceEpoch ~/ 1000}",
        options: Options(
            responseType: ResponseType.plain
        )
    );
    tagIndexVersion = res.data;
  }

  Future<List<int>> getGalleryIdsFromNozomi(String? area, String tag, String language) async{
    var url = "$domain/n/$tag-$language$nozomiExtension";
    if(area != null){
      url = "$domain/n/$area/$tag-$language$nozomiExtension";
    }
    var bytes = (await dio.get<Uint8List>(url, options: Options(
      responseType: ResponseType.bytes
    ))).data;
    var comicIds = <int>[];
    for (int i = 0; i < bytes!.length; i += 4) {
      Int8List list = Int8List(4);
      list[0] = bytes[i];
      list[1] = bytes[i + 1];
      list[2] = bytes[i + 2];
      list[3] = bytes[i + 3];
      int number = list.buffer.asByteData().getInt32(0);
      comicIds.add(number);
    }
    return comicIds;
  }

  Future<List<int>> getGalleryIdsForQuery(String query) async{
    query = query.replaceAll("_", " ");
    if(query.contains(":")){
      final sides = query.split(":");
      final ns = sides[0];
      var tag = sides[1];
      String? area = ns;
      var language = 'all';

      if(ns == 'female' || ns == 'male'){
        area = 'tag';
        tag = query;
      }else if(ns == 'language'){
        area = null;
        language = tag;
        tag = 'index';
      }

      return getGalleryIdsFromNozomi(area, tag, language);
    }
    final key = hashTerm(query);
    const field = 'galleries';
    var node = await getNodeAtAddress(field, 0);
    if(node == null){
      return [];
    }else{
      var data = await bSearch(field, key, node);
      if(data == null){
        return [];
      }else{
        return getGalleryIdsFromData(data);
      }
    }
  }

  Uint8List hashTerm(String term){
    List<int> hash = sha256.convert(utf8.encode(term)).bytes;
    return Uint8List.fromList(hash.sublist(0, 4));
  }

  Future<Node?> getNodeAtAddress(String field, int address) async{
    const maxNodeSize = 464;
    var url = '$domain/$indexDir/$field.${tagIndexVersion!}.index';
    var res = await getUrlAtRange(url, [address, address + maxNodeSize - 1]);
    if(res == null){
      return null;
    }else{
      return decodeNodeData(res);
    }
  }

  Future<Uint8List?> getUrlAtRange(String url, List<int> range) async{
    assert(range.length==2);
    var res = await dio.get<List<int>>(url, options: Options(
      responseType: ResponseType.bytes,
      headers: {
        'Range': "bytes=${range[0]}-${range[1]}",
        'User-Agent': webUA,
        'Referer': 'https://hitomi.la/search.html',
        'Origin': "https://hitomi.la"
      }
    ));
    return Uint8List.fromList(res.data!);
  }

  Future<Node?> decodeNodeData(Uint8List data) async{
    ByteData view = ByteData.view(data.buffer);
    int pos = 0;
    int numberOfKeys = view.getInt32(pos, Endian.big);
    pos += 4;

    List<Uint8List> keys = [];
    for (int i = 0; i < numberOfKeys; i++) {
      int keySize = view.getInt32(pos, Endian.big);
      if (keySize == 0 || keySize > 32) {
        return null;
      }
      pos += 4;
      keys.add(data.sublist(pos, pos + keySize));
      pos += keySize;
    }

    int numberOfDatas = view.getInt32(pos, Endian.big);
    pos += 4;
    List<List<int>> datas = [];
    for (int i = 0; i < numberOfDatas; i++) {
      int offset = view.getUint64(pos, Endian.big);
      pos += 8;

      int length = view.getInt32(pos, Endian.big);
      pos += 4;

      datas.add([offset, length]);
    }

    const B = 16;
    int numberOfSubnodeAddresses = B + 1;
    List<int> subnodeAddresses = [];
    for (int i = 0; i < numberOfSubnodeAddresses; i++) {
      int subnodeAddress = view.getUint64(pos, Endian.big);
      pos += 8;
      subnodeAddresses.add(subnodeAddress);
    }

    return Node(keys, datas, subnodeAddresses);
  }

  Future<List<int>?> bSearch(String field, Uint8List key, Node? node) async{
    if(node == null){
      return null;
    }

    if(node.keys.isEmpty){
      return null;
    }

    int compareArrayBuffers(Uint8List a, Uint8List b){
      final top = min(a.length, b.length);
      for(var i=0;i<top;i++){
        if(a[i] < b[i]){
          return -1;
        }else if(a[i] > b[i]){
          return 1;
        }
      }
      return 0;
    }

    List<dynamic> locateKey(Uint8List key, Node node){
      var cmpResult = -1;
      int i;
      for(i=0;i<node.keys.length;i++){
        cmpResult = compareArrayBuffers(key, node.keys[i]);
        if(cmpResult <= 0){
          break;
        }
      }
      return [cmpResult==0, i];
    }

    bool isLeaf(Node node){
      for(var i = 0; i< node.subNodeAddresses.length; i++){
        if(node.subNodeAddresses[i]!=0){
          return false;
        }
      }
      return true;
    }

    var [there, where] = locateKey(key, node);
    assert(there is bool && where is int);
    if(there){
      return node.data[where];
    }else if(isLeaf(node)){
      return null;
    }

    if(node.subNodeAddresses[where] == 0){
      return null;
    }

    var next = await getNodeAtAddress(field, node.subNodeAddresses[where]);
    return bSearch(field, key, next);
  }

  Future<List<int>> getGalleryIdsFromData(List<int>? data) async{
    if(data==null){
      return [];
    }
    assert(data.length==2);
    var [offset, length] = data;
    if(length > 100000000 || length <= 0){
      if(kDebugMode){
        print("length $length is too long");
      }
    }
    var url = '$domain/$galleriesIndexDir/galleries.${tagIndexVersion!}.data';
    var inbuf = await getUrlAtRange(url, [offset, offset+length-1]);
    if(inbuf == null){
      return [];
    }
    var galleryIds = <int>[];
    var pos = 0;
    ByteData view = ByteData.view(inbuf.buffer);
    var numberOfGalleryIds = view.getInt32(pos);
    pos += 4;
    var expectedLength = numberOfGalleryIds * 4 + 4;
    if (numberOfGalleryIds > 10000000 || numberOfGalleryIds <= 0){
      return [];
    } else if (inbuf.length != expectedLength){
      return [];
    }

    for(var i = 0; i < numberOfGalleryIds; i++){
      galleryIds.add(view.getInt32(pos));
      pos += 4;
    }
    return galleryIds;
  }
}

class Node{
  List<Uint8List> keys;
  ///数据, 个体为[offset, length]
  List<List<int>> data;
  List<int> subNodeAddresses;

  Node(this.keys, this.data, this.subNodeAddresses);
}