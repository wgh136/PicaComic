String getJmCoverUrl(String id){
  return "https://cdn-msp.jmapiproxy.cc/media/albums/${id}_3x4.jpg";
}

String getJmImageUrl(String imageName, String id){
  return "https://cdn-msp.jmapiproxy.cc/media/photos/$id/$imageName";
}

String getJmAvaterUrl(String imageName){
  return "https://cdn-msp.jmapiproxy.cc/media/users/$imageName";
}