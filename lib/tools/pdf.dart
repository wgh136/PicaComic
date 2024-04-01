import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart';
import 'package:pica_comic/foundation/app.dart';

Future<void> createPdfFromComic({
  required String title,
  required String comicPath,
  required String savePath,
  required ByteData font,
  List<String>? chapters,
  List<int>? chapterIndexes,
}) async{
  final pdf = Document(
    theme: ThemeData(
      defaultTextStyle: TextStyle(
        font: Font.ttf(font)
      )
    )
  );

  // add cover
  var imageData = File("$comicPath/cover.jpg").readAsBytesSync();
  pdf.addPage(Page(
    build: (Context context) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 100,
            child: Center(
              child: Text(title, style: const TextStyle(fontSize: 20)),
            )
          ),
          Expanded(
            child: Image(MemoryImage(imageData), fit: BoxFit.contain)
          )
        ]
      );
    },
  ));

  bool multiChapters = !(File("$comicPath/0.jpg").existsSync()
      || File("$comicPath/0.png").existsSync()
      || File("$comicPath/0.webp").existsSync()
      || File("$comicPath/0.jpeg").existsSync()
      || File("$comicPath/0.gif").existsSync());

  void reorderFiles(List<FileSystemEntity> files) {
    files.removeWhere((element) =>
    element is! File ||
        element.path.contains('info.json') ||
        element.path.contains('cover.jpg') ||
        element.path.contains('cover.png') ||
        element.path.contains('cover.webp') ||
        element.path.contains('cover.jpeg'));
    files.sort((a, b) {
      var aName = (a as File).path.replaceAll('\\', '/').split("/").last;
      var bName = (b as File).path.replaceAll('\\', '/').split("/").last;
      var aIndex = int.parse(aName.split(".").first);
      var bIndex = int.parse(bName.split(".").first);
      return aIndex.compareTo(bIndex);
    });
  }

  if(!multiChapters){
    var files = Directory(comicPath).listSync();
    reorderFiles(files);

    for (var file in files){
      var imageData = (file as File).readAsBytesSync();
      pdf.addPage(Page(
        build: (Context context) {
          return Image(MemoryImage(imageData), fit: BoxFit.contain);
        },
      ));
    }
  } else {
    for (int current = 0; current < chapterIndexes!.length; current++){
      var directory = Directory("$comicPath/${chapterIndexes[current]+1}");
      // add chapter title
      pdf.addPage(Page(
        build: (Context context) {
          return Center(
            child: Text(chapters![chapterIndexes[current]],
                style: const TextStyle(fontSize: 20)),
          );
        },
      ));

      var files = directory.listSync();
      reorderFiles(files);

      for (var file in files){
        var imageData = (file as File).readAsBytesSync();
        pdf.addPage(Page(
          build: (Context context) {
            return Image(MemoryImage(imageData), fit: BoxFit.contain);
          },
        ));
      }
    }
  }

  final file = File(savePath);
  file.writeAsBytesSync(await pdf.save());
}

Future<void> createPdfFromComicWithIsolate({
  required String title,
  required String comicPath,
  required String savePath,
  List<String>? chapters,
  List<int>? chapterIndexes,
}) async{
  var fontData = await _loadFont();

  return Isolate.run(() => createPdfFromComic(
    title: title,
    comicPath: comicPath,
    savePath: savePath,
    font: fontData,
    chapters: chapters,
    chapterIndexes: chapterIndexes
  ));
}

Future<ByteData> _loadFont() async{
  if(Platform.isWindows) {
    return await rootBundle.load("fonts/NotoSansSC-Regular.ttf");
  }
  var fontFile = File("${App.dataPath}/font.ttf");
  if(!fontFile.existsSync()){
    throw Exception("Font file not found");
  }
  return fontFile.readAsBytes().then((value) => ByteData.sublistView(value));
}