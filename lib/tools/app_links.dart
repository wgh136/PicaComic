import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/tools/extensions.dart';
import '../views/eh_views/eh_gallery_page.dart';
import '../views/hitomi_views/hitomi_comic_page.dart';
import '../views/main_page.dart';
import '../views/nhentai/comic_page.dart';
import '../views/widgets/show_message.dart';
import 'package:get/get.dart';

bool handleAppLinks(Uri uri, {bool showMessageWhenError = true}){
  LogManager.addLog(LogLevel.info, "App Link", "Open Link $uri");
  switch(uri.host){
    case "e-hentai.org":
    case "exhentai.org":
      if(uri.pathSegments.isEmpty){
        MainPage.toExplorePageAt(2);
      }else if(uri.path.contains("popular")){
        MainPage.toExplorePageAt(3);
      }else if(uri.path.contains("/g/")){
        MainPage.to(() => EhGalleryPage.fromLink("https://${uri.host}${uri.path}"));
      }else{
        showMessage(Get.context, "Unknown Link");
        return false;
      }
    case "nhentai.net":
    case "nhentai.xxx":
      if(uri.pathSegments.isEmpty){
        MainPage.toExplorePageAt(7);
      }else if(uri.path.contains("/g/")){
        MainPage.to(() => NhentaiComicPage(uri.path.nums));
      }else{
        showMessage(Get.context, "Unknown Link");
        return false;
      }
    case "hitomi.la":
      if(uri.pathSegments.isEmpty){
        MainPage.toExplorePageAt(6);
      }else if(["doujinshi", "cg", "manga"].contains(uri.pathSegments[0])){
        MainPage.to(() => HitomiComicPage.fromLink("https://${uri.host}${uri.path}"));
      }else{
        showMessage(Get.context, "Unknown Link");
        return false;
      }
    default:
      return false;
  }
  return true;
}