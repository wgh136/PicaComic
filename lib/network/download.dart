import 'dart:collection';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/base.dart';
import 'package:dio/dio.dart';
import 'models.dart';
import 'package:sqflite/sqflite.dart';

class DownloadManage{
  var downloadList = Queue<DownloadInfo>();
  bool isRunning = false;

  Future<void> _download(DownloadInfo downloadInfo) async{
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    var dio = Dio();
    var urls = await network.getComicContent(downloadInfo.id, downloadInfo.ep);
    for(var url in urls){
      if(downloadInfo.downloaded == -1) return;
      await dio.download(url,"${appDocPath}download/+${downloadInfo.id}+${downloadInfo.ep}");
      downloadInfo.downloaded++;
    }
  }

  Future<bool> addDownload(String id, int ep) async{
    var eps = await network.getEps(id);
    if(eps.isNotEmpty) {
      downloadList.add(DownloadInfo(id, eps.length, ep));
      return true;
    }else{
      return false;
    }
  }

  Future<void> download() async{
    isRunning = true;
    while(downloadList.isNotEmpty){
      var current = downloadList.first;
      await _download(current);
      downloadList.removeFirst();
    }
    isRunning = false;
  }

  Future<void> saveInfo() async{
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    final database = openDatabase("${appDocPath}download/",  onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE download(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
      );
    },);

  }
}