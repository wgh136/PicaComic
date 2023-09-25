import 'package:pica_comic/base.dart';

const imageUrls = [
  "https://cdn-msp.jmapiproxy1.monster",
  "https://cdn-msp2.jmapiproxy3.cc",
  "https://cdn-msp.jmapiproxy2.cc",
  "https://cdn-msp2.jmapiproxy1.cc",
  "https://cdn-msp2.jmapiproxy4.cc",
  "https://cdn-msp.jmapiproxy3.cc",
];

String getBaseUrl(){
  return imageUrls[int.parse(appdata.settings[37])];
}

String getJmCoverUrl(String id) {
  return "${getBaseUrl()}/media/albums/${id}_3x4.jpg";
}

String getJmImageUrl(String imageName, String id) {
  return "${getBaseUrl()}/media/photos/$id/$imageName";
}

String getJmAvatarUrl(String imageName) {
  return "${getBaseUrl()}/media/users/$imageName";
}
