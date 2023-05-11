///从画廊链接中获取画廊id
String getGalleryId(String url){
  var i = url.indexOf("/g/");
  i += 3;
  String res = "";
  while(i < url.length){
    res += url[i];
    i++;
    if(url[i] == '/'){
      break;
    }
  }
  return res;
}