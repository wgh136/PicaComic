import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'package:crypto/crypto.dart';

///由chatgpt转换自 https://github.com/tonquer/JMComic-qt/blob/main/src/tools/tool.py
int getSegmentationNum(String epsId, String scrambleID, String pictureName) {
  int scrambleId = int.parse(scrambleID);
  int epsID = int.parse(epsId);
  int num = 0;

  if (epsID < scrambleId) {
    num = 0;
  } else if (epsID < 268850) {
    num = 10;
  } else if (epsID > 421926) {
    String string = epsID.toString() + pictureName;
    List<int> bytes = utf8.encode(string);
    String hash = md5.convert(bytes).toString();
    int charCode = hash.codeUnitAt(hash.length - 1);
    int remainder = charCode % 8;
    num = remainder * 2 + 2;
  } else {
    String string = epsID.toString() + pictureName;
    List<int> bytes = utf8.encode(string);
    String hash = md5.convert(bytes).toString();
    int charCode = hash.codeUnitAt(hash.length - 1);
    int remainder = charCode % 10;
    num = remainder * 2 + 2;
  }

  return num;
}

///由chatgpt转换自 https://github.com/tonquer/JMComic-qt/blob/main/src/tools/tool.py
///
/// chatgpt转换后产生了一个错误, 导致我检查了很久
///
/// 不建议使用gpt完成这种需要注意细节的东西, 它总能给你一些惊喜
Future<Uint8List> segmentationPicture(_Data data) async{
  int num = getSegmentationNum(data.epsId, data.scrambleId, data.bookId);

  if (num <= 1) {
    return data.imgData;
  }

  image.Image srcImg = image.decodeImage(data.imgData)!;

  int blockSize = (srcImg.height / num).floor();
  int remainder = srcImg.height % num;

  List<Map<String, int>> blocks = [];

  for (int i = 0; i < num; i++) {
    int start = i * blockSize;
    int end = start + blockSize + ((i != num-1) ? 0 : remainder);
    blocks.add({'start': start, 'end': end});
  }

  image.Image desImg = image.Image(srcImg.width, srcImg.height);

  int y = 0;
  for (int i = blocks.length-1; i >=0; i--) {
    var block = blocks[i];
    int currBlockHeight = block['end']! - block['start']!;
    image.Image tempImg = image.copyCrop(srcImg, 0, block['start']!, srcImg.width, block['end']!);
    await Future.delayed(const Duration(milliseconds: 40));
    image.copyInto(desImg, tempImg, dstY: y);
    y += currBlockHeight;
  }

  return Uint8List.fromList(image.encodeJpg(desImg));
}

class _Data{
  Uint8List imgData;
  String epsId;
  String scrambleId;
  String bookId;

  _Data(this.imgData, this.epsId, this.scrambleId, this.bookId);
}

int recombiningItem = 0;

///启动一个新的线程转换图片
///
/// 直接使用异步会导致卡顿
Future<Uint8List> startRecombineImage(Uint8List imgData, String epsId, String scrambleId, String bookId) async{
  //仅允许有三张图片在进行重组
  //同时重组过多会导致占用资源过多
  //当有其它图片进行重组时, 等待
  if(recombiningItem > 3){
    await Future.delayed(const Duration(milliseconds: 200));
  }else{
    recombiningItem++;
  }
  var res =  await compute(segmentationPicture,_Data(imgData,epsId,scrambleId,bookId));
  recombiningItem--;
  return res;
}