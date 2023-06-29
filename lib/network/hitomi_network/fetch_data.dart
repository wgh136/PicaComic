import 'dart:typed_data';
import 'package:pica_comic/network/res.dart';
import 'package:dio/dio.dart';

import '../proxy.dart';

///改写自 hitomi.la 网站上的js脚本
///
/// 接收byte数据, 将每4个byte合成1个int32即为漫画id
///
/// 发送请求时需要在请求头设置开始接收位置和最后接收位置,
///
/// 获取主页时不需要传入end, 因为需要和js脚本保持一致, 设置获取宽度100, 避免出现问题
///
/// 响应头中 Content-Range 指明数据范围, 此函数用subData形式返回此值
Future<Res<List<int>>> fetchComicData(String url, int start, {int? maxLength, int? endData, String? ref}) async{
  await getProxy();
  try{
    var end = start + 100 - 1;
    if(endData != null){
      end = endData;
    }
    if(maxLength != null && maxLength < end){
      end = maxLength;
    }
    assert(start < end);
    var dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
    ));
    dio.options.responseType = ResponseType.bytes;
    dio.options.headers = {
      "User-Agent":
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
      "Range": "bytes=$start-$end",
      if(ref != null)
        "Referer": ref
    };
    var res = await dio.get(url);
    var bytes = Uint8List.fromList(res.data);
    var comicIds = <int>[];
    for (int i = 0; i < bytes.length; i += 4) {
      Int8List list = Int8List(4);
      list[0] = bytes[i];
      list[1] = bytes[i + 1];
      list[2] = bytes[i + 2];
      list[3] = bytes[i + 3];
      int number = list.buffer.asByteData().getInt32(0);
      comicIds.add(number);
    }
    var range = (res.headers["content-range"]?? res.headers["Content-Range"])![0];
    int i = 0;
    for(;i<range.length;i++){
      if(range[i] == '/') break;
    }
    return Res(comicIds, subData: range.substring(i+1));
  }
  catch(e){
    return Res(null, errorMessage: e.toString()=="null" ? "未知错误" : e.toString());
  }
}