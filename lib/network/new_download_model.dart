abstract class DownloadedItem{
  ///漫画源
  DownloadType get type;
  ///漫画名
  String get name;
  ///章节
  List<String> get eps;
  ///已下载的章节
  List<int> get downloadedEps;
  ///标识符, 禁漫必须在前加jm
  String get id;
  ///副标题, 通常为作者
  String get subTitle;
  ///大小
  double? get comicSize;
  ///下载的时间, 仅在下载页面时需要, 用于排序, 读取漫画信息时顺便读取即可
  DateTime? time;
}

enum DownloadType{picacg, ehentai, jm, hitomi}

abstract class DownloadingItem{
  ///完成时调用
  final void Function()? whenFinish;

  ///更新ui, 用于下载管理器页面
  void Function()? updateUi;

  ///出现错误时调用
  final void Function()? whenError;

  ///更新下载信息
  final Future<void> Function()? updateInfo;

  ///标识符, 对于哔咔和eh, 直接使用其提供的漫画id, 禁漫开头加jm, hitomi开头加hitomi
  final String id;

  ///类型
  DownloadType type;

  DownloadingItem(this.whenFinish,this.whenError,this.updateInfo,this.id, {required this.type});


  ///开始或者继续暂停的下载
  void start();

  ///暂停下载
  void pause();

  ///停止下载
  void stop();

  Map<String, dynamic> toMap();

  ///获取封面链接
  String get cover;

  ///总共的图片数量
  int get totalPages;

  ///已下载的图片数量
  int get downloadedPages;

  ///标题
  String get title;

  @override
  bool operator==(Object other){
    if(other is DownloadingItem){
      return id == other.id;
    }else{
      return false;
    }
  }

  @override
  int get hashCode => id.hashCode;
}