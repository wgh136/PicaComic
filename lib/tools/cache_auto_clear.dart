import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 清除长期未使用的缓存
Future<void> _autoClearCache(String cachePath) async{
  var imageCachePath = Directory("$cachePath${Platform.pathSeparator}imageCache");
  var networkCachePath = Directory("$cachePath${Platform.pathSeparator}cachedNetwork");
  var time = DateTime.now();
  if(imageCachePath.existsSync()){
    for(var file in imageCachePath.listSync()){
      if(file is File){
        if(time.millisecondsSinceEpoch - file.lastAccessedSync().millisecondsSinceEpoch > 604800000){
          file.deleteSync();
        }
      }
    }
  }
  if(networkCachePath.existsSync()){
    for(var file in networkCachePath.listSync()){
      if(file is File){
        if(time.millisecondsSinceEpoch - file.lastAccessedSync().millisecondsSinceEpoch > 604800000){
          file.deleteSync();
        }
      }
    }
  }
}

/// 清除长期未使用的缓存
Future<void> startClearCache() async{
  var cachePath = await getTemporaryDirectory();
  return await compute(_autoClearCache, cachePath.path);
}