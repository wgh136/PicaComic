import 'package:pica_comic/base.dart';

const imageUrls = [
  "https://cdn-msp.jmapiproxy.cc",
  "https://cdn-msp.jmapiproxy1.cc",
  "https://cdn-msp.jmapiproxy2.cc",
  "https://cdn-msp.jmapiproxy3.cc"
];

String getBaseUrl(){
  return imageUrls[int.parse(appdata.settings[17])];
}

String getJmCoverUrl(String id) {
  return "https://cdn-msp.jmapiproxy.cc/media/albums/${id}_3x4.jpg";
}

String getJmImageUrl(String imageName, String id) {
  return "https://cdn-msp.jmapiproxy.cc/media/photos/$id/$imageName";
}

String getJmAvatarUrl(String imageName) {
  return "https://cdn-msp.jmapiproxy.cc/media/users/$imageName";
}
