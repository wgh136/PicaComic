import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:share_plus/share_plus.dart';

import '../foundation/app.dart';

///保存图片
void saveImage(File file) async {
  if (App.isAndroid || App.isIOS) {
    await ImageGallerySaver.saveImage(
      await file.readAsBytes(),
      quality: 100,
      name: file.name,
    );
    showToast(message: "已保存".tl);
  } else if (App.isDesktop) {
    try {
      final String? path =
          (await getSaveLocation(suggestedName: file.name))?.path;
      if (path != null) {
        const String mimeType = 'image/jpeg';
        final XFile xFile = XFile.fromData(await file.readAsBytes(),
            mimeType: mimeType, name: file.name);
        await xFile.saveTo(path);
      }
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Save Image", "$e\n$s");
    }
  }
}

Future<String> persistentCurrentImage(File file) async {
  var newFile = File("${App.dataPath}/images/${file.path.split('/').last})}");
  if (!(await newFile.exists())) {
    newFile.createSync(recursive: true);
    newFile.writeAsBytesSync(await file.readAsBytes());
  }
  return newFile.path;
}

void shareImage(File file) {
  Share.shareXFiles([XFile(file.path)]);
}
