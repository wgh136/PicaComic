import 'dart:io';

extension FileExtension on File{
  /// Get file size information in MB
  double getMBSizeSync(){
    var bytes = lengthSync();
    return bytes/1024/1024;
  }
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

  Directory renameX(String newName){
    var dirName = path.substring(0, path.lastIndexOf(Platform.pathSeparator)+1);
    return renameSync(dirName + newName);
  }

  String get name => path.substring(path.lastIndexOf(Platform.pathSeparator)+1);
}