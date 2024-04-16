import 'dart:convert';
import 'dart:io';

import 'package:pica_comic/tools/extensions.dart';

extension FileSystemEntityExt on FileSystemEntity{
  String get name {
    var path = this.path;
    if(path.endsWith('/') || path.endsWith('\\')){
      path = path.substring(0, path.length-1);
    }

    int i = path.length - 1;

    while(path[i] != '\\' && path[i] != '/' && i >= 0){
      i--;
    }

    return path.substring(i+1);
  }

  Future<void> deleteIgnoreError({bool recursive = false}) async{
    try{
      await delete(recursive: recursive);
    }catch(e){
      // ignore
    }
  }
}

extension FileExtension on File{
  /// Get file size information in MB
  double getMBSizeSync(){
    var bytes = lengthSync();
    return bytes/1024/1024;
  }

  String get extension => path.split('.').last;
}

extension DirectoryExtension on Directory{
  /// Get directory size information in MB
  ///
  /// if directory is not exist, return 0;
  double getMBSizeSync(){
    if(!existsSync()) return 0;
    double total = 0;
    for(var f in listSync(recursive: true)){
      if(FileSystemEntity.typeSync(f.path)==FileSystemEntityType.file){
        total += File(f.path).lengthSync()/1024/1024;
      }
    }
    return total;
  }

  Future<int> get size async{
    if(!existsSync()) return 0;
    int total = 0;
    for(var f in listSync(recursive: true)){
      if(FileSystemEntity.typeSync(f.path)==FileSystemEntityType.file){
        total += await File(f.path).length();
      }
    }
    return total;
  }

  Directory renameX(String newName){
    newName = sanitizeFileName(newName);
    return renameSync(path.replaceLast(name, newName));
  }
}

String sanitizeFileName(String fileName) {
  const maxLength = 255;
  final invalidChars = RegExp(r'[<>:"/\\|?*]');
  final sanitizedFileName = fileName.replaceAll(invalidChars, ' ');
  var trimmedFileName = sanitizedFileName.trim();
  if (trimmedFileName.isEmpty) {
    throw Exception('Invalid File Name: Empty length.');
  }
  while(true){
    final bytes = utf8.encode(trimmedFileName);
    if (bytes.length > maxLength) {
      trimmedFileName = trimmedFileName.substring(0, trimmedFileName.length-1);
    }else{
      break;
    }
  }
  return trimmedFileName;
}