import 'package:dio/dio.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/app_dio.dart';

String? _updateInfo;

Future<String> getLatestVersion() async {
  var dio = logDio();
  var res = await dio
      .get("https://api.github.com/repos/wgh136/PicaComic/releases/latest");
  _updateInfo = res.data["body"];
  return (res.data["tag_name"] as String).replaceFirst("v", "");
}

Future<bool?> checkUpdate() async {
  try {
    var version = appVersion;
    var res = await getLatestVersion();
    return compareSemVer(res, version);
  } catch (e) {
    return null;
  }
}

bool compareSemVer(String ver1, String ver2) {
  ver1 = ver1.replaceFirst("-", ".");
  ver2 = ver2.replaceFirst("-", ".");
  List<String> v1 = ver1.split('.');
  List<String> v2 = ver2.split('.');

  for (int i = 0; i < 3; i++) {
    int num1 = int.parse(v1[i]);
    int num2 = int.parse(v2[i]);

    if (num1 > num2) {
      return true;
    } else if (num1 < num2) {
      return false;
    }
  }

  var v14 = v1.elementAtOrNull(3);
  var v24 = v2.elementAtOrNull(3);

  if (v14 != v24) {
    if (v14 == null && v24 != "hotfix") {
      return true;
    } else if (v14 == null) {
      return false;
    }
    if (v24 == null) {
      if (v14 == "hotfix") {
        return true;
      }
      return false;
    }
    return v14.compareTo(v24) > 0;
  }

  return false;
}

Future<String?> getUpdatesInfo() async {
  if(_updateInfo == null)  return null;
  _updateInfo!.replaceAll('\r\n', '\n');
  var lines = _updateInfo!.split("\n");
  if(lines.length > 5) {
    lines.add("...");
    return lines.sublist(5).join("\n");
  }
  return _updateInfo;
}

Future<String> getDownloadUrl() async {
  return "https://github.com/wgh136/PicaComic/releases/latest";
}
