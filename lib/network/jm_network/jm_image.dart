import 'package:pica_comic/base.dart';

const imageUrls = [
  "https://cdn-msp2.jmapiproxy.cc",
  "https://cdn-msp2.jmapiproxy1.cc",
  "https://cdn-msp2.jmapiproxy2.cc",
  "https://cdn-msp2.jmapiproxy3.cc",
  "https://cdn-msp.jmapiproxy4.cc",
  "https://cdn-msp.jmapiproxy.cc",
];

String getBaseUrl(){
  return imageUrls[int.parse(appdata.settings[37])];
}

String getJmCoverUrl(String id) {
  return "${getBaseUrl()}/media/albums/${id}_3x4.jpg";
}

String getJmImageUrl(String imageName, String id) {
  return "${getBaseUrl()}/media/photos/$id/$imageName?v=${DateTime.now().millisecondsSinceEpoch ~/ 1000}";
}

String getJmAvatarUrl(String imageName) {
  return "${getBaseUrl()}/media/users/$imageName";
}
