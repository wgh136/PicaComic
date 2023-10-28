import 'package:dio/dio.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/log_dio.dart';

import '../tools/device_info.dart';

Future<bool?> checkUpdate() async {
  try {
    var version = appVersion;
    var dio = logDio();
    var res = await dio.get("$serverDomain/version");
    var s = res.data;
    return compareSemVer(s, version); //有更新返回true
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
  try {
    var dio = Dio();
    var res = await dio.get("$serverDomain/updates");
    var s = res.data;
    return s;
  } catch (e) {
    return null;
  }
}

Future<String> getDownloadUrl() async {
  return "$serverDomain/download";
}
